// THROWAWAY one-off script. Generates a synthetic "scanned" PDF fixture --
// a page with drawn graphics but NO text-layer content at all -- for
// `test/l1_ingestion/pdf_kind_detector_test.dart` to verify `detectPdfKind`
// correctly classifies an image-only page as PdfKind.scanned. A real scanned
// PDF would have image XObjects instead of vector shapes, but pdfrx's text
// extraction only cares that there's no text layer to find, so a shape-only
// page is a faithful, much simpler stand-in. Run once via `dart run
// bin/gen_scanned_fixture.dart`, then the output is copied by hand into
// ../../assets/fixtures/ -- not part of the main app or its build.
import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> main() async {
  final doc = pw.Document();
  const format = PdfPageFormat(420, 300);
  doc.addPage(
    pw.Page(
      pageFormat: format,
      build: (context) => pw.Center(
        child: pw.Container(
          width: 200,
          height: 150,
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        ),
      ),
    ),
  );
  final bytes = await doc.save();
  Directory('fixtures').createSync(recursive: true);
  await File('fixtures/synthetic_scanned_blank.pdf').writeAsBytes(bytes);
  stdout.writeln('Wrote fixtures/synthetic_scanned_blank.pdf');
}
