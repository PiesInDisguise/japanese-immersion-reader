import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l2_linguistics/kana.dart';

void main() {
  group('katakanaToHiragana', () {
    test('converts a plain katakana reading', () {
      expect(katakanaToHiragana('マジョ'), 'まじょ');
    });

    test('converts small katakana (youon/sokuon) correctly', () {
      expect(katakanaToHiragana('キュウビン'), 'きゅうびん');
      expect(katakanaToHiragana('ガッコウ'), 'がっこう');
    });

    test('leaves the prolonged-sound mark ー unconverted', () {
      expect(katakanaToHiragana('ラーメン'), 'らーめん');
    });

    test('leaves kanji, ASCII, and punctuation unchanged', () {
      expect(katakanaToHiragana('魔女123!?'), '魔女123!?');
    });

    test('leaves already-hiragana text unchanged', () {
      expect(katakanaToHiragana('まじょ'), 'まじょ');
    });

    test('handles an empty string', () {
      expect(katakanaToHiragana(''), '');
    });

    test('converts mixed kanji and katakana text', () {
      expect(katakanaToHiragana('食べルコト'), '食べること');
    });
  });
}
