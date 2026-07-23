import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l1_ingestion/epub/epub_importer.dart';
import 'package:japanese_immersion_reader/l1_ingestion/importer.dart';

import '../../core/document_contract.dart';

Future<Document> _importFixture(
  String fileName, {
  List<ImportProgress>? progressEvents,
}) {
  final file = File('assets/fixtures/$fileName');
  return EpubImporter().import(
    file,
    onProgress: (progress) => progressEvents?.add(progress),
  );
}

/// Every token's surface, concatenated in (chapter, block, sentence, token)
/// order -- a robust way to check "nothing was lost or duplicated" without
/// hand-asserting every single token.
String _fullText(Document document) => document.chapters
    .expand((c) => c.blocks)
    .expand((b) => b.sentences)
    .expand((s) => s.tokens)
    .map((t) => t.surface)
    .join();

void main() {
  group('epub_ruby_forms.epub', () {
    test('satisfies the shared document contract', () async {
      final doc = await _importFixture('epub_ruby_forms.epub');
      expect(
        () => checkDocumentContract(doc, expectSourceRects: false),
        returnsNormally,
      );
    });

    test(
      'produces stable sentence IDs across two successive imports',
      () async {
        final a = await _importFixture('epub_ruby_forms.epub');
        final b = await _importFixture('epub_ruby_forms.epub');
        expect(() => checkSentenceIdsStable(a, b), returnsNormally);
      },
    );

    test('reads the book title from dc:title and sourceType epub', () async {
      final doc = await _importFixture('epub_ruby_forms.epub');
      expect(doc.title, 'サンプル小説');
      expect(doc.sourceType, DocumentSourceType.epub);
    });

    test('preserves chapter titles from nav.xhtml, in spine order', () async {
      final doc = await _importFixture('epub_ruby_forms.epub');
      expect(doc.chapters, hasLength(2));
      expect(doc.chapters[0].title, '第一章 はじまり');
      expect(doc.chapters[1].title, '第二章 おわり');
    });

    test('folds the chapter <h1> into its own paragraph block', () async {
      final doc = await _importFixture('epub_ruby_forms.epub');
      final firstBlock = doc.chapters[0].blocks[0];
      expect(firstBlock.kind, BlockKind.paragraph);
      expect(firstBlock.sentences.single.surfaceText, '第一章 はじまり');
    });

    test(
      'rb/rt and bare ruby both split a sentence into ruby/plain tokens',
      () async {
        final doc = await _importFixture('epub_ruby_forms.epub');
        final block = doc.chapters[0].blocks[1]; // first <p>
        expect(block.sentences, hasLength(2));

        final sentence0 = block.sentences[0];
        expect(sentence0.surfaceText, '彼は東京に行った。');
        expect(sentence0.tokens, [
          const Token(surface: '彼は'),
          const Token(surface: '東京', reading: 'とうきょう'),
          const Token(surface: 'に行った。'),
        ]);

        final sentence1 = block.sentences[1];
        expect(sentence1.surfaceText, 'そこで友達に会った。');
        expect(sentence1.tokens, [
          const Token(surface: 'そこで'),
          const Token(surface: '友達', reading: 'ともだち'),
          const Token(surface: 'に会った。'),
        ]);
      },
    );

    test(
      '<rp> fallback parens are excluded from the reconstructed sentence',
      () async {
        final doc = await _importFixture('epub_ruby_forms.epub');
        final block = doc.chapters[0].blocks[2]; // second <p>
        expect(block.sentences, hasLength(1));
        final sentence = block.sentences.single;
        expect(sentence.surfaceText, '「大丈夫?」と彼女に聞いた。');
        expect(sentence.surfaceText.contains('('), isFalse);
        expect(sentence.surfaceText.contains(')'), isFalse);
        final rubyToken = sentence.tokens.firstWhere((t) => t.reading != null);
        expect(rubyToken.surface, '大丈夫');
        expect(rubyToken.reading, 'だいじょうぶ');
      },
    );

    test('two independent ruby runs inside one sentence each keep their own '
        'reading (the R1 schema-gap scenario, end-to-end through the real '
        'importer)', () async {
      final doc = await _importFixture('epub_ruby_forms.epub');
      final block = doc.chapters[0].blocks[3]; // third <p>
      expect(block.sentences, hasLength(1));
      final sentence = block.sentences.single;
      expect(sentence.surfaceText, 'その先生は難しい漢字を書いた。');

      final rubyTokens = sentence.tokens
          .where((t) => t.reading != null)
          .toList();
      expect(rubyTokens, hasLength(2));
      expect(rubyTokens[0].surface, '先生');
      expect(rubyTokens[0].reading, 'せんせい');
      expect(rubyTokens[1].surface, '難しい');
      expect(rubyTokens[1].reading, 'むずかしい');
    });

    test(
      'a chapter with no ruby at all still imports with single-token sentences',
      () async {
        final doc = await _importFixture('epub_ruby_forms.epub');
        final block = doc.chapters[1].blocks[1];
        expect(block.sentences, hasLength(2));
        for (final sentence in block.sentences) {
          expect(sentence.tokens, hasLength(1));
          expect(sentence.tokens.single.reading, isNull);
        }
      },
    );

    test(
      'reports per-chapter parsing progress followed by a final done event',
      () async {
        final events = <ImportProgress>[];
        await _importFixture('epub_ruby_forms.epub', progressEvents: events);

        expect(events, isNotEmpty);
        final last = events.removeLast();
        expect(last.stage, ImportStage.done);
        expect(last.fraction, 1.0);

        expect(events, hasLength(2)); // 2 chapters
        for (final event in events) {
          expect(event.stage, ImportStage.parsing);
        }
        expect(events[0].currentChapterIndex, 0);
        expect(events[0].fraction, closeTo(0.5, 1e-9));
        expect(events[1].currentChapterIndex, 1);
        expect(events[1].fraction, closeTo(1.0, 1e-9));
      },
    );
  });

  group('epub_plain_text.epub', () {
    test('satisfies the shared document contract', () async {
      final doc = await _importFixture('epub_plain_text.epub');
      expect(
        () => checkDocumentContract(doc, expectSourceRects: false),
        returnsNormally,
      );
    });

    test(
      'produces stable sentence IDs across two successive imports',
      () async {
        final a = await _importFixture('epub_plain_text.epub');
        final b = await _importFixture('epub_plain_text.epub');
        expect(() => checkSentenceIdsStable(a, b), returnsNormally);
      },
    );

    test(
      'falls back to toc.ncx for chapter titles when there is no nav.xhtml',
      () async {
        final doc = await _importFixture('epub_plain_text.epub');
        expect(doc.chapters.map((c) => c.title).toList(), ['一章', '二章']);
      },
    );

    test(
      'every token has a null reading (no ruby anywhere in this book)',
      () async {
        final doc = await _importFixture('epub_plain_text.epub');
        final allTokens = doc.chapters
            .expand((c) => c.blocks)
            .expand((b) => b.sentences)
            .expand((s) => s.tokens);
        expect(allTokens, isNotEmpty);
        for (final token in allTokens) {
          expect(token.reading, isNull);
        }
      },
    );

    test(
      'every sentence with no ruby has exactly one token (the common case)',
      () async {
        final doc = await _importFixture('epub_plain_text.epub');
        final allSentences = doc.chapters
            .expand((c) => c.blocks)
            .expand((b) => b.sentences);
        for (final sentence in allSentences) {
          expect(sentence.tokens, hasLength(1));
        }
      },
    );

    test(
      'multi-sentence paragraphs split into separate Sentence nodes',
      () async {
        final doc = await _importFixture('epub_plain_text.epub');
        // <h1>一章</h1> + first <p> (2 sentences) + second <p> (1 sentence).
        final chapter0 = doc.chapters[0];
        expect(chapter0.blocks, hasLength(3));
        expect(chapter0.blocks[1].sentences, hasLength(2));
        expect(chapter0.blocks[1].sentences[0].surfaceText, '猫は屋根の上で眠っていた。');
        expect(chapter0.blocks[1].sentences[1].surfaceText, '日差しは暖かかった。');
      },
    );
  });

  group('epub_malformed.epub', () {
    test('satisfies the shared document contract', () async {
      final doc = await _importFixture('epub_malformed.epub');
      expect(
        () => checkDocumentContract(doc, expectSourceRects: false),
        returnsNormally,
      );
    });

    test(
      'produces stable sentence IDs across two successive imports',
      () async {
        final a = await _importFixture('epub_malformed.epub');
        final b = await _importFixture('epub_malformed.epub');
        expect(() => checkSentenceIdsStable(a, b), returnsNormally);
      },
    );

    test('still reads the OPF title and nav.xhtml chapter title', () async {
      final doc = await _importFixture('epub_malformed.epub');
      expect(doc.title, '壊れた本');
      expect(doc.chapters.single.title, '第一章');
    });

    test('recovers ruby and full text through the package:html fallback '
        'despite the unclosed <b> tag', () async {
      final doc = await _importFixture('epub_malformed.epub');
      final chapter = doc.chapters.single;
      // <h1>第一章</h1> folded, plus the one (malformed) <p>.
      expect(chapter.blocks, hasLength(2));

      final paragraph = chapter.blocks[1];
      expect(paragraph.sentences, hasLength(2));
      expect(paragraph.sentences[0].surfaceText, 'これは壊れた本タグです。');
      expect(paragraph.sentences[1].surfaceText, 'まだ続く文章がある。');

      final rubyToken = paragraph.sentences[0].tokens.firstWhere(
        (t) => t.reading != null,
      );
      expect(rubyToken.surface, '本');
      expect(rubyToken.reading, 'ほん');
    });

    test('reconstructed full text has nothing lost or duplicated', () async {
      final doc = await _importFixture('epub_malformed.epub');
      expect(_fullText(doc), '第一章これは壊れた本タグです。まだ続く文章がある。');
    });
  });
}
