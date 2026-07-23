import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Ensures a large, licensed, not-committed-to-git model file (an ONNX
/// weights file, here) is available locally, fetching it on first use --
/// same reasoning as the Yomitan dictionary assets and the Sudachi
/// dictionary (`lib/app/dictionary_paths.dart`), except those two are still
/// placeholder/dev-fallback-only (see that file's doc comment) whereas OCR's
/// whole point is to work on a real device with no research-spike fixture to
/// fall back to, so this implements the real download rather than punting
/// it.
///
/// An interface (not a bare function) so real OCR engine implementations can
/// have this injected and unit tests can swap in a fake that returns a small
/// local fixture instead of a real multi-hundred-MB network download.
abstract class ModelFetcher {
  /// Returns a local [File] containing the content at [url], downloading it
  /// into the application support directory (under [subDir]/[fileName]) if
  /// not already cached there. [onProgress] (0.0-1.0), if given, reports
  /// download progress -- omitted (never called) if the server doesn't send
  /// a `content-length` header.
  Future<File> ensureDownloaded({
    required String url,
    required String subDir,
    required String fileName,
    void Function(double fraction)? onProgress,
  });
}

/// Real implementation: downloads via a streamed HTTP GET into a `.part`
/// temp file first, only renaming to the final path once the download
/// completes successfully -- so a crash/interruption mid-download can never
/// leave a truncated file sitting at the path future calls treat as "already
/// cached," which would otherwise hand a corrupt model to `OrtSession` with
/// no obvious error until inference itself fails strangely.
class HttpModelFetcher implements ModelFetcher {
  const HttpModelFetcher();

  @override
  Future<File> ensureDownloaded({
    required String url,
    required String subDir,
    required String fileName,
    void Function(double fraction)? onProgress,
  }) async {
    final supportDir = await getApplicationSupportDirectory();
    final targetFile = File(
      p.join(supportDir.path, subDir, fileName),
    );
    if (await targetFile.exists()) return targetFile;

    await targetFile.parent.create(recursive: true);
    final partFile = File('${targetFile.path}.part');

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw StateError(
          'ModelFetcher: GET $url returned HTTP ${response.statusCode}; '
          'expected 200.',
        );
      }

      final total = response.contentLength;
      var received = 0;
      final sink = partFile.openWrite();
      try {
        await response.stream.listen(
          (chunk) {
            sink.add(chunk);
            received += chunk.length;
            if (total != null && total > 0) {
              onProgress?.call(received / total);
            }
          },
        ).asFuture<void>();
      } finally {
        await sink.close();
      }

      await partFile.rename(targetFile.path);
      return targetFile;
    } finally {
      client.close();
    }
  }
}
