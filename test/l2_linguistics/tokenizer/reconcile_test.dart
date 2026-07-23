import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l2_linguistics/tokenizer/reconcile.dart';

void main() {
  test(
    'no-ruby sentence: Sudachi segmentation and grammar win, reading falls back to Sudachi',
    () {
      final l1 = [const Token(surface: '食べさせられた')];
      final sudachi = [
        const Token(
          surface: '食べ',
          dictForm: '食べる',
          reading: 'たべ',
          pos: '動詞',
          inflection: '連用形',
        ),
        const Token(
          surface: 'させ',
          dictForm: 'させる',
          reading: 'させ',
          pos: '助動詞',
          inflection: '連用形',
        ),
        const Token(
          surface: 'られ',
          dictForm: 'られる',
          reading: 'られ',
          pos: '助動詞',
          inflection: '連用形',
        ),
        const Token(
          surface: 'た',
          dictForm: 'た',
          reading: 'タ',
          pos: '助動詞',
          inflection: '終止形',
        ),
      ];

      final result = reconcileSentenceTokens(l1, sudachi);

      expect(result.map((t) => t.surface).join(), '食べさせられた');
      expect(result.length, 4);
      expect(result[0].dictForm, '食べる');
      expect(result[0].reading, 'たべ'); // Sudachi's own reading, no L1 override
      expect(result.every((t) => t.sourceRect == null), isTrue);
      expect(result.every((t) => t.confidence == null), isTrue);
    },
  );

  test(
    'PDF/OCR sentence: single L1 token with sourceRect+confidence is inherited by every resulting Sudachi token',
    () {
      const rect = SourceRect(
        pageIndex: 0,
        x: 10,
        y: 20,
        width: 100,
        height: 30,
        pageWidth: 600,
        pageHeight: 800,
      );
      final l1 = [
        const Token(surface: '吾輩は猫である', sourceRect: rect, confidence: 0.92),
      ];
      final sudachi = [
        const Token(surface: '吾輩', dictForm: '吾輩', reading: 'ワガハイ', pos: '代名詞'),
        const Token(surface: 'は', dictForm: 'は', reading: 'ハ', pos: '助詞'),
        const Token(surface: '猫', dictForm: '猫', reading: 'ネコ', pos: '名詞'),
        const Token(surface: 'で', dictForm: 'だ', reading: 'デ', pos: '助動詞'),
        const Token(surface: 'ある', dictForm: 'ある', reading: 'アル', pos: '動詞'),
      ];

      final result = reconcileSentenceTokens(l1, sudachi);

      expect(result.map((t) => t.surface).join(), '吾輩は猫である');
      for (final token in result) {
        expect(token.sourceRect, rect);
        expect(token.confidence, 0.92);
      }
    },
  );

  test(
    'ruby span aligning exactly with a Sudachi token boundary carries its reading over',
    () {
      final l1 = [
        const Token(surface: '彼は'),
        const Token(surface: '東京', reading: 'とうきょう'),
        const Token(surface: 'に行った'),
      ];
      final sudachi = [
        const Token(surface: '彼', dictForm: '彼', reading: 'カレ', pos: '代名詞'),
        const Token(surface: 'は', dictForm: 'は', reading: 'ハ', pos: '助詞'),
        const Token(surface: '東京', dictForm: '東京', reading: 'トウキョウ', pos: '名詞'),
        const Token(surface: 'に', dictForm: 'に', reading: 'ニ', pos: '助詞'),
        const Token(surface: '行っ', dictForm: '行く', reading: 'イッ', pos: '動詞'),
        const Token(surface: 'た', dictForm: 'た', reading: 'タ', pos: '助動詞'),
      ];

      final result = reconcileSentenceTokens(l1, sudachi);

      final tokyo = result.firstWhere((t) => t.surface == '東京');
      expect(tokyo.reading, 'とうきょう'); // ruby wins over Sudachi's own トウキョウ
      expect(result.firstWhere((t) => t.surface == '彼').reading, 'カレ');
    },
  );

  test(
    'a ruby span Sudachi splits into multiple morphemes attributes its reading only once, not to every piece',
    () {
      // Regression test for a real bug caught during design: an earlier
      // version of reconcileSentenceTokens attributed a ruby reading
      // independently per Sudachi token, so a single ruby span split into
      // multiple Sudachi morphemes ended up with the *same* reading
      // duplicated onto every piece instead of attributed once.
      final l1 = [const Token(surface: '東京', reading: 'とうきょう')];
      final sudachi = [
        const Token(surface: '東', dictForm: '東', reading: 'ヒガシ', pos: '名詞'),
        const Token(surface: '京', dictForm: '京', reading: 'キョウ', pos: '名詞'),
      ];

      final result = reconcileSentenceTokens(l1, sudachi);

      expect(result[0].reading, 'とうきょう');
      expect(result[1].reading, 'キョウ'); // Sudachi's own -- not duplicated
    },
  );

  test(
    'a Sudachi token spanning multiple L1 tokens unions their rects and takes the lowest confidence',
    () {
      const rectA = SourceRect(
        pageIndex: 0,
        x: 0,
        y: 0,
        width: 10,
        height: 10,
        pageWidth: 100,
        pageHeight: 100,
      );
      const rectB = SourceRect(
        pageIndex: 0,
        x: 8,
        y: 0,
        width: 10,
        height: 10,
        pageWidth: 100,
        pageHeight: 100,
      );
      final l1 = [
        const Token(surface: '大', sourceRect: rectA, confidence: 0.95),
        const Token(surface: '丈夫', sourceRect: rectB, confidence: 0.6),
      ];
      final sudachi = [
        const Token(
          surface: '大丈夫',
          dictForm: '大丈夫',
          reading: 'ダイジョウブ',
          pos: '形容動詞',
        ),
      ];

      final result = reconcileSentenceTokens(l1, sudachi);

      expect(result, hasLength(1));
      expect(result.single.confidence, 0.6); // lowest of 0.95 and 0.6
      final unioned = result.single.sourceRect!;
      expect(unioned.x, 0);
      expect(unioned.width, 18); // spans from rectA.x=0 to rectB.x+width=18
    },
  );

  test('throws if L1 and tokenizer surface text disagree', () {
    final l1 = [const Token(surface: 'こんにちは')];
    final sudachi = [const Token(surface: 'こんばんは', dictForm: 'こんばんは')];

    expect(() => reconcileSentenceTokens(l1, sudachi), throwsArgumentError);
  });
}
