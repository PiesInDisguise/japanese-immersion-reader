import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/manga_ocr_recognizer.dart';

/// Verifies [mangaOcrPostProcess] against concrete before/after examples,
/// ported line-for-line from kha-white/manga-ocr's `post_process`
/// (`manga_ocr/ocr.py`) -- see that function's doc comment for the exact
/// reference source and the (real, verified-against-jaconv's-own-source)
/// correction to how step 4 is sometimes summarized: `kana=True` is
/// jaconv's default and is not overridden by the reference call, so
/// half-width katakana is normalized too, not just ASCII/digits.
void main() {
  group('mangaOcrPostProcess: whitespace stripping', () {
    test('removes an internal half-width space entirely (not just trims)', () {
      expect(mangaOcrPostProcess('こんにちは 世界'), 'こんにちは世界');
    });

    test('removes tabs and newlines', () {
      expect(mangaOcrPostProcess('a\tb\nc'), 'ａｂｃ');
    });

    test('removes a full-width ideographic space', () {
      expect(mangaOcrPostProcess('猫　が　好き'), '猫が好き');
    });

    test('leading/trailing whitespace is also removed, not just collapsed', () {
      expect(mangaOcrPostProcess('  猫  '), '猫');
    });
  });

  group('mangaOcrPostProcess: ellipsis normalization', () {
    test(
      'converts U+2026 ellipsis to three periods, which the final h2z '
      'step then widens to full-width (…->...  ->  ．．．) -- easy to miss '
      'that the *final* output has full-width periods, not ASCII ones',
      () {
        expect(mangaOcrPostProcess('ちょっと…待って'), 'ちょっと．．．待って');
      },
    );

    test('a bare ellipsis with nothing else', () {
      expect(mangaOcrPostProcess('…'), '．．．');
    });
  });

  group('mangaOcrPostProcess: middle-dot / period run collapsing', () {
    test(
      'collapses a run of 2+ full-width middle dots to the same-length run '
      'of periods (then widened to full-width by the final h2z step)',
      () {
        expect(mangaOcrPostProcess('あ・・い'), 'あ．．い');
      },
    );

    test('a single middle dot (below the {2,} threshold) is left untouched', () {
      expect(mangaOcrPostProcess('あ・い'), 'あ・い');
    });

    test('a mixed run of ・ and . still collapses to that many periods', () {
      expect(mangaOcrPostProcess('あ・.・い'), 'あ．．．い');
    });

    test('a longer run preserves its exact length', () {
      expect(mangaOcrPostProcess('あ・・・・い'), 'あ．．．．い');
    });
  });

  group('mangaOcrPostProcess: half-width -> full-width (ascii/digit)', () {
    test('converts ASCII letters and digits to full-width forms', () {
      expect(mangaOcrPostProcess('abc123'), 'ａｂｃ１２３');
    });

    test('converts ASCII punctuation to full-width forms', () {
      expect(mangaOcrPostProcess('a-b!'), 'ａ－ｂ！');
    });
  });

  group('mangaOcrPostProcess: half-width -> full-width (kana)', () {
    test(
      'converts plain half-width katakana to full-width '
      '(kana=True is jaconv\'s default and is not overridden by the '
      'reference -- see function doc comment)',
      () {
        expect(mangaOcrPostProcess('ｱｲｳｴｵ'), 'アイウエオ');
      },
    );

    test('merges half-width dakuten pairs into a single full-width character', () {
      expect(mangaOcrPostProcess('ｶﾞｷﾞ'), 'ガギ');
    });

    test('merges half-width handakuten pairs into a single full-width character', () {
      expect(mangaOcrPostProcess('ﾊﾟﾋﾟ'), 'パピ');
    });

    test('half-width katakana punctuation (｡｢｣､) also normalizes', () {
      expect(mangaOcrPostProcess('ｱｲｳ｡'), 'アイウ。');
    });
  });

  test('a realistic combined example exercises all four steps together', () {
    // Whitespace to strip, an ellipsis, a collapsed dot-run, and half-width
    // ascii -- all in one decoded string, as a real decode might produce.
    expect(
      mangaOcrPostProcess(' 猫 が 好き…OK・・ '),
      '猫が好き．．．ＯＫ．．',
    );
  });

  group('argmaxSoftmaxProbability', () {
    test('picks the index of the largest logit', () {
      final result = argmaxSoftmaxProbability([1.0, 5.0, 2.0]);
      expect(result.index, 1);
      // softmax(5.0) among [1,5,2] relative to the max:
      // 1 / (exp(-4) + exp(0) + exp(-3))
      expect(result.probability, closeTo(0.9362, 0.0005));
    });

    test('uniform logits give uniform probability and the first index', () {
      final result = argmaxSoftmaxProbability([2.0, 2.0, 2.0, 2.0]);
      expect(result.index, 0);
      expect(result.probability, closeTo(0.25, 1e-9));
    });

    test('a single-element input is certain (probability 1.0)', () {
      final result = argmaxSoftmaxProbability([-3.0]);
      expect(result.index, 0);
      expect(result.probability, closeTo(1.0, 1e-9));
    });

    test('is numerically stable for large logits', () {
      final result = argmaxSoftmaxProbability([1000.0, 1001.0, 999.0]);
      expect(result.index, 1);
      expect(result.probability, isNot(isNaN));
      expect(result.probability, greaterThan(0.0));
      expect(result.probability, lessThanOrEqualTo(1.0));
    });

    test('throws on empty input', () {
      expect(() => argmaxSoftmaxProbability([]), throwsArgumentError);
    });
  });
}
