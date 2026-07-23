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

/// Deterministic, content-derived Document ID: hashing the source file's
/// bytes (not its path) means re-importing the same file from a different
/// location resolves to the same Document instead of a duplicate, and a
/// genuinely changed file (a corrected re-release, say) correctly gets a
/// new one. `sourceTypePrefix` should match the importer's
/// `DocumentSourceType` name (`epub`, `pdfText`, `pdfScanned`) so IDs are
/// visually traceable to their source at a glance.
///
/// This is the one deliberate exception to `stableNodeId`'s
/// position-not-content philosophy: a whole `Document`'s identity is a
/// different concern from a `Sentence`'s position-synced identity within
/// it, and every importer must use this rather than inventing its own
/// scheme, so `Document.id` derivation stays consistent across sources.
String contentDerivedDocumentId(String sourceTypePrefix, List<int> bytes) {
  return '$sourceTypePrefix-${sha1.convert(bytes)}';
}
