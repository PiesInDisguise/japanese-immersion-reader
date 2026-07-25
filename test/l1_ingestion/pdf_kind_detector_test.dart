import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_kind_detector.dart';
import 'package:pdfrx_engine/pdfrx_engine.dart';

Future<PdfDocument> _open(String assetPath) async {
  await pdfrxInitialize();
  return PdfDocument.openFile(assetPath);
}

void main() {
  test('classifies a real text-layer PDF as PdfKind.text', () async {
    final doc = await _open('assets/fixtures/synthetic_horizontal_ja.pdf');
    addTearDown(doc.dispose);

    expect(await detectPdfKind(doc), PdfKind.text);
  });

  test('classifies an image-only (no text layer) PDF as PdfKind.scanned', () async {
    final doc = await _open('assets/fixtures/synthetic_scanned_blank.pdf');
    addTearDown(doc.dispose);

    expect(await detectPdfKind(doc), PdfKind.scanned);
  });

  test('samples pages evenly, not just the first N -- a blank cover page '
      'does not misclassify a document that has real text elsewhere', () async {
    final doc = await _open('assets/fixtures/synthetic_blank_cover_ja.pdf');
    addTearDown(doc.dispose);

    // Page 0 is a blank "cover" with no text layer; page 1 has real text.
    // Sampling every page (sampleSize >= pageCount) must still reach page 1
    // and classify the document as text, not stop after a blank page 0.
    expect(await detectPdfKind(doc, sampleSize: 5), PdfKind.text);
  });

  test('sampleSize of 1 on the blank-cover fixture only samples page 0, '
      'demonstrating why the default sampleSize must exceed 1', () async {
    final doc = await _open('assets/fixtures/synthetic_blank_cover_ja.pdf');
    addTearDown(doc.dispose);

    expect(await detectPdfKind(doc, sampleSize: 1), PdfKind.scanned);
  });
}
