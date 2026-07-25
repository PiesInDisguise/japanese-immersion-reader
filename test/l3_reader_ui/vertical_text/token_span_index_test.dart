import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/vertical_text/token_span_index.dart';

void main() {
  // '猫が走る。' split the way `reconcileSentenceTokens` would actually
  // split it (see card_mode_test_helpers.dart's buildTestTokenizer): four
  // tokens, one of which (走る) spans two characters, so char indices don't
  // just match token indices one-to-one -- the case this class exists for.
  final tokens = const [
    Token(surface: '猫'),
    Token(surface: 'が'),
    Token(surface: '走る'),
    Token(surface: '。'),
  ];

  group('tokenIndexForCharIndex', () {
    test('maps each single-character token to its own index', () {
      final index = TokenSpanIndex(tokens);
      expect(index.tokenIndexForCharIndex(0), 0); // 猫
      expect(index.tokenIndexForCharIndex(1), 1); // が
      expect(index.tokenIndexForCharIndex(4), 3); // 。
    });

    test('maps every character of a multi-character token to that token', () {
      final index = TokenSpanIndex(tokens);
      expect(index.tokenIndexForCharIndex(2), 2); // 走
      expect(index.tokenIndexForCharIndex(3), 2); // る
    });

    test('a single all-encompassing placeholder token (pre-L2) maps every '
        'char index back to index 0', () {
      // Mirrors what PdfTextImporter/pre-Sudachi Sentence.tokens actually
      // look like: one token spanning the whole surface (see
      // core/models/sentence.dart's doc comment).
      final index = TokenSpanIndex(const [Token(surface: '猫が走る。')]);
      for (var i = 0; i < 5; i++) {
        expect(index.tokenIndexForCharIndex(i), 0);
      }
    });

    test('throws RangeError for a negative charIndex', () {
      final index = TokenSpanIndex(tokens);
      expect(() => index.tokenIndexForCharIndex(-1), throwsRangeError);
    });

    test('throws RangeError for a charIndex past the joined surface length', () {
      final index = TokenSpanIndex(tokens);
      expect(() => index.tokenIndexForCharIndex(5), throwsRangeError);
    });

    test('throws RangeError for any charIndex against an empty token list', () {
      final index = TokenSpanIndex(const []);
      expect(() => index.tokenIndexForCharIndex(0), throwsRangeError);
    });

    test('every character of the joined surface round-trips to some valid '
        'token index', () {
      final index = TokenSpanIndex(tokens);
      final joined = tokens.map((t) => t.surface).join();
      for (var i = 0; i < joined.length; i++) {
        final tokenIndex = index.tokenIndexForCharIndex(i);
        expect(tokenIndex, inInclusiveRange(0, tokens.length - 1));
      }
    });
  });

  group('charRangeForToken', () {
    test('single-character tokens each get a length-1 range', () {
      final index = TokenSpanIndex(tokens);
      expect(index.charRangeForToken(0), (0, 1)); // 猫
      expect(index.charRangeForToken(1), (1, 2)); // が
      expect(index.charRangeForToken(3), (4, 5)); // 。
    });

    test('a multi-character token gets the full span it occupies', () {
      final index = TokenSpanIndex(tokens);
      expect(index.charRangeForToken(2), (2, 4)); // 走る
    });

    test('is the exact inverse of tokenIndexForCharIndex over every char', () {
      final index = TokenSpanIndex(tokens);
      for (var tokenIndex = 0; tokenIndex < tokens.length; tokenIndex++) {
        final (start, end) = index.charRangeForToken(tokenIndex);
        for (var charIndex = start; charIndex < end; charIndex++) {
          expect(index.tokenIndexForCharIndex(charIndex), tokenIndex);
        }
      }
    });

    test('a single all-encompassing placeholder token spans the whole text', () {
      final index = TokenSpanIndex(const [Token(surface: '猫が走る。')]);
      expect(index.charRangeForToken(0), (0, 5));
    });
  });
}
