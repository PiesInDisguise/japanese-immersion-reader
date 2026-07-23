import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/deinflector.dart';

void main() {
  group('i-adjective (adj-i)', () {
    const forms = {
      '高かった': 'past',
      '高くない': 'negative',
      '高ければ': 'conditional',
      '高くて': 'te-form',
      '高く': 'adverbial',
    };

    for (final entry in forms.entries) {
      test('${entry.value}: ${entry.key} -> 高い', () {
        expect(
          Deinflector.deinflect(entry.key),
          contains(
            const DeinflectionCandidate(
              term: '高い',
              rule: InflectionRule.iAdjective,
            ),
          ),
        );
      });
    }
  });

  group('ichidan verb (v1)', () {
    const forms = {
      '食べた': 'past',
      '食べない': 'negative',
      '食べて': 'te-form',
      '食べます': 'polite',
      '食べられる': 'passive/potential',
      '食べさせる': 'causative',
      '食べれば': 'conditional',
    };

    for (final entry in forms.entries) {
      test('${entry.value}: ${entry.key} -> 食べる', () {
        expect(
          Deinflector.deinflect(entry.key),
          contains(
            const DeinflectionCandidate(
              term: '食べる',
              rule: InflectionRule.ichidanVerb,
            ),
          ),
        );
      });
    }
  });

  group('godan verb (v5), all nine consonant rows', () {
    const casesByRow = {
      '買う': {
        '買わない': 'negative',
        '買います': 'polite',
        '買われる': 'passive',
        '買わせる': 'causative',
        '買える': 'potential',
        '買えば': 'conditional',
        '買った': 'past',
        '買って': 'te-form',
      },
      '書く': {'書いた': 'past', '書いて': 'te-form', '書かない': 'negative'},
      '泳ぐ': {'泳いだ': 'past', '泳いで': 'te-form', '泳がない': 'negative'},
      '話す': {'話した': 'past', '話して': 'te-form', '話さない': 'negative'},
      '待つ': {'待った': 'past', '待って': 'te-form', '待たない': 'negative'},
      '死ぬ': {'死んだ': 'past', '死んで': 'te-form', '死なない': 'negative'},
      '遊ぶ': {'遊んだ': 'past', '遊んで': 'te-form', '遊ばない': 'negative'},
      '読む': {'読んだ': 'past', '読んで': 'te-form', '読まない': 'negative'},
      '走る': {'走った': 'past', '走って': 'te-form', '走らない': 'negative'},
    };

    casesByRow.forEach((dictionaryForm, forms) {
      group(dictionaryForm, () {
        for (final entry in forms.entries) {
          test('${entry.value}: ${entry.key} -> $dictionaryForm', () {
            expect(
              Deinflector.deinflect(entry.key),
              contains(
                DeinflectionCandidate(
                  term: dictionaryForm,
                  rule: InflectionRule.godanVerb,
                ),
              ),
            );
          });
        }
      });
    });

    test('行く past/te-form use the irregular 行った/行って, not 行いた/行いて', () {
      expect(
        Deinflector.deinflect('行った'),
        contains(
          const DeinflectionCandidate(
            term: '行く',
            rule: InflectionRule.godanVerb,
          ),
        ),
      );
      expect(
        Deinflector.deinflect('行って'),
        contains(
          const DeinflectionCandidate(
            term: '行く',
            rule: InflectionRule.godanVerb,
          ),
        ),
      );
    });
  });

  group('suru verb (vs)', () {
    const forms = {
      '勉強します': 'polite',
      '勉強した': 'past',
      '勉強して': 'te-form',
      '勉強しない': 'negative',
      '勉強できる': 'potential',
      '勉強される': 'passive',
      '勉強させる': 'causative',
    };

    for (final entry in forms.entries) {
      test('${entry.value}: ${entry.key} -> 勉強する', () {
        expect(
          Deinflector.deinflect(entry.key),
          contains(
            const DeinflectionCandidate(
              term: '勉強する',
              rule: InflectionRule.suruVerb,
            ),
          ),
        );
      });
    }

    test('bare する (no preceding noun stem) deinflects too', () {
      expect(
        Deinflector.deinflect('した'),
        contains(
          const DeinflectionCandidate(
            term: 'する',
            rule: InflectionRule.suruVerb,
          ),
        ),
      );
    });
  });

  group('kuru verb (vk), kanji-prefixed spellings only', () {
    const forms = {
      '来ない': 'negative',
      '来た': 'past',
      '来て': 'te-form',
      '来ます': 'polite',
      '来られる': 'passive/potential',
      '来させる': 'causative',
    };

    for (final entry in forms.entries) {
      test('${entry.value}: ${entry.key} -> 来る', () {
        expect(
          Deinflector.deinflect(entry.key),
          contains(
            const DeinflectionCandidate(
              term: '来る',
              rule: InflectionRule.kuruVerb,
            ),
          ),
        );
      });
    }

    test('the kana-only spelling (きた) is a documented gap, not covered', () {
      // Deliberately not asserting emptiness -- some godan/ichidan rule may
      // coincidentally fire on 'きた' -- only that no *kuru* candidate is
      // produced, since kana-only kuru forms aren't recognized (see the
      // Deinflector class doc comment's "known gaps").
      expect(
        Deinflector.deinflect('きた'),
        isNot(
          contains(
            isA<DeinflectionCandidate>().having(
              (c) => c.rule,
              'rule',
              InflectionRule.kuruVerb,
            ),
          ),
        ),
      );
    });
  });

  group('ambiguity and over-generation (by design, see class doc comment)', () {
    test('one surface form can produce multiple distinct candidates', () {
      // 買った ends in った, matching both the godan う-row past rule (->買う)
      // and (spuriously) nothing else meaningful -- but 買える/買われる-style
      // overlaps across categories are common enough that asserting
      // `length > 1` somewhere is worthwhile without pinning an exact count.
      final candidates = Deinflector.deinflect('勉強した');
      expect(
        candidates,
        contains(
          const DeinflectionCandidate(
            term: '勉強する',
            rule: InflectionRule.suruVerb,
          ),
        ),
      );
      // The godan す-row "past" rule also spuriously fires on the same
      // string (stem '勉強' + 'す'), demonstrating over-generation is real
      // and expected, not just theoretical.
      expect(
        candidates,
        contains(
          const DeinflectionCandidate(
            term: '勉強す',
            rule: InflectionRule.godanVerb,
          ),
        ),
      );
    });

    test('deinflect never throws on arbitrary/short input', () {
      expect(() => Deinflector.deinflect(''), returnsNormally);
      expect(() => Deinflector.deinflect('a'), returnsNormally);
      expect(() => Deinflector.deinflect('東京'), returnsNormally);
    });

    test('a bare conjugation ending with no stem at all is not proposed for '
        'regular categories (minStemLength guard)', () {
      // 'ない' alone has zero stem before the ichidan/godan 'ない' suffix --
      // must not produce a nonsense empty-stem candidate like term 'る'.
      final candidates = Deinflector.deinflect('ない');
      expect(
        candidates,
        isNot(
          contains(
            const DeinflectionCandidate(
              term: 'る',
              rule: InflectionRule.ichidanVerb,
            ),
          ),
        ),
      );
    });
  });

  group('DeinflectionCandidate equality', () {
    test('two candidates with the same term and rule are equal', () {
      const a = DeinflectionCandidate(
        term: '買う',
        rule: InflectionRule.godanVerb,
      );
      const b = DeinflectionCandidate(
        term: '買う',
        rule: InflectionRule.godanVerb,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('candidates with a different rule are not equal', () {
      const a = DeinflectionCandidate(
        term: '買う',
        rule: InflectionRule.godanVerb,
      );
      const b = DeinflectionCandidate(
        term: '買う',
        rule: InflectionRule.ichidanVerb,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('InflectionRule.yomitanRuleTag', () {
    test('matches the literal Yomitan rule strings from R5', () {
      expect(InflectionRule.ichidanVerb.yomitanRuleTag, 'v1');
      expect(InflectionRule.godanVerb.yomitanRuleTag, 'v5');
      expect(InflectionRule.suruVerb.yomitanRuleTag, 'vs');
      expect(InflectionRule.kuruVerb.yomitanRuleTag, 'vk');
      expect(InflectionRule.iAdjective.yomitanRuleTag, 'adj-i');
    });
  });
}
