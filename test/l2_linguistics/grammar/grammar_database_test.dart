import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_database.dart';

const _validJlptLevels = {'N5', 'N4', 'N3', 'N2', 'N1'};

void main() {
  group('loadGrammarPoints', () {
    testWidgets('loads the bundled asset without throwing', (tester) async {
      await expectLater(loadGrammarPoints(), completes);
    });

    testWidgets('every entry has a valid JLPT level', (tester) async {
      final points = await loadGrammarPoints();
      for (final point in points) {
        expect(
          _validJlptLevels.contains(point.jlptLevel),
          isTrue,
          reason:
              'GrammarPoint "${point.id}" has jlptLevel '
              '"${point.jlptLevel}", expected one of $_validJlptLevels',
        );
      }
    });

    testWidgets(
      'every entry\'s matcher compiles as a valid regular expression',
      (tester) async {
        final points = await loadGrammarPoints();
        for (final point in points) {
          expect(
            () => RegExp(point.matcher),
            returnsNormally,
            reason:
                'GrammarPoint "${point.id}" has an invalid matcher regex: '
                '${point.matcher}',
          );
        }
      },
    );

    testWidgets('every entry has a non-empty pattern, explanation, and id', (
      tester,
    ) async {
      final points = await loadGrammarPoints();
      for (final point in points) {
        expect(point.id, isNotEmpty);
        expect(point.pattern, isNotEmpty);
        expect(point.explanation, isNotEmpty);
      }
    });
  });
}
