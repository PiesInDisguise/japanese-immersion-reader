import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Disk store for Library cover-art images (auto-extracted or user-picked),
/// keyed by `Document.id` -- a cover, once set, stays tied to "this book"
/// independent of whether the user re-imports the same source file. Mirrors
/// `lib/l1_ingestion/pdf_scanned/ocr_result_cache.dart`'s
/// `getApplicationSupportDirectory()`-based pattern for app-managed binary
/// files (no BLOB column exists anywhere in this app's schema).
class CoverArtStore {
  CoverArtStore({this.directoryOverride});

  final Directory? directoryOverride;

  Future<Directory> _resolveDirectory() async {
    final override = directoryOverride;
    if (override != null) return override;
    final supportDir = await getApplicationSupportDirectory();
    return Directory(p.join(supportDir.path, 'cover_art'));
  }

  /// Writes [bytes] as the cover image for [documentId] and returns the
  /// absolute path to persist via `DocumentRepository.updateCoverImagePath`/
  /// `setAutoExtractedCoverIfAbsent`. No file extension is used -- Flutter's
  /// `Image.file` sniffs format from the byte signature, not the filename,
  /// so one bare `<documentId>` filename works regardless of whether the
  /// cover came from a JPEG-embedding EPUB, a PNG PDF render, or a
  /// user-picked file of any format. Overwrites any existing cover for the
  /// same [documentId] rather than accumulating files.
  Future<String> write(String documentId, Uint8List bytes) async {
    final dir = await _resolveDirectory();
    final file = File(p.join(dir.path, documentId));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file.absolute.path;
  }
}
