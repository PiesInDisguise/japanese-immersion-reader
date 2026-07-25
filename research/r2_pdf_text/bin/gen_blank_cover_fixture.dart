// THROWAWAY one-off script. Generates a 2-page fixture: page 0 is a blank
// (image-only, no text layer) "cover," page 1 has real Japanese text --
// for `test/l1_ingestion/pdf_kind_detector_test.dart` to verify
// `detectPdfKind` samples pages evenly across the whole document rather
// than just the first N, so a blank cover page in an otherwise real
// text-layer book doesn't misclassify the document as scanned.
import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> main() async {
  final fontBytes = File(r'C:\Windows\Fonts\yumin.ttf').readAsBytesSync();
  final font = pw.Font.ttf(fontBytes.buffer.asByteData());

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
  doc.addPage(
    pw.Page(
      pageFormat: format,
      build: (context) => pw.Padding(
        padding: const pw.EdgeInsets.all(24),
        child: pw.Text(
          '吾輩は猫である。名前はまだ無い。\nどこで生れたかとんと見当がつかぬ。',
          style: pw.TextStyle(font: font, fontSize: 20),
        ),
      ),
    ),
  );

  final bytes = await doc.save();
  Directory('fixtures').createSync(recursive: true);
  await File('fixtures/synthetic_blank_cover_ja.pdf').writeAsBytes(bytes);
  stdout.writeln('Wrote fixtures/synthetic_blank_cover_ja.pdf');
}
