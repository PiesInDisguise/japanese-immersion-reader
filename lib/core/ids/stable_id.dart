import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Deterministic, position-derived ID for a Chapter/Block/Sentence, given the
/// owning document's ID and the node's index path (e.g. `[chapterIndex]` for
/// a Chapter, `[chapterIndex, blockIndex, sentenceIndex]` for a Sentence).
///
/// Deliberately position-derived rather than content-hashed: Card Mode and
/// Document Mode sync position by Sentence ID, and mining/SRS rows key off
/// it, so re-importing or OCR-reprocessing the same source must not shift
/// IDs just because a sentence's recognized text changed slightly. Every
/// importer must call this rather than inventing its own scheme.
String stableNodeId(String documentId, List<int> path) {
  final input = '$documentId/${path.join('/')}';
  return sha1.convert(utf8.encode(input)).toString();
}
