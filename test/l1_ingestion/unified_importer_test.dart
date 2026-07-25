import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/fake_ocr_engine.dart';
import 'package:japanese_immersion_reader/l1_ingestion/unified_importer.dart';

import '../core/document_contract.dart';

void main() {
  test('.epub routes to EpubImporter', () async {
    final document = await importAnyFile(
      File('assets/fixtures/epub_plain_text.epub'),
      onProgress: (_) {},
    );

    expect(document.sourceType, DocumentSourceType.epub);
    checkDocumentContract(document, expectSourceRects: false);
  });

  test('.pdf with a real text layer routes to PdfTextImporter', () async {
    final document = await importAnyFile(
      File('assets/fixtures/synthetic_horizontal_ja.pdf'),
      onProgress: (_) {},
    );

    expect(document.sourceType, DocumentSourceType.pdfText);
    checkDocumentContract(document, expectSourceRects: true);
  });

  test('.pdf with no text layer routes to ScannedPdfImporter, using the '
      'injected OCR engine factory (never a real download in tests)', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'unified_importer_test_',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final document = await importAnyFile(
      File('assets/fixtures/synthetic_scanned_blank.pdf'),
      onProgress: (_) {},
      ocrEngineFactory: FakeOcrEngine.new,
      ocrCacheDirectory: Directory('${tempDir.path}/cache'),
    );

    expect(document.sourceType, DocumentSourceType.pdfScanned);
    checkDocumentContract(document, expectSourceRects: true);
  });

  test('an unsupported extension throws', () async {
    expect(
      () => importAnyFile(File('some/path/book.txt'), onProgress: (_) {}),
      throwsA(isA<StateError>()),
    );
  });
}
