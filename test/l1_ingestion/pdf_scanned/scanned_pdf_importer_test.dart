import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l1_ingestion/importer.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/fake_ocr_engine.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/ocr_engine.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/scanned_pdf_importer.dart';

import '../../core/document_contract.dart';
import 'fake_pdf_page_rasterizer.dart';

/// Always throws if actually invoked. Used to *prove* a code path does not
/// call the engine (e.g. a disk-cache hit): if the assertion under test is
/// wrong and the engine gets called after all, the test fails loudly
/// instead of silently passing.
class _ThrowingOcrEngine implements OcrEngine {
  @override
  Future<List<OcrRegionResult>> recognize(
    Uint8List pageImage, {
    required int width,
    required int height,
    required bool vertical,
  }) async {
    throw StateError(
      '_ThrowingOcrEngine.recognize should not have been called',
    );
  }
}

void main() {
  late Directory tempDir;
  late File sourceFile;
  late Directory cacheDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'scanned_pdf_importer_test_',
    );
    // Content is irrelevant to these tests: FakePdfPageRasterizer never
    // reads it. It only needs to exist on disk so OcrResultCache's
    // size+mtime cache key can be computed via `File.statSync()`.
    sourceFile = File('${tempDir.path}/fake_source.pdf');
    await sourceFile.writeAsBytes([1, 2, 3, 4]);
    cacheDir = Directory('${tempDir.path}/cache');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'reports a progress sequence from parsing through per-page ocr to done',
    () async {
      final events = <ImportProgress>[];
      final importer = ScannedPdfImporter(
        const FakeOcrEngine(),
        rasterizer: FakePdfPageRasterizer(pageCount: 3),
        cacheDirectory: cacheDir,
      );

      await importer.import(sourceFile, onProgress: events.add);

      expect(events.first.stage, ImportStage.parsing);
      expect(events.first.fraction, 0.0);

      final ocrEvents = events
          .where((e) => e.stage == ImportStage.ocr)
          .toList();
      expect(ocrEvents, hasLength(3), reason: 'one ocr event per page');
      for (final e in ocrEvents) {
        expect(e.currentChapterIndex, 0);
      }

      expect(events.any((e) => e.stage == ImportStage.indexing), isTrue);

      expect(events.last.stage, ImportStage.done);
      expect(events.last.fraction, 1.0);

      for (var i = 1; i < events.length; i++) {
        expect(
          events[i].fraction,
          greaterThanOrEqualTo(events[i - 1].fraction),
          reason: 'fraction must never regress',
        );
      }
    },
  );

  test('second import of an unchanged source hits the disk cache instead of '
      're-invoking OCR or re-rasterizing', () async {
    final rasterizer1 = FakePdfPageRasterizer(
      pageCount: 2,
      width: 50,
      height: 60,
    );
    final importer1 = ScannedPdfImporter(
      const FakeOcrEngine(
        defaultRegions: [
          OcrRegionResult(
            text: 'こんにちは。今日は晴れです。',
            x: 1,
            y: 2,
            width: 40,
            height: 20,
            confidence: 0.77,
          ),
        ],
      ),
      rasterizer: rasterizer1,
      cacheDirectory: cacheDir,
    );
    final doc1 = await importer1.import(sourceFile, onProgress: (_) {});
    expect(rasterizer1.openCount, 1);

    final rasterizer2 = FakePdfPageRasterizer(
      pageCount: 2,
      width: 50,
      height: 60,
    );
    final importer2 = ScannedPdfImporter(
      _ThrowingOcrEngine(),
      rasterizer: rasterizer2,
      cacheDirectory: cacheDir,
    );
    final doc2 = await importer2.import(sourceFile, onProgress: (_) {});

    expect(
      doc2,
      equals(doc1),
      reason: 'second import must reproduce the cached document exactly',
    );
    expect(
      rasterizer2.openCount,
      0,
      reason: 'cache hit must skip rasterization entirely, not just OCR',
    );
    checkSentenceIdsStable(doc1, doc2);
  });

  test('OCR confidence flows through to Token.confidence and produces a '
      'contract-valid document', () async {
    final importer = ScannedPdfImporter(
      const FakeOcrEngine(
        defaultRegions: [
          OcrRegionResult(
            text: '猫が好きです。犬も好きです。',
            x: 5,
            y: 6,
            width: 90,
            height: 40,
            confidence: 0.42,
          ),
        ],
      ),
      rasterizer: FakePdfPageRasterizer(pageCount: 1, width: 100, height: 50),
      cacheDirectory: cacheDir,
    );

    final doc = await importer.import(sourceFile, onProgress: (_) {});

    checkDocumentContract(doc, expectSourceRects: true);
    expect(doc.sourceType, DocumentSourceType.pdfScanned);
    expect(doc.chapters, hasLength(1));

    final block = doc.chapters.single.blocks.single;
    expect(block.kind, BlockKind.page);
    expect(block.sentences, hasLength(2), reason: 'split at each 。');
    expect(block.sentences[0].surfaceText, '猫が好きです。');
    expect(block.sentences[1].surfaceText, '犬も好きです。');

    final tokens = block.sentences.expand((s) => s.tokens).toList();
    expect(tokens, isNotEmpty);
    for (final token in tokens) {
      expect(token.confidence, 0.42);
      expect(token.sourceRect, isNotNull);
      expect(token.sourceRect!.pageIndex, 0);
      expect(token.sourceRect!.pageWidth, 100);
      expect(token.sourceRect!.pageHeight, 50);
    }
  });

  test(
    'produces exactly one Block per page, in order, all kind page',
    () async {
      final importer = ScannedPdfImporter(
        const FakeOcrEngine(),
        rasterizer: FakePdfPageRasterizer(pageCount: 5),
        cacheDirectory: cacheDir,
      );
      final doc = await importer.import(sourceFile, onProgress: (_) {});
      checkDocumentContract(doc, expectSourceRects: true);
      final blocks = doc.chapters.single.blocks;
      expect(blocks, hasLength(5));
      for (var i = 0; i < blocks.length; i++) {
        expect(blocks[i].index, i);
        expect(blocks[i].kind, BlockKind.page);
      }
    },
  );

  test(
    'assumeVertical sets Block.direction on every page (default: horizontal)',
    () async {
      final horizontalImporter = ScannedPdfImporter(
        const FakeOcrEngine(),
        rasterizer: FakePdfPageRasterizer(pageCount: 2),
        cacheDirectory: Directory('${cacheDir.path}/horizontal'),
      );
      final horizontalDoc = await horizontalImporter.import(
        sourceFile,
        onProgress: (_) {},
      );
      for (final block in horizontalDoc.chapters.single.blocks) {
        expect(block.direction, WritingDirection.horizontal);
      }

      final verticalImporter = ScannedPdfImporter(
        const FakeOcrEngine(),
        rasterizer: FakePdfPageRasterizer(pageCount: 2),
        cacheDirectory: Directory('${cacheDir.path}/vertical'),
        assumeVertical: true,
      );
      final verticalDoc = await verticalImporter.import(
        sourceFile,
        onProgress: (_) {},
      );
      for (final block in verticalDoc.chapters.single.blocks) {
        expect(block.direction, WritingDirection.vertical);
      }
    },
  );

  test('a page that fails to rasterize becomes an empty block without '
      'aborting the import', () async {
    final importer = ScannedPdfImporter(
      const FakeOcrEngine(
        defaultRegions: [
          OcrRegionResult(
            text: 'ok.',
            x: 0,
            y: 0,
            width: 10,
            height: 10,
            confidence: 0.5,
          ),
        ],
      ),
      rasterizer: FakePdfPageRasterizer(pageCount: 3, failPageIndices: {1}),
      cacheDirectory: cacheDir,
    );
    final doc = await importer.import(sourceFile, onProgress: (_) {});
    checkDocumentContract(doc, expectSourceRects: true);
    final blocks = doc.chapters.single.blocks;
    expect(blocks, hasLength(3));
    expect(
      blocks[1].sentences,
      isEmpty,
      reason: 'the page that failed to render',
    );
    expect(blocks[0].sentences, isNotEmpty);
    expect(blocks[2].sentences, isNotEmpty);
  });

  test('an OCR engine that throws does not abort the import -- affected pages '
      'become empty blocks', () async {
    final importer = ScannedPdfImporter(
      _ThrowingOcrEngine(),
      rasterizer: FakePdfPageRasterizer(pageCount: 2),
      cacheDirectory: cacheDir,
    );
    final doc = await importer.import(sourceFile, onProgress: (_) {});
    checkDocumentContract(doc, expectSourceRects: true);
    final blocks = doc.chapters.single.blocks;
    expect(blocks, hasLength(2));
    for (final block in blocks) {
      expect(block.sentences, isEmpty);
    }
  });
}
