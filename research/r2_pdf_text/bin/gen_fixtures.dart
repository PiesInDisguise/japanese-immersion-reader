// THROWAWAY research script (r2_pdf_text spike). Generates two synthetic
// Japanese-text PDF fixtures to test pdfrx/pdfrx_engine's text-extraction
// API against. Not part of the main app.
//
//   fixtures/fixture_horizontal.pdf
//     A normal paragraph of horizontal Japanese text, laid out by the `pdf`
//     package's real text-flow/wrapping engine (pw.Text) -- i.e. NOT
//     hand-placed. This is a fair test of "extract a realistic horizontal
//     page of prose."
//
//   fixtures/fixture_vertical_sim.pdf
//     A *simulated* vertical-text (縦書き) page. IMPORTANT CAVEAT: this is
//     NOT a true PDF vertical-writing-mode page (that requires a CID font
//     with WMode 1 / vertical glyph metrics and a shaping engine this spike
//     doesn't have time to build). Instead each character is individually
//     placed, upright, at explicit (x, y) coordinates chosen to reproduce
//     the *geometry* of vertical Japanese typesetting: characters descend
//     top-to-bottom within a column, and successive columns run
//     right-to-left across the page (rightmost column = start of text).
//     This is a legitimate test of pdfrx's direction heuristic, because
//     that heuristic (vector2direction() in pdfrx_engine's
//     pdf_text_formatter.dart) classifies direction purely from the
//     relative positions of consecutive character boxes -- not from font
//     vertical-metrics flags or glyph rotation angle -- so upright glyphs
//     laid out in descending-y/right-to-left-column order is exactly the
//     signal it keys off of. See docs/research/r2-pdf-text.md for the
//     full writeup and residual risk this doesn't cover.
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> main() async {
  final fontBytes = File(r'C:\Windows\Fonts\yumin.ttf').readAsBytesSync();

  Directory('fixtures').createSync(recursive: true);

  await _genHorizontal(pw.Font.ttf(fontBytes.buffer.asByteData()));
  await _writeVerticalFixture(
    fontBytes,
    'fixtures/fixture_vertical_sim.pdf',
    paintInVisualReadingOrder: true,
  );
  await _writeVerticalFixture(
    fontBytes,
    'fixtures/fixture_vertical_scrambled.pdf',
    paintInVisualReadingOrder: false,
  );

  stdout.writeln('Wrote fixtures/fixture_horizontal.pdf');
  stdout.writeln('Wrote fixtures/fixture_vertical_sim.pdf');
  stdout.writeln('Wrote fixtures/fixture_vertical_scrambled.pdf');
}

/// Famous public-domain opening line of Natsume Soseki's Wagahai wa Neko de
/// Aru (1905) -- out of copyright, thematically apt for a light-novel-reader
/// test fixture.
const _line1 = '吾輩は猫である。名前はまだ無い。';
const _line2 = 'どこで生れたかとんと見当がつかぬ。';

Future<void> _genHorizontal(pw.Font font) async {
  final doc = pw.Document();
  const format = PdfPageFormat(420, 300);
  doc.addPage(
    pw.Page(
      pageFormat: format,
      build: (context) => pw.Padding(
        padding: const pw.EdgeInsets.all(24),
        child: pw.Text(
          '$_line1\n$_line2',
          style: pw.TextStyle(font: font, fontSize: 20),
        ),
      ),
    ),
  );
  final bytes = await doc.save();
  await File('fixtures/fixture_horizontal.pdf').writeAsBytes(bytes);
}

const _pageW = 320.0;
const _pageH = 520.0;
const _fontSize = 20.0;
const _lineHeight = 28.0;
const _colWidth = 32.0;
const _marginRight = 40.0;
const _marginTop = 40.0;

/// Column order is right-to-left (columns[0] is the rightmost column and is
/// read first), matching real 縦書き layout. Page height (520) is sized with
/// headroom above the longest column (16 chars * 28pt + 40pt margin = 488pt)
/// so no character lands off-page.
final _columns = <String>[
  _line1.replaceAll('。', ''),
  _line2.replaceAll('。', ''),
];

/// (column, charIndexWithinColumn) pairs in the order each glyph should be
/// PAINTED (i.e. the order drawString() calls happen / the order the chars
/// will appear in the PDF content stream).
List<(int col, int i)> _placements(bool paintInVisualReadingOrder) {
  final byColumnInOrder = [
    for (var col = 0; col < _columns.length; col++)
      for (var i = 0; i < _columns[col].length; i++) (col, i),
  ];
  if (paintInVisualReadingOrder) return byColumnInOrder;
  // Reverse column paint order only (column 1 painted before column 0),
  // while every glyph keeps the EXACT SAME on-page (x, y) position. The
  // rendered page is visually identical either way; only the order the
  // draw calls hit the content stream differs. This isolates whether
  // pdfium's linear char/fragment sequence follows paint/content-stream
  // order or true visual (right-to-left column) reading order.
  return [
    for (var i = 0; i < _columns[1].length; i++) (1, i),
    for (var i = 0; i < _columns[0].length; i++) (0, i),
  ];
}

Future<void> _writeVerticalFixture(
  Uint8List fontBytes,
  String outPath, {
  required bool paintInVisualReadingOrder,
}) async {
  final doc = pw.Document();
  // PdfGraphics.drawString() (low-level canvas API) wants a package:pdf/pdf.dart
  // `PdfFont`, a different type from the widget-layer `pw.Font` used by
  // pw.Text -- build a PdfTtfFont from the raw font bytes, bound to this
  // document's underlying low-level PdfDocument.
  final rawFont = PdfTtfFont(doc.document, fontBytes.buffer.asByteData());
  const format = PdfPageFormat(_pageW, _pageH);

  doc.addPage(
    pw.Page(
      pageFormat: format,
      build: (context) => pw.CustomPaint(
        size: const PdfPoint(_pageW, _pageH),
        painter: (canvas, size) {
          canvas.setColor(PdfColors.black);
          for (final (col, i) in _placements(paintInVisualReadingOrder)) {
            final x = size.x - _marginRight - col * _colWidth;
            final y = size.y - _marginTop - _fontSize - i * _lineHeight;
            canvas.drawString(rawFont, _fontSize, _columns[col][i], x, y);
          }
        },
      ),
    ),
  );
  final bytes = await doc.save();
  await File(outPath).writeAsBytes(bytes);
}
