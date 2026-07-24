import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../pdf_scanned/model_fetcher.dart';
import 'remote_book_source.dart';

/// Fetches a [RemoteBookEntry]'s actual file, caching it locally --
/// deliberately reuses [ModelFetcher] (the same fetch-once-then-local-file
/// pattern already used for OCR model weights) rather than a second copy
/// of the same streamed-download-with-progress logic. A remote book is a
/// large, licensed-to-the-user, not-worth-re-fetching asset in exactly the
/// same sense a model weight file is, even though the two have nothing else
/// in common domain-wise.
class RemoteBookDownloader {
  const RemoteBookDownloader([this._fetcher = const HttpModelFetcher()]);

  final ModelFetcher _fetcher;

  /// Downloads [entry] into a local cache file, reusing an already-
  /// downloaded copy if one exists. Keyed by [RemoteBookEntry.id] (hashed,
  /// since ids can contain characters unsafe for filenames -- e.g. a
  /// WebDAV href with slashes), not the download URL, so a source that
  /// changes its URL scheme without changing a book's identity doesn't
  /// re-download it.
  Future<File> download(
    RemoteBookEntry entry, {
    void Function(double fraction)? onProgress,
  }) {
    final extension = p.extension(Uri.parse(entry.downloadUrl).path);
    final safeId = sha1.convert(utf8.encode(entry.id)).toString();
    return _fetcher.ensureDownloaded(
      url: entry.downloadUrl,
      subDir: 'remote_books',
      fileName: '$safeId$extension',
      onProgress: onProgress,
    );
  }
}
