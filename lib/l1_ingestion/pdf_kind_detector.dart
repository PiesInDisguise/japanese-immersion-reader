import 'package:pdfrx_engine/pdfrx_engine.dart';

/// Whether a PDF's pages carry a real text layer ([text]) or are effectively
/// image-only ([scanned]) -- the signal `unified_importer.dart` uses to pick
/// between [PdfTextImporter] and [ScannedPdfImporter] for a `.pdf` file
/// without asking the user.
///
/// Out of scope: hybrid PDFs with a mix of text and scanned pages. This
/// heuristic picks one importer for the whole document, matching both
/// importers' existing all-or-nothing scope (see their own doc comments).
enum PdfKind { text, scanned }

/// Samples up to [sampleSize] pages, evenly spaced across [pdfDocument]
/// (not the first N -- a cover/title page can be image-only even in a
/// genuine text-layer book), and classifies the whole document as
/// [PdfKind.scanned] if the total non-whitespace character count extracted
/// from those pages' text layer falls below [nonWhitespaceThreshold]. Real
/// text pages contribute hundreds of characters each; an image-only page
/// contributes ~zero from the text layer, so the threshold only needs to
/// separate "some real text found" from "none," not finely calibrate page
/// density.
Future<PdfKind> detectPdfKind(
  PdfDocument pdfDocument, {
  int sampleSize = 5,
  int nonWhitespaceThreshold = 20,
}) async {
  final pageCount = pdfDocument.pages.length;
  if (pageCount == 0) return PdfKind.scanned;

  final sampledIndices = _evenlySpacedIndices(pageCount, sampleSize);

  var nonWhitespaceCount = 0;
  for (final pageIndex in sampledIndices) {
    final pageText = await pdfDocument.pages[pageIndex].loadStructuredText();
    nonWhitespaceCount += pageText.fullText
        .replaceAll(RegExp(r'\s'), '')
        .length;
    if (nonWhitespaceCount >= nonWhitespaceThreshold) return PdfKind.text;
  }
  return PdfKind.scanned;
}

List<int> _evenlySpacedIndices(int pageCount, int sampleSize) {
  final count = sampleSize < pageCount ? sampleSize : pageCount;
  if (count <= 1) return [0];
  return [
    for (var i = 0; i < count; i++) (i * (pageCount - 1) / (count - 1)).round(),
  ];
}
