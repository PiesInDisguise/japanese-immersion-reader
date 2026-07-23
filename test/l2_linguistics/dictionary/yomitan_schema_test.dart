import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/yomitan_schema.dart';

void main() {
  group('YomitanIndex', () {
    test('parses every field', () {
      final index = YomitanIndex.fromJson({
        'title': 'Test Dictionary',
        'revision': '2026.01.01',
        'format': 3,
        'author': 'Someone',
        'url': 'https://example.invalid',
        'description': 'A test dictionary',
        'attribution': 'Attribution text',
        'sourceLanguage': 'ja',
        'targetLanguage': 'en',
        'frequencyMode': 'rank-based',
        'sequenced': true,
      });

      expect(index.title, 'Test Dictionary');
      expect(index.revision, '2026.01.01');
      expect(index.formatVersion, 3);
      expect(index.author, 'Someone');
      expect(index.url, 'https://example.invalid');
      expect(index.description, 'A test dictionary');
      expect(index.attribution, 'Attribution text');
      expect(index.sourceLanguage, 'ja');
      expect(index.targetLanguage, 'en');
      expect(index.frequencyMode, 'rank-based');
      expect(index.sequenced, isTrue);
    });

    test('accepts the "version" alias for "format"', () {
      final index = YomitanIndex.fromJson({
        'title': 'T',
        'revision': 'R',
        'version': 3,
      });
      expect(index.formatVersion, 3);
    });

    test('prefers "format" over "version" when both are present', () {
      final index = YomitanIndex.fromJson({
        'title': 'T',
        'revision': 'R',
        'format': 3,
        'version': 1,
      });
      expect(index.formatVersion, 3);
    });

    test('defaults optional fields to null/false when absent', () {
      final index = YomitanIndex.fromJson({
        'title': 'T',
        'revision': 'R',
        'format': 3,
      });
      expect(index.author, isNull);
      expect(index.sequenced, isFalse);
    });

    test('throws when title is missing', () {
      expect(
        () => YomitanIndex.fromJson({'revision': 'R', 'format': 3}),
        throwsFormatException,
      );
    });

    test('throws when neither format nor version is present', () {
      expect(
        () => YomitanIndex.fromJson({'title': 'T', 'revision': 'R'}),
        throwsFormatException,
      );
    });
  });

  group('YomitanTermEntry', () {
    test('maps all 8 tuple fields in order', () {
      final entry = YomitanTermEntry.fromTuple([
        '打つ',
        'うつ',
        'vt',
        'v5',
        12,
        ['to hit', 'to strike'],
        101,
        'P',
      ]);

      expect(entry.term, '打つ');
      expect(entry.reading, 'うつ');
      expect(entry.definitionTags, 'vt');
      expect(entry.rules, 'v5');
      expect(entry.score, 12.0);
      expect(entry.definitions, ['to hit', 'to strike']);
      expect(entry.sequence, 101);
      expect(entry.termTags, 'P');
    });

    test('readingNormalized falls back to term when reading is empty', () {
      final entry = YomitanTermEntry.fromTuple([
        'そう',
        '',
        '',
        '',
        5,
        ['so'],
        1,
        '',
      ]);
      expect(entry.readingNormalized, 'そう');
    });

    test('readingNormalized keeps the real reading when it is non-empty', () {
      final entry = YomitanTermEntry.fromTuple([
        '打つ',
        'うつ',
        '',
        '',
        1,
        ['x'],
        1,
        '',
      ]);
      expect(entry.readingNormalized, 'うつ');
    });

    test('accepts a null definitionTags', () {
      final entry = YomitanTermEntry.fromTuple([
        '猫',
        'ねこ',
        null,
        '',
        1,
        ['cat'],
        1,
        '',
      ]);
      expect(entry.definitionTags, isNull);
    });

    test('stores heterogeneous definitions verbatim', () {
      final entry = YomitanTermEntry.fromTuple([
        '猫',
        'ねこ',
        '',
        '',
        1,
        [
          'plain string',
          {'type': 'text', 'text': 'text-typed'},
          {'type': 'image', 'path': 'a.png'},
          {
            'type': 'structured-content',
            'content': {'tag': 'div', 'content': 'x'},
          },
          [
            '行く',
            ['v5'],
          ],
        ],
        1,
        '',
      ]);
      expect(entry.definitions, hasLength(5));
      expect(entry.definitions[0], 'plain string');
      expect(entry.definitions[1], {'type': 'text', 'text': 'text-typed'});
      expect(entry.definitions[4], [
        '行く',
        ['v5'],
      ]);
    });

    test('throws when the tuple has the wrong length', () {
      expect(
        () => YomitanTermEntry.fromTuple(['打つ', 'うつ']),
        throwsFormatException,
      );
    });

    test('throws when a field has the wrong type', () {
      expect(
        () => YomitanTermEntry.fromTuple([
          '打つ',
          'うつ',
          '',
          '',
          'not a number',
          ['x'],
          1,
          '',
        ]),
        throwsFormatException,
      );
    });
  });

  group('YomitanTermMetaEntry', () {
    test('parses freq mode with a bare number payload', () {
      final entry = YomitanTermMetaEntry.fromTuple(['打つ', 'freq', 25]);
      expect(entry.term, '打つ');
      expect(entry.mode, YomitanTermMetaMode.freq);
      expect(entry.data, 25);
      expect(entry.readingForIndex, isNull);
    });

    test(
      'parses freq mode with a {value, displayValue} payload and no reading',
      () {
        final entry = YomitanTermMetaEntry.fromTuple([
          '打つ',
          'freq',
          {'value': 1500, 'displayValue': '1.5k'},
        ]);
        expect(entry.readingForIndex, isNull);
      },
    );

    test(
      'parses freq mode with a reading-specific {reading, frequency} payload',
      () {
        final entry = YomitanTermMetaEntry.fromTuple([
          '打つ',
          'freq',
          {
            'reading': 'うつ',
            'frequency': {'value': 1500},
          },
        ]);
        expect(entry.readingForIndex, 'うつ');
      },
    );

    test('parses pitch mode and pulls out the reading', () {
      final entry = YomitanTermMetaEntry.fromTuple([
        '打つ',
        'pitch',
        {
          'reading': 'うつ',
          'pitches': [
            {'position': 0},
          ],
        },
      ]);
      expect(entry.mode, YomitanTermMetaMode.pitch);
      expect(entry.readingForIndex, 'うつ');
    });

    test('parses ipa mode and pulls out the reading', () {
      final entry = YomitanTermMetaEntry.fromTuple([
        '打つ',
        'ipa',
        {
          'reading': 'うつ',
          'transcriptions': [
            {'ipa': 'ɯtsɯ'},
          ],
        },
      ]);
      expect(entry.mode, YomitanTermMetaMode.ipa);
      expect(entry.readingForIndex, 'うつ');
    });

    test('throws on an unknown mode', () {
      expect(
        () => YomitanTermMetaEntry.fromTuple(['打つ', 'nonsense', 1]),
        throwsFormatException,
      );
    });

    test('throws when the tuple has the wrong length', () {
      expect(
        () => YomitanTermMetaEntry.fromTuple(['打つ', 'freq']),
        throwsFormatException,
      );
    });
  });

  group('YomitanTagEntry', () {
    test('maps all 5 tuple fields in order', () {
      final tag = YomitanTagEntry.fromTuple([
        'v5',
        'partOfSpeech',
        0,
        'godan verb',
        -5,
      ]);
      expect(tag.name, 'v5');
      expect(tag.category, 'partOfSpeech');
      expect(tag.order, 0);
      expect(tag.notes, 'godan verb');
      expect(tag.score, -5.0);
    });

    test('throws when the tuple has the wrong length', () {
      expect(
        () => YomitanTagEntry.fromTuple(['v5', 'partOfSpeech']),
        throwsFormatException,
      );
    });

    test('throws when a field has the wrong type', () {
      expect(
        () => YomitanTagEntry.fromTuple([
          'v5',
          'partOfSpeech',
          'not a number',
          'godan verb',
          -5,
        ]),
        throwsFormatException,
      );
    });
  });
}
