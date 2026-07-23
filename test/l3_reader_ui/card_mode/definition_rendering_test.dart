import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/definition_rendering.dart';

void main() {
  group('parseDefinitionEntries', () {
    test('plain string entries pass through unchanged', () {
      final json = jsonEncode(['a cat', 'feline']);

      expect(parseDefinitionEntries(json), ['a cat', 'feline']);
    });

    test('{type: text} entries extract the text field', () {
      final json = jsonEncode([
        {'type': 'text', 'text': 'a dog'},
      ]);

      expect(parseDefinitionEntries(json), ['a dog']);
    });

    test('a mix of plain strings and {type: text} entries are all handled', () {
      final json = jsonEncode([
        'plain gloss',
        {'type': 'text', 'text': 'typed gloss'},
      ]);

      expect(parseDefinitionEntries(json), ['plain gloss', 'typed gloss']);
    });

    test(
      '{type: image} entries fall back to a plain, non-crashing placeholder',
      () {
        final json = jsonEncode([
          {'type': 'image', 'path': 'cat.png', 'width': 100, 'height': 100},
        ]);

        final result = parseDefinitionEntries(json);

        expect(result, hasLength(1));
        expect(result.single, isNot(contains('cat.png'))); // no raw path dump
        expect(result.single.toLowerCase(), contains('image'));
      },
    );

    test('{type: structured-content} entries fall back to a plain, '
        'non-crashing placeholder', () {
      final json = jsonEncode([
        {
          'type': 'structured-content',
          'content': {
            'tag': 'div',
            'content': [
              {
                'tag': 'ruby',
                'content': [
                  '新明解',
                  {'tag': 'rt', 'content': 'しんめいかい'},
                ],
              },
            ],
          },
        },
      ]);

      final result = parseDefinitionEntries(json);

      expect(result, hasLength(1));
      expect(result.single, isNotEmpty);
    });

    test('a 2-tuple cross-reference entry does not crash and yields text', () {
      final json = jsonEncode([
        [
          'うつ',
          ['v5'],
        ],
      ]);

      expect(() => parseDefinitionEntries(json), returnsNormally);
      expect(parseDefinitionEntries(json).single, isNotEmpty);
    });

    test('an unrecognized map "type" falls back to a labeled placeholder', () {
      final json = jsonEncode([
        {'type': 'something-new', 'data': 42},
      ]);

      final result = parseDefinitionEntries(json);

      expect(result.single, contains('something-new'));
    });

    test('malformed JSON does not throw and returns the raw text', () {
      expect(() => parseDefinitionEntries('not json at all'), returnsNormally);
      expect(parseDefinitionEntries('not json at all'), ['not json at all']);
    });

    test(
      'a non-list top-level JSON value is still handled without throwing',
      () {
        final json = jsonEncode({'unexpected': 'shape'});

        expect(() => parseDefinitionEntries(json), returnsNormally);
        expect(parseDefinitionEntries(json), hasLength(1));
      },
    );
  });
}
