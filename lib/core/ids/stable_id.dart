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

/// Deterministic, content-derived id for a `CollectedWord` row (spec §11):
/// hashes `dictForm`+`reading` (length-prefixed, exactly like
/// `contentDerivedDictionaryId` above and for the same reason -- so two
/// different (dictForm, reading) pairs can never hash identically by having
/// text shift across the join) rather than generating a random id.
///
/// This is what makes "is this word already collected" (spec §6's
/// re-tap-resets-it behavior) a direct primary-key lookup on
/// `CollectedWords.id` instead of a separate uniqueness query, and what
/// makes mining the same word twice -- once from today's chapter, once from
/// a subtitle track later -- resolve to one row with two sightings rather
/// than a duplicate row. Word identity is `dictForm`+`reading` rather than
/// `dictForm` alone because the same dictionary form can carry more than one
/// reading (different words), which must not collapse into one entry.
String contentDerivedWordId({
  required String dictForm,
  required String reading,
}) {
  final input = '${dictForm.length}:$dictForm:${reading.length}:$reading';
  return 'word-${sha1.convert(utf8.encode(input))}';
}

/// Deterministic id for a `CollectedGrammar` row (spec §11: `id,
/// grammarPointId`). Unlike [contentDerivedWordId], there's no compound key
/// to collapse here -- a grammar point's own id *is* its collection
/// identity (the grammar-point database itself is a later phase per spec
/// §8, so `grammarPointId` is taken as an already-unique opaque string).
/// This just namespaces it with a prefix, like the other
/// `contentDerived*Id` functions, rather than hashing -- hashing an
/// already-unique id would add nothing.
String contentDerivedGrammarId(String grammarPointId) =>
    'grammar-$grammarPointId';

/// Deterministic id for a cached LLM grammar explanation (spec §8 layer 3:
/// "cached permanently by sentence hash"). Hashes the sentence's own text
/// *and* its surrounding context together (length-prefixed, same reasoning
/// as [contentDerivedWordId]) rather than reusing the sentence's own
/// position-derived `Sentence.id`: the explanation depends on what the
/// sentence and its context actually say, not where it sits in a particular
/// document, so identical text+context (e.g. the same line quoted in two
/// books, or re-imported after a minor OCR re-run that didn't change this
/// sentence) shares one cached call instead of paying for it twice.
String contentDerivedExplanationId({
  required String sentenceText,
  required String contextText,
}) {
  final input =
      '${sentenceText.length}:$sentenceText:${contextText.length}:$contextText';
  return 'explanation-${sha1.convert(utf8.encode(input))}';
}
