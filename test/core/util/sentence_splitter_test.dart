import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/util/sentence_splitter.dart';

void main() {
  List<String> splitToStrings(String text) => splitIntoSentenceSpans(
    text,
  ).map((s) => text.substring(s.start, s.end)).toList();

  test('splits on 。 terminators', () {
    expect(splitToStrings('彼は東京に行った。そこで友達に会った。'), ['彼は東京に行った。', 'そこで友達に会った。']);
  });

  test('splits on mixed 。！？ terminators', () {
    expect(splitToStrings('大丈夫？うん、大丈夫！良かった。'), ['大丈夫？', 'うん、大丈夫！', '良かった。']);
  });

  test(
    'keeps a terminator inside trailing closing quotes in the same sentence',
    () {
      expect(splitToStrings('「大丈夫？」と彼女に聞いた。'), ['「大丈夫？」と彼女に聞いた。']);
    },
  );

  test(
    'a quote-ending terminator with nothing after it is its own trailing span',
    () {
      expect(splitToStrings('彼は言った。「もう終わりだ。」'), ['彼は言った。', '「もう終わりだ。」']);
    },
  );

  test('keeps an unterminated trailing remainder as its own final span', () {
    expect(splitToStrings('彼は東京に行った。そして'), ['彼は東京に行った。', 'そして']);
  });

  test('returns empty for empty or whitespace-only input', () {
    expect(splitIntoSentenceSpans(''), isEmpty);
    expect(splitIntoSentenceSpans('   '), isEmpty);
  });

  test('spans cover the entire input with no gaps or overlaps', () {
    const text = '彼は東京に行った。そこで友達に会った。まだ続く';
    final spans = splitIntoSentenceSpans(text);

    expect(spans.first.start, 0);
    expect(spans.last.end, text.length);
    for (var i = 1; i < spans.length; i++) {
      expect(
        spans[i].start,
        spans[i - 1].end,
        reason: 'span $i must start exactly where span ${i - 1} ended',
      );
    }
  });
}
