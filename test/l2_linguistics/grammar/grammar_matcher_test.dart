import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_database.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_matcher.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_point.dart';

const _teIru = GrammarPoint(
  id: 'te-iru-progressive',
  pattern: '～ている',
  matcher: 'ている|ていた',
  jlptLevel: 'N5',
  explanation: 'progressive/resulting state',
  examples: [],
);

const _tai = GrammarPoint(
  id: 'tai-desire',
  pattern: '～たい',
  matcher: 'たい',
  jlptLevel: 'N5',
  explanation: 'want to',
  examples: [],
);

void main() {
  group('GrammarMatcher.matchSentence (synthetic points)', () {
    test('returns every point whose matcher appears in the sentence', () {
      final matcher = GrammarMatcher([_teIru, _tai]);
      final matches = matcher.matchSentence('日本語を勉強したいと思っている。');

      expect(matches, hasLength(2));
      expect(matches.map((m) => m.point.id), containsAll(['te-iru-progressive', 'tai-desire']));
    });

    test('a sentence matching no points returns an empty list', () {
      final matcher = GrammarMatcher([_teIru, _tai]);
      expect(matcher.matchSentence('猫が好きです。'), isEmpty);
    });

    test('reports the literal matched substring, not just which point matched', () {
      final matcher = GrammarMatcher([_teIru]);
      final matches = matcher.matchSentence('彼はもう帰っていた。');
      expect(matches.single.matchedText, 'ていた');
    });

    test('preserves construction order in results, not match-position order', () {
      // _tai's matcher appears first in the sentence, but the matcher list
      // is constructed [_teIru, _tai] -- results should still list _teIru
      // first, matching the doc comment's stated ordering guarantee.
      final matcher = GrammarMatcher([_teIru, _tai]);
      final matches = matcher.matchSentence('食べたいと思っている。');
      expect(matches.map((m) => m.point.id).toList(), [
        'te-iru-progressive',
        'tai-desire',
      ]);
    });

    test('a point present more than once in one sentence is only reported '
        'once', () {
      final matcher = GrammarMatcher([_teIru]);
      final matches = matcher.matchSentence('走っている犬を見ている。');
      expect(matches, hasLength(1));
    });
  });

  group('GrammarMatcher against the real bundled grammar-point database', () {
    testWidgets(
      'every seed grammar point\'s own example sentences match its own '
      'matcher -- a real regression check against the committed data, not '
      'just synthetic points',
      (tester) async {
        final points = await loadGrammarPoints();
        expect(
          points,
          isNotEmpty,
          reason: 'expected at least the seed grammar points to be present',
        );

        for (final point in points) {
          final matcher = GrammarMatcher([point]);
          for (final example in point.examples) {
            final matches = matcher.matchSentence(example.japanese);
            expect(
              matches,
              isNotEmpty,
              reason:
                  'GrammarPoint "${point.id}" (matcher: ${point.matcher}) '
                  'did not match its own example sentence '
                  '"${example.japanese}" -- either the matcher regex or the '
                  'example sentence has a typo.',
            );
          }
        }
      },
    );

    testWidgets('every grammar point has a unique id', (tester) async {
      final points = await loadGrammarPoints();
      final ids = points.map((p) => p.id).toList();
      expect(
        ids.toSet(),
        hasLength(ids.length),
        reason: 'expected no duplicate GrammarPoint ids in the bundled database',
      );
    });

    testWidgets('every grammar point has at least one example', (tester) async {
      final points = await loadGrammarPoints();
      for (final point in points) {
        expect(
          point.examples,
          isNotEmpty,
          reason: 'GrammarPoint "${point.id}" has no example sentences',
        );
      }
    });
  });
}
