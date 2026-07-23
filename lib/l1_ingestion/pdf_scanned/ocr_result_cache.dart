import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'ocr_engine.dart';

/// All OCR output for one rasterized page: the regions an [OcrEngine]
/// recognized, plus the raster dimensions they're relative to (needed to
/// populate `SourceRect.pageWidth`/`pageHeight` when building `Token`s).
class PageOcrResult {
  const PageOcrResult({
    required this.pageWidth,
    required this.pageHeight,
    required this.regions,
  });

  final double pageWidth;
  final double pageHeight;
  final List<OcrRegionResult> regions;

  Map<String, dynamic> toJson() => {
    'pageWidth': pageWidth,
    'pageHeight': pageHeight,
    'regions': regions
        .map(
          (r) => {
            'text': r.text,
            'x': r.x,
            'y': r.y,
            'width': r.width,
            'height': r.height,
            'confidence': r.confidence,
          },
        )
        .toList(),
  };

  factory PageOcrResult.fromJson(Map<String, dynamic> json) => PageOcrResult(
    pageWidth: (json['pageWidth'] as num).toDouble(),
    pageHeight: (json['pageHeight'] as num).toDouble(),
    regions: (json['regions'] as List)
        .map(
          (r) => OcrRegionResult(
            text: r['text'] as String,
            x: (r['x'] as num).toDouble(),
            y: (r['y'] as num).toDouble(),
            width: (r['width'] as num).toDouble(),
            height: (r['height'] as num).toDouble(),
            confidence: (r['confidence'] as num).toDouble(),
          ),
        )
        .toList(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageOcrResult &&
          other.pageWidth == pageWidth &&
          other.pageHeight == pageHeight &&
          _regionListsEqual(other.regions, regions));

  @override
  int get hashCode =>
      Object.hash(pageWidth, pageHeight, Object.hashAll(regions));
}

/// Element-wise [List] equality for [OcrRegionResult], avoiding a
/// dependency on `package:collection` purely for this one comparison.
bool _regionListsEqual(List<OcrRegionResult> a, List<OcrRegionResult> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Disk cache of per-document OCR output, keyed so that re-importing an
/// unchanged source file skips OCR entirely (spec §4: "OCR runs as a
/// background job on import, cached to disk").
///
/// The cache key intentionally differs from `Document.id` (see
/// `ScannedPdfImporter`): it folds in the source file's size and
/// modification time so a file that changed on disk (re-scanned, replaced)
/// invalidates the old entry, whereas `Document.id` is deliberately
/// path-only so that Chapter/Block/Sentence IDs stay stable across
/// re-imports of what's conceptually "the same document" even if content
/// shifts slightly -- these are different stability requirements and
/// deliberately use different derivations (see `core/ids/stable_id.dart`'s
/// own doc comment on position-derived vs. content-hashed IDs).
///
/// Size+mtime rather than a full content hash is a deliberate trade-off:
/// hashing would mean reading the entire source file on every import just
/// to check the cache, which is exactly the kind of up-front cost that's
/// unattractive for what could be a very large scanned-PDF file.
class OcrResultCache {
  OcrResultCache({this.directoryOverride});

  final Directory? directoryOverride;

  Future<Directory> _resolveDirectory() async {
    final override = directoryOverride;
    if (override != null) return override;
    final supportDir = await getApplicationSupportDirectory();
    return Directory(p.join(supportDir.path, 'ocr_cache'));
  }

  String _keyFor(File file) {
    final stat = file.statSync();
    final raw =
        '${file.absolute.path}|${stat.size}|'
        '${stat.modified.microsecondsSinceEpoch}';
    return sha1.convert(utf8.encode(raw)).toString();
  }

  Future<File> _cacheFileFor(File sourceFile) async {
    final dir = await _resolveDirectory();
    return File(p.join(dir.path, '${_keyFor(sourceFile)}.json'));
  }

  /// Returns the cached per-page OCR results for [sourceFile], or `null` if
  /// there is no valid cache entry (never been OCR'd, or the file changed
  /// since it was).
  Future<List<PageOcrResult>?> read(File sourceFile) async {
    final cacheFile = await _cacheFileFor(sourceFile);
    if (!await cacheFile.exists()) return null;
    final decoded = jsonDecode(await cacheFile.readAsString());
    final pages = decoded['pages'] as List;
    return pages
        .map((p) => PageOcrResult.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// Persists [pages] as the cached OCR output for [sourceFile], so a
  /// future [read] for the same (unchanged) file hits this entry.
  Future<void> write(File sourceFile, List<PageOcrResult> pages) async {
    final cacheFile = await _cacheFileFor(sourceFile);
    await cacheFile.parent.create(recursive: true);
    await cacheFile.writeAsString(
      jsonEncode({
        'sourcePath': sourceFile.absolute.path,
        'pages': pages.map((page) => page.toJson()).toList(),
      }),
    );
  }
}
