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

/// Deterministic, content-derived Dictionary ID: hashes the identifying
/// fields of a Yomitan dictionary's `index.json` (title, revision, format)
/// rather than the zip file's raw bytes. What makes two imports "the same
/// dictionary" is its author-declared identity, not incidental packaging
/// bytes: two zips of the same dictionary release can differ byte-for-byte
/// (different zip tool, different mtimes/compression inside the archive)
/// while still being the same logical dictionary, and must resolve to the
/// same ID so re-importing doesn't create a duplicate `Dictionaries` row. A
/// genuinely different release (the author bumps `revision`) correctly gets
/// a new ID -- the same "corrected re-release gets a new ID" behavior
/// `contentDerivedDocumentId` gives Documents, just keyed on declared
/// metadata instead of source bytes, because that's what identifies a
/// dictionary release (see docs/research/r5-dictionary.md, sections 1 and 6).
///
/// Kept as its own function rather than reusing `contentDerivedDocumentId`
/// directly: the two ID spaces (Document vs Dictionary) hash conceptually
/// different kinds of input (declared metadata strings vs. a source file's
/// raw bytes) and should stay independent rather than risk being confused
/// for one another. Every dictionary importer must use this rather than
/// inventing its own scheme, mirroring `contentDerivedDocumentId`'s role for
/// Documents.
///
/// Each field is length-prefixed before joining (rather than joined with a
/// plain separator) so two different (title, revision) pairs can never hash
/// to the same input by having text shift across the boundary between
/// fields.
String contentDerivedDictionaryId({
  required String title,
  required String revision,
  required int formatVersion,
}) {
  final input =
      '${title.length}:$title:${revision.length}:$revision:$formatVersion';
  return 'dictionary-${sha1.convert(utf8.encode(input))}';
}
