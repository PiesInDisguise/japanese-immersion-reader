import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/fake_ocr_engine.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/scanned_pdf_importer.dart';

import '../../core/document_contract.dart';

/// Companion to scanned_pdf_importer_test.dart, which exercises the
/// orchestration (progress/cache/confidence) against a synthetic
/// `FakePdfPageRasterizer` for speed and determinism. This file instead
/// proves the *production* default -- `PdfrxPageRasterizer`, rasterizing a
/// real PDF via `pdfrx_engine`'s PDFium bindings -- actually works
/// end-to-end against a real fixture.
void main() {
  test('rasterizes a real PDF fixture via pdfrx_engine and produces a '
      'contract-valid document', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'scanned_pdf_importer_real_fixture_test_',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    // Default `rasterizer` -- exercises PdfrxPageRasterizer for real.
    final importer = ScannedPdfImporter(
      const FakeOcrEngine(),
      cacheDirectory: Directory('${tempDir.path}/cache'),
    );

    final doc = await importer.import(
      File('assets/fixtures/synthetic_horizontal_ja.pdf'),
      onProgress: (_) {},
    );

    checkDocumentContract(doc, expectSourceRects: true);
    expect(doc.sourceType, DocumentSourceType.pdfScanned);
    expect(doc.chapters, hasLength(1));
    expect(doc.chapters.single.blocks, isNotEmpty);
    for (final block in doc.chapters.single.blocks) {
      expect(block.kind, BlockKind.page);
    }
    for (final sentence in doc.chapters.single.blocks.first.sentences) {
      for (final token in sentence.tokens) {
        expect(token.sourceRect!.pageWidth, greaterThan(0));
        expect(token.sourceRect!.pageHeight, greaterThan(0));
      }
    }
  });
}
