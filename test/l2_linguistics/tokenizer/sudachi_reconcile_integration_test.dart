// Proves the real SudachiTokenizer's output flows correctly through
// reconcileSentenceTokens end-to-end against a sample L1 (EPUB-style)
// sentence -- i.e. the full L1+L2 merge pipeline (see
// lib/l2_linguistics/tokenizer/reconcile.dart), not just the tokenizer in
// isolation (that's sudachi_tokenizer_test.dart).
//
// Skips (rather than fails) if the research-spike dictionary this test
// setup reuses isn't present on disk -- see sudachi_test_support.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l2_linguistics/tokenizer/reconcile.dart';

import 'sudachi_test_support.dart';

void main() {
  test('real SudachiTokenizer output reconciles with L1 placeholder tokens '
      'for "彼は東京に行った", with ruby overriding Sudachi\'s own reading', () async {
    if (!sudachiTestDictionaryAvailable) {
      markTestSkipped(
        'research/r4_tokenizer/spike_rs/resources/system_small.dic not '
        'present -- see docs/research/r4-tokenizer.md Appendix to fetch '
        'it.',
      );
      return;
    }

    final tokenizer = await createTestSudachiTokenizer();

    // L1 (EPUB-style) placeholder tokens for "he went to Tokyo", with
    // author-supplied ruby on 東京 the way the EPUB importer preserves it
    // -- see reconcile.dart's own doc comment and reconcile_test.dart.
    // sourceRect/confidence are both null, matching EPUB (reflowable,
    // exact text -- no page geometry or OCR uncertainty).
    final l1 = [
      const Token(surface: '彼は'),
      const Token(surface: '東京', reading: 'とうきょう'),
      const Token(surface: 'に行った'),
    ];
    final sentence = l1.map((t) => t.surface).join();
    expect(sentence, '彼は東京に行った');

    final sudachiTokens = await tokenizer.tokenize(sentence);
    final result = reconcileSentenceTokens(l1, sudachiTokens);

    // The merged list still reconstructs the exact sentence, and its
    // segmentation is Sudachi's real one (6 morphemes: 彼/は/東京/に/行っ/た),
    // not L1's coarse 3-token placeholder split.
    expect(result.map((t) => t.surface).join(), sentence);
    expect(result.map((t) => t.surface).toList(), [
      '彼',
      'は',
      '東京',
      'に',
      '行っ',
      'た',
    ]);

    // dictForm/pos/inflection come exclusively from the real tokenizer.
    expect(result[0].dictForm, '彼');
    final iku = result.firstWhere((t) => t.surface == '行っ');
    expect(iku.dictForm, '行く');
    expect(iku.inflection, isNotNull);

    // Ruby wins over Sudachi's own reading for 東京 (spec §4: author-
    // supplied furigana must not be regenerated), but dictForm/pos still
    // come from Sudachi -- reconcileSentenceTokens only ever overrides
    // reading/sourceRect/confidence, never segmentation or grammar.
    final tokyo = result.firstWhere((t) => t.surface == '東京');
    expect(tokyo.reading, 'とうきょう');
    expect(tokyo.dictForm, '東京');
    expect(tokyo.pos, '名詞,固有名詞,地名,一般');

    // 彼 had no L1 reading override, so Sudachi's own reading survives.
    expect(result.firstWhere((t) => t.surface == '彼').reading, 'カレ');

    // No EPUB source has page geometry or OCR confidence.
    expect(result.every((t) => t.sourceRect == null), isTrue);
    expect(result.every((t) => t.confidence == null), isTrue);
  });
}
