import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l1_ingestion/importer.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_text/pdf_text_importer.dart';
import 'package:pdfrx_engine/pdfrx_engine.dart';

import '../../core/document_contract.dart';

void main() {
  const importer = PdfTextImporter();

  Future<Document> importFixture(String assetPath) {
    return importer.import(File(assetPath), onProgress: (_) {});
  }

  group('PdfTextImporter - synthetic_horizontal_ja.pdf', () {
    late Document document;

    setUpAll(() async {
      document = await importFixture(
        'assets/fixtures/synthetic_horizontal_ja.pdf',
      );
    });

    test('satisfies the document contract with sourceRects', () {
      checkDocumentContract(document, expectSourceRects: true);
    });

    test('produces exactly one chapter with one page block', () {
      expect(document.sourceType, DocumentSourceType.pdfText);
      expect(document.chapters, hasLength(1));
      expect(document.chapters.single.index, 0);
      expect(document.chapters.single.blocks, hasLength(1));
      expect(document.chapters.single.blocks.single.kind, BlockKind.page);
      expect(
        document.chapters.single.blocks.single.direction,
        WritingDirection.horizontal,
      );
    });

    test('splits the page into the three period-terminated sentences', () {
      final sentences = document.chapters.single.blocks.single.sentences;

      expect(sentences.map((s) => s.surfaceText), [
        '吾輩は猫である。',
        '名前はまだ無い。',
        'どこで生れたかとんと見当がつかぬ。',
      ]);
      // No stray whitespace/newlines leaked from the row-boundary filler
      // character PDFium inserts between the two lines.
      for (final sentence in sentences) {
        expect(sentence.surfaceText.contains('\n'), isFalse);
        expect(sentence.surfaceText.contains(' '), isFalse);
      }
    });

    test('flips PDFium bottom-left/y-up rects to top-left/y-down', () {
      final firstSentenceRect = document
          .chapters
          .single
          .blocks
          .single
          .sentences
          .first
          .tokens
          .single
          .sourceRect!;

      expect(firstSentenceRect.pageIndex, 0);
      expect(firstSentenceRect.pageWidth, closeTo(420, 0.01));
      expect(firstSentenceRect.pageHeight, closeTo(300, 0.01));
      // The first line sits near the visual TOP of the page. Its raw PDF
      // top (~275.46 in bottom-left/y-up space on a 300pt-tall page) is
      // close to pageHeight -- top-left/y-down must represent "near the
      // top" as a SMALL y instead, or every tap target in the app is
      // vertically mirrored.
      expect(firstSentenceRect.y, lessThan(firstSentenceRect.pageHeight / 2));
      expect(firstSentenceRect.y, closeTo(300 - 275.46, 1));
      expect(firstSentenceRect.height, closeTo(275.46 - 256.66, 1));
    });
  });

  group('PdfTextImporter - vertical reading order (the R2 regression)', () {
    late Document sim;
    late Document scrambled;

    setUpAll(() async {
      sim = await importFixture(
        'assets/fixtures/synthetic_vertical_sim_ja.pdf',
      );
      scrambled = await importFixture(
        'assets/fixtures/synthetic_vertical_scrambled_ja.pdf',
      );
    });

    test('both satisfy the document contract with sourceRects', () {
      checkDocumentContract(sim, expectSourceRects: true);
      checkDocumentContract(scrambled, expectSourceRects: true);
    });

    test('sim fixture (already paint-order-correct) reconstructs the right-to'
        '-left, top-to-bottom reading order', () {
      final sentences = sim.chapters.single.blocks.single.sentences;

      // No terminator punctuation in this fixture (see gen_fixtures.dart),
      // so the whole page is exactly one unterminated sentence span.
      expect(sentences, hasLength(1));
      expect(sentences.single.surfaceText, '吾輩は猫である名前はまだ無いどこで生れたかとんと見当がつかぬ');
      expect(
        sim.chapters.single.blocks.single.direction,
        WritingDirection.vertical,
      );
    });

    test('scrambled paint-order fixture reconstructs the SAME text as the sim '
        'fixture, despite different underlying paint order -- proving reading '
        'order is geometric, not extraction-order-dependent', () {
      final simSentences = sim.chapters.single.blocks.single.sentences;
      final scrambledSentences =
          scrambled.chapters.single.blocks.single.sentences;

      expect(scrambledSentences, hasLength(simSentences.length));
      expect(
        scrambledSentences.single.surfaceText,
        simSentences.single.surfaceText,
      );
      expect(
        scrambledSentences.single.surfaceText,
        '吾輩は猫である名前はまだ無いどこで生れたかとんと見当がつかぬ',
      );
      expect(
        scrambled.chapters.single.blocks.single.direction,
        WritingDirection.vertical,
      );

      // The two fixtures are pixel-identical (same glyph positions; only
      // content-stream paint order differs), so the reconstructed
      // aggregate sourceRect should match closely too, not just the text.
      final simRect = simSentences.single.tokens.single.sourceRect!;
      final scrambledRect = scrambledSentences.single.tokens.single.sourceRect!;
      expect(scrambledRect.x, closeTo(simRect.x, 0.5));
      expect(scrambledRect.y, closeTo(simRect.y, 0.5));
      expect(scrambledRect.width, closeTo(simRect.width, 0.5));
      expect(scrambledRect.height, closeTo(simRect.height, 0.5));
    });
  });

  group('PdfTextImporter - progress reporting', () {
    test(
      'reports one parsing update per page, then a final done update',
      () async {
        final events = <ImportProgress>[];
        await importer.import(
          File('assets/fixtures/synthetic_horizontal_ja.pdf'),
          onProgress: events.add,
        );

        expect(events, hasLength(2)); // 1 page + 1 final "done"
        expect(events.first.stage, ImportStage.parsing);
        expect(events.first.fraction, closeTo(1.0, 0.001));
        expect(events.first.currentChapterIndex, 0);
        expect(events.last.stage, ImportStage.done);
        expect(events.last.fraction, closeTo(1.0, 0.001));
      },
    );
  });

  group('PdfTextImporter - ID stability', () {
    test('re-importing the same file yields identical sentence IDs', () async {
      final first = await importFixture(
        'assets/fixtures/synthetic_horizontal_ja.pdf',
      );
      final second = await importFixture(
        'assets/fixtures/synthetic_horizontal_ja.pdf',
      );

      checkSentenceIdsStable(first, second);
    });
  });

  group('PdfTextImporter - preOpened', () {
    test('reuses a caller-supplied PdfDocument instead of opening its own, '
        'and does not dispose it', () async {
      await pdfrxInitialize();
      final path = 'assets/fixtures/synthetic_horizontal_ja.pdf';
      final preOpened = await PdfDocument.openFile(path);

      final document = await importer.import(
        File(path),
        onProgress: (_) {},
        preOpened: preOpened,
      );

      checkDocumentContract(document, expectSourceRects: true);
      expect(document.chapters.single.blocks.single.sentences, hasLength(3));
      // Still usable -- proves import() didn't dispose a handle it was
      // only lent, not given ownership of.
      expect(preOpened.pages, isNotEmpty);
      await preOpened.dispose();
    });
  });
}
