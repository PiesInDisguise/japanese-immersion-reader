import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/stats/comprehension_calculator.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';

void main() {
  group('ComprehensionCalculator', () {
    test('returns null when there are no countable tokens', () async {
      final calculator = ComprehensionCalculator(
        ({required dictForm, required reading}) async => false,
      );
      final result = await calculator.compute([
        [const Token(surface: '。')],
      ]);
      expect(result, isNull);
    });

    test('computes the fraction of collected words', () async {
      final collected = {'猫|ネコ', '好き|スキ'};
      final calculator = ComprehensionCalculator(
        ({required dictForm, required reading}) async =>
            collected.contains('$dictForm|$reading'),
      );

      final tokens = [
        [
          const Token(surface: '猫', dictForm: '猫', reading: 'ネコ'),
          const Token(surface: 'が', dictForm: 'が', reading: 'ガ'),
          const Token(surface: '好き', dictForm: '好き', reading: 'スキ'),
          const Token(surface: 'です', dictForm: 'です', reading: 'デス'),
        ],
      ];

      final result = await calculator.compute(tokens);

      // 4 non-punctuation tokens, 2 collected ("猫" and "好き").
      expect(result, 0.5);
    });

    test('excludes punctuation-only tokens from both halves of the ratio', () async {
      final calculator = ComprehensionCalculator(
        ({required dictForm, required reading}) async => true,
      );

      final tokens = [
        [
          const Token(surface: '猫', dictForm: '猫', reading: 'ネコ'),
          const Token(surface: '。', dictForm: '。', reading: '。'),
        ],
      ];

      final result = await calculator.compute(tokens);

      expect(result, 1.0);
    });

    test('falls back to surface when dictForm/reading are null', () async {
      final calls = <String>[];
      final calculator = ComprehensionCalculator(
        ({required dictForm, required reading}) async {
          calls.add('$dictForm|$reading');
          return false;
        },
      );

      await calculator.compute([
        [const Token(surface: '猫')],
      ]);

      expect(calls, ['猫|猫']);
    });
  });
}
