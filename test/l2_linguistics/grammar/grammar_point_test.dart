import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_point.dart';

void main() {
  group('GrammarPoint.fromJson/toJson', () {
    test('round-trips every field, including a list of examples', () {
      const point = GrammarPoint(
        id: 'te-iru-progressive',
        pattern: '～ている',
        matcher: 'ている',
        jlptLevel: 'N5',
        explanation: 'Describes an action in progress or a resulting state.',
        examples: [
          GrammarExample(japanese: '本を読んでいます。', english: 'I am reading a book.'),
          GrammarExample(japanese: '窓が開いている。', english: 'The window is open.'),
        ],
      );

      final roundTripped = GrammarPoint.fromJson(point.toJson());

      expect(roundTripped.id, point.id);
      expect(roundTripped.pattern, point.pattern);
      expect(roundTripped.matcher, point.matcher);
      expect(roundTripped.jlptLevel, point.jlptLevel);
      expect(roundTripped.explanation, point.explanation);
      expect(roundTripped.examples, hasLength(2));
      expect(roundTripped.examples[0].japanese, '本を読んでいます。');
      expect(roundTripped.examples[0].english, 'I am reading a book.');
      expect(roundTripped.examples[1].japanese, '窓が開いている。');
    });

    test('an empty examples list round-trips as empty, not null/missing', () {
      const point = GrammarPoint(
        id: 'x',
        pattern: 'x',
        matcher: 'x',
        jlptLevel: 'N5',
        explanation: 'x',
        examples: [],
      );
      expect(GrammarPoint.fromJson(point.toJson()).examples, isEmpty);
    });
  });
}
