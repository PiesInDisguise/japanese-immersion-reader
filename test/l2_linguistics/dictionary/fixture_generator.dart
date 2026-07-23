// Generates the Yomitan-format dictionary fixtures under assets/fixtures/
// used by dictionary_importer_test.dart. Not a test itself (no test()/
// group() calls, and its filename doesn't end in `_test.dart`, so `flutter
// test` never picks it up) -- mirrors
// test/l1_ingestion/epub/fixture_generator.dart's role for this module.
//
// Content is hand-authored, not fetched from yomidevs/yomitan's own test
// suite. docs/research/r5-dictionary.md identified their
// test/data/dictionaries/valid-dictionary1 fixture as a good sample, but
// Yomitan is GPL-3.0-licensed (R5 §6) and that fixture's specific example
// words/glosses are that project's own content, not just schema facts -- so
// this fixture instead exercises the *same schema shapes* (confirmed
// against the real schema files in R5 §1) with entirely original example
// data, built from native Dart data structures and `jsonEncode`d rather
// than hand-typed as JSON text, so syntax can't drift from what the
// importer actually expects.
//
// Run from the repo root:
//   dart run test/l2_linguistics/dictionary/fixture_generator.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

void main() {
  _writeZip(
    'assets/fixtures/yomitan_sample_dictionary.zip',
    _sampleDictionaryEntries(),
  );
  _writeZip(
    'assets/fixtures/yomitan_second_dictionary.zip',
    _secondDictionaryEntries(),
  );
  _writeZip(
    'assets/fixtures/yomitan_unsupported_format.zip',
    _unsupportedFormatEntries(),
  );
  _writeZip(
    'assets/fixtures/yomitan_missing_index.zip',
    _missingIndexEntries(),
  );
}

void _writeZip(String path, Map<String, Object> jsonEntries) {
  final archive = Archive();
  jsonEntries.forEach((name, data) {
    archive.add(ArchiveFile.string(name, jsonEncode(data)));
  });
  final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
  File(path).writeAsBytesSync(bytes);
}

// ---------------------------------------------------------------------------
// Fixture 1: a small but complete format-3 dictionary exercising every bank
// type and every definition/term-meta sub-shape confirmed in R5 §1. Two
// term_bank files and two tag_bank files, to also exercise multi-file
// aggregation within one bank type.
// ---------------------------------------------------------------------------

Map<String, Object> _sampleDictionaryEntries() {
  final index = {
    'title': 'JIR Sample Dictionary',
    'revision': '2026.07.22',
    'format': 3,
    'author': 'Japanese Immersion Reader fixtures',
    'url': 'https://example.invalid/jir-sample-dictionary',
    'description':
        'Hand-authored fixture exercising every Yomitan v3 bank type.',
    'attribution': "Original fixture content for this project's test suite.",
    'sourceLanguage': 'ja',
    'targetLanguage': 'en',
    'frequencyMode': 'rank-based',
    'sequenced': true,
  };

  // Godan verb (v5), common (P), with a realistic definitionTags value.
  final utsu = [
    '打つ',
    'うつ',
    'vt',
    'v5',
    12,
    ['to hit; to strike', 'to knock'],
    101,
    'P',
  ];
  // Kana-only headword with an empty reading -- exercises the "empty
  // reading means same as term" normalization rule.
  final sou = [
    'そう',
    '',
    '',
    '',
    5,
    ['so; in that way'],
    102,
    '',
  ];
  // i-adjective (adj-i), {type: text} definition.
  final takai = [
    '高い',
    'たかい',
    'adj-i',
    'adj-i',
    8,
    [
      {'type': 'text', 'text': 'high; tall'},
    ],
    103,
    '',
  ];
  // Ichidan verb (v1), for deinflection tests.
  final taberu = [
    '食べる',
    'たべる',
    'v1',
    'v1',
    10,
    ['to eat'],
    104,
    'P',
  ];
  // Suru verb (vs), for deinflection tests.
  final benkyouSuru = [
    '勉強する',
    'べんきょうする',
    'vs',
    'vs',
    6,
    ['to study'],
    105,
    '',
  ];
  // Kuru verb (vk), for deinflection tests.
  final kuru = [
    '来る',
    'くる',
    'vk',
    'vk',
    9,
    ['to come'],
    106,
    '',
  ];
  // Godan verb with the 行く irregular past/te exception.
  final iku = [
    '行く',
    'いく',
    'v5',
    'v5',
    7,
    ['to go'],
    107,
    '',
  ];
  final termBank1 = [utsu, sou, takai, taberu, benkyouSuru, kuru, iku];

  // Noun (uninflectable, rules ''), structured-content definition.
  final neko = [
    '猫',
    'ねこ',
    'n',
    '',
    15,
    [
      {
        'type': 'structured-content',
        'content': {
          'tag': 'div',
          'content': [
            'A small domesticated carnivorous mammal. See also: ',
            {
              'tag': 'ruby',
              'content': [
                '子猫',
                {'tag': 'rt', 'content': 'こねこ'},
              ],
            },
            ' (kitten).',
          ],
        },
      },
    ],
    201,
    'P',
  ];
  // Noun, {type: image} definition. The path doesn't need to resolve to a
  // real file in this fixture zip -- storage keeps definitions opaque;
  // resolving/rendering images is separate, later UI work.
  final e = [
    '絵',
    'え',
    'n',
    '',
    4,
    [
      {
        'type': 'image',
        'path': 'images/e_example.png',
        'width': 32,
        'height': 32,
        'alt': 'a simple picture',
        'title': 'example image definition',
      },
    ],
    202,
    '',
  ];
  // 2-tuple cross-reference definition: "this sense is itself an inflected
  // form of X" -- distinct from the `rules` field (R5 §1).
  final itta = [
    '行った',
    'いった',
    '',
    '',
    1,
    [
      [
        '行く',
        ['v5'],
      ],
    ],
    203,
    '',
  ];
  final termBank2 = [neko, e, itta];

  final termMetaBank1 = [
    ['打つ', 'freq', 25],
    [
      '打つ',
      'freq',
      {
        'reading': 'うつ',
        'frequency': {'value': 1500, 'displayValue': '1.5k'},
      },
    ],
    [
      '打つ',
      'pitch',
      {
        'reading': 'うつ',
        'pitches': [
          {'position': 0},
        ],
      },
    ],
    [
      '打つ',
      'ipa',
      {
        'reading': 'うつ',
        'transcriptions': [
          {
            'ipa': 'ɯtsɯ',
            'tags': ['general'],
          },
        ],
      },
    ],
    [
      '食べる',
      'pitch',
      {
        'reading': 'たべる',
        'pitches': [
          {
            'position': 2,
            'tags': ['v1'],
          },
        ],
      },
    ],
  ];

  final tagBank1 = [
    ['v5', 'partOfSpeech', 0, 'godan verb', -5],
    ['v1', 'partOfSpeech', 0, 'ichidan verb', -5],
    ['vs', 'partOfSpeech', 0, 'suru verb', -5],
    ['vk', 'partOfSpeech', 0, 'kuru verb', -5],
    ['adj-i', 'partOfSpeech', 0, 'i-adjective', -5],
  ];
  final tagBank2 = [
    ['P', 'popular', 0, 'common word', 5],
    ['vt', 'partOfSpeech', 1, 'transitive verb', -3],
    ['n', 'partOfSpeech', 1, 'noun', -3],
  ];

  return {
    'index.json': index,
    'term_bank_1.json': termBank1,
    'term_bank_2.json': termBank2,
    'term_meta_bank_1.json': termMetaBank1,
    'tag_bank_1.json': tagBank1,
    'tag_bank_2.json': tagBank2,
  };
}

// ---------------------------------------------------------------------------
// Fixture 2: a second, distinct, minimal valid dictionary -- for testing
// that importing an additional dictionary assigns the next free priority
// rather than colliding with an already-installed one.
// ---------------------------------------------------------------------------

Map<String, Object> _secondDictionaryEntries() {
  return {
    'index.json': {
      'title': 'JIR Second Sample Dictionary',
      'revision': '1.0',
      'format': 3,
    },
    'term_bank_1.json': [
      [
        '犬',
        'いぬ',
        'n',
        '',
        3,
        ['dog'],
        1,
        '',
      ],
    ],
  };
}

// ---------------------------------------------------------------------------
// Fixture 3: a format-1 index.json -- must be rejected before any bank file
// is even parsed (R5 §1: only format 3 is supported here).
// ---------------------------------------------------------------------------

Map<String, Object> _unsupportedFormatEntries() {
  return {
    'index.json': {
      'title': 'Old Format Dictionary',
      'revision': '1',
      'format': 1,
    },
    'term_bank_1.json': [
      [
        '古い',
        'ふるい',
        'adj-i',
        'adj-i',
        1,
        ['old'],
        1,
        '',
      ],
    ],
  };
}

// ---------------------------------------------------------------------------
// Fixture 4: a zip with no index.json at all.
// ---------------------------------------------------------------------------

Map<String, Object> _missingIndexEntries() {
  return {
    'term_bank_1.json': [
      [
        '何か',
        'なにか',
        '',
        '',
        1,
        ['something'],
        1,
        '',
      ],
    ],
  };
}
