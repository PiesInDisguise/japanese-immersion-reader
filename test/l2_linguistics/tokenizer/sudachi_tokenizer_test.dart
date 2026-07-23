// Loads the actual compiled Sudachi native library (not a fake/mock) and
// proves SudachiTokenizer.tokenize produces the real segmentation/
// dictForm/reading/pos/inflection chain -- the load-bearing proof for the
// R4 tokenizer integration (see docs/research/r4-tokenizer.md and
// lib/l2_linguistics/tokenizer/sudachi_tokenizer.dart).
//
// Skips (rather than fails) if the research-spike dictionary this test
// setup reuses isn't present on disk -- see sudachi_test_support.dart.

import 'package:flutter_test/flutter_test.dart';

import 'sudachi_test_support.dart';

const _skipReason =
    'research/r4_tokenizer/spike_rs/resources/system_small.dic not present '
    '-- see docs/research/r4-tokenizer.md Appendix to fetch it.';

void main() {
  test('tokenize(食べさせられた) returns the real causative+passive+past chain '
      'from the compiled Sudachi library (docs/spec.md §8)', () async {
    if (!sudachiTestDictionaryAvailable) {
      markTestSkipped(_skipReason);
      return;
    }

    final tokenizer = await createTestSudachiTokenizer();
    final tokens = await tokenizer.tokenize('食べさせられた');

    expect(tokens.map((t) => t.surface).toList(), ['食べ', 'させ', 'られ', 'た']);

    expect(tokens[0].dictForm, '食べる');
    expect(tokens[0].reading, 'タベ');
    expect(tokens[0].pos, '動詞,一般');
    expect(tokens[0].inflection, '下一段-バ行,連用形-一般');

    expect(tokens[1].dictForm, 'させる'); // causative
    expect(tokens[2].dictForm, 'られる'); // passive
    expect(tokens[3].dictForm, 'た'); // past

    // Every token satisfies the Tokenizer contract: fully populated
    // except sourceRect/confidence, which a Tokenizer never sees.
    for (final t in tokens) {
      expect(t.dictForm, isNotNull);
      expect(t.reading, isNotNull);
      expect(t.pos, isNotNull);
      expect(t.inflection, isNotNull);
      expect(t.sourceRect, isNull);
      expect(t.confidence, isNull);
    }
  });

  test('tokenize leaves inflection null for non-inflecting words (nouns, '
      'interjections)', () async {
    if (!sudachiTestDictionaryAvailable) {
      markTestSkipped(_skipReason);
      return;
    }

    final tokenizer = await createTestSudachiTokenizer();
    final tokens = await tokenizer.tokenize('こんにちは世界');

    final greeting = tokens.firstWhere((t) => t.surface == 'こんにちは');
    expect(greeting.pos, '感動詞,一般');
    expect(greeting.inflection, isNull);

    final world = tokens.firstWhere((t) => t.surface == '世界');
    expect(world.dictForm, '世界');
    expect(world.reading, 'セカイ');
    expect(world.pos, '名詞,普通名詞,一般');
    expect(world.inflection, isNull);
  });
}
