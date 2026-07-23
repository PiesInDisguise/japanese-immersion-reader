import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l1_ingestion/epub/epub_ruby.dart';
import 'package:japanese_immersion_reader/l1_ingestion/epub/epub_sentence_builder.dart';

void main() {
  group('tokenListsForBlock', () {
    test(
      'a block with no ruby at all yields exactly one token per sentence',
      () {
        final runs = [TextRun('それから二人は静かに歩いた。夜はまだ長い。')];
        final sentences = tokenListsForBlock(runs);

        expect(sentences, hasLength(2));
        expect(sentences[0], [const Token(surface: 'それから二人は静かに歩いた。')]);
        expect(sentences[1], [const Token(surface: '夜はまだ長い。')]);
      },
    );

    test(
      'a single ruby run confined to one sentence becomes its own token',
      () {
        final runs = [TextRun('彼は'), RubyRun('東京', 'とうきょう'), TextRun('に行った。')];
        final sentences = tokenListsForBlock(runs);

        expect(sentences, hasLength(1));
        expect(sentences.single, [
          const Token(surface: '彼は'),
          const Token(surface: '東京', reading: 'とうきょう'),
          const Token(surface: 'に行った。'),
        ]);
      },
    );

    test('a ruby run adjacent to the very start/end of a sentence does not '
        'produce an empty surrounding token', () {
      final runs = [RubyRun('本', 'ほん'), TextRun('だ。')];
      final sentences = tokenListsForBlock(runs);

      expect(sentences.single, [
        const Token(surface: '本', reading: 'ほん'),
        const Token(surface: 'だ。'),
      ]);
    });

    test('two independent ruby runs inside the same sentence each become '
        'their own token (the R1 schema-gap scenario)', () {
      final runs = [
        TextRun('その'),
        RubyRun('先生', 'せんせい'),
        TextRun('は'),
        RubyRun('難しい', 'むずかしい'),
        TextRun('漢字を書いた。'),
      ];
      final sentences = tokenListsForBlock(runs);

      expect(sentences, hasLength(1));
      expect(sentences.single, [
        const Token(surface: 'その'),
        const Token(surface: '先生', reading: 'せんせい'),
        const Token(surface: 'は'),
        const Token(surface: '難しい', reading: 'むずかしい'),
        const Token(surface: '漢字を書いた。'),
      ]);
      // Every token's linguistic fields besides `reading` stay null --
      // that's exclusively L2 (Sudachi)'s job.
      for (final token in sentences.single) {
        expect(token.dictForm, isNull);
        expect(token.pos, isNull);
        expect(token.inflection, isNull);
        expect(token.sourceRect, isNull);
      }
    });

    test('a ruby run spanning a sentence boundary splits the surrounding '
        'plain text across sentences, in reading order', () {
      // "彼は東京に行った。そこで友達に会った。" -- the ruby runs sit entirely
      // within their own sentence, but the plain-text run between them
      // ("に行った。そこで") straddles the sentence boundary and must be cut.
      final runs = [
        TextRun('彼は'),
        RubyRun('東京', 'とうきょう'),
        TextRun('に行った。そこで'),
        RubyRun('友達', 'ともだち'),
        TextRun('に会った。'),
      ];
      final sentences = tokenListsForBlock(runs);

      expect(sentences, hasLength(2));
      expect(sentences[0], [
        const Token(surface: '彼は'),
        const Token(surface: '東京', reading: 'とうきょう'),
        const Token(surface: 'に行った。'),
      ]);
      expect(sentences[1], [
        const Token(surface: 'そこで'),
        const Token(surface: '友達', reading: 'ともだち'),
        const Token(surface: 'に会った。'),
      ]);

      // Concatenating every token's surface text must reconstruct exactly
      // the block's flattened plain text, with nothing lost or duplicated.
      final reconstructed = sentences
          .expand((tokens) => tokens)
          .map((t) => t.surface)
          .join();
      expect(reconstructed, plainTextOf(runs));
    });

    test('returns [] for a block whose flattened text is empty', () {
      expect(tokenListsForBlock(const []), isEmpty);
      expect(tokenListsForBlock([TextRun('   ')]), isEmpty);
    });

    test('a lone unterminated sentence still yields a token list', () {
      final runs = [TextRun('まだ続く')];
      final sentences = tokenListsForBlock(runs);
      expect(sentences, [
        [const Token(surface: 'まだ続く')],
      ]);
    });
  });
}
