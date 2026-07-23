import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';

/// Every L1 importer's own tests must run their fixture-produced `Document`
/// through this before merging (see docs/spec.md §3-4 and the build plan's
/// Phase 1 Step 0). It is the one place that encodes the structural
/// invariants every later layer (tokenizer, dictionary, mining, SRS) relies
/// on: contiguous indices, non-empty sentences, and sourceRect nullability
/// matching the source format.
void checkDocumentContract(
  Document document, {
  required bool expectSourceRects,
}) {
  for (
    var chapterIndex = 0;
    chapterIndex < document.chapters.length;
    chapterIndex++
  ) {
    final chapter = document.chapters[chapterIndex];
    expect(
      chapter.index,
      chapterIndex,
      reason: 'Chapter indices must be contiguous from 0',
    );

    for (var blockIndex = 0; blockIndex < chapter.blocks.length; blockIndex++) {
      final block = chapter.blocks[blockIndex];
      expect(
        block.index,
        blockIndex,
        reason: 'Block indices must be contiguous from 0 within a chapter',
      );

      for (
        var sentenceIndex = 0;
        sentenceIndex < block.sentences.length;
        sentenceIndex++
      ) {
        final sentence = block.sentences[sentenceIndex];
        expect(
          sentence.index,
          sentenceIndex,
          reason: 'Sentence indices must be contiguous from 0 within a block',
        );
        expect(
          sentence.tokens,
          isNotEmpty,
          reason:
              'Every sentence must have at least one token, even pre-tokenization',
        );

        for (final token in sentence.tokens) {
          if (expectSourceRects) {
            expect(
              token.sourceRect,
              isNotNull,
              reason: 'PDF/OCR-sourced tokens must carry a sourceRect',
            );
          } else {
            expect(
              token.sourceRect,
              isNull,
              reason: 'Reflowable EPUB tokens must not carry a sourceRect',
            );
          }
        }
      }
    }
  }
}

/// Asserts that re-importing the same source produced identical Sentence IDs
/// at each (chapter, block, sentence) position — the invariant Card Mode and
/// Document Mode position-sync depend on.
void checkSentenceIdsStable(Document first, Document second) {
  expect(_sentenceIdsByPosition(second), equals(_sentenceIdsByPosition(first)));
}

Map<String, String> _sentenceIdsByPosition(Document document) {
  final result = <String, String>{};
  for (final chapter in document.chapters) {
    for (final block in chapter.blocks) {
      for (final sentence in block.sentences) {
        result['${chapter.index}/${block.index}/${sentence.index}'] =
            sentence.id;
      }
    }
  }
  return result;
}
