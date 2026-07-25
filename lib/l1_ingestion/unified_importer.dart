import 'dart:io';

import 'package:pdfrx_engine/pdfrx_engine.dart';

import '../core/models/models.dart';
import 'epub/epub_importer.dart';
import 'importer.dart';
import 'pdf_kind_detector.dart';
import 'pdf_scanned/ocr_worker.dart';
import 'pdf_scanned/real_ocr_engine.dart';
import 'pdf_scanned/scanned_pdf_importer.dart';
import 'pdf_text/pdf_text_importer.dart';

/// The single entry point every "import a book" button (sideload and remote
/// alike) should call: picks the right [Importer] by file extension, and
/// for `.pdf` additionally by [detectPdfKind], so the caller never has to
/// know or ask which of the three underlying importers a given file needs.
///
/// The PDF branch opens the file once via `PdfDocument.openFile` to run
/// [detectPdfKind], then either hands that same handle to [PdfTextImporter]
/// (via its `preOpened` parameter, avoiding a second full file open/parse)
/// or, for a scanned PDF, disposes the detection handle -- cheap, since only
/// a handful of sampled pages were parsed -- before handing off to
/// [ScannedPdfImporter], which rasterizes pages itself and never touches the
/// text layer.
Future<Document> importAnyFile(
  File file, {
  required void Function(ImportProgress progress) onProgress,
  OcrEngineFactory ocrEngineFactory = RealOcrEngine.create,
  Directory? ocrCacheDirectory,
}) async {
  final extension = _extensionOf(file.path);
  return switch (extension) {
    '.epub' => EpubImporter().import(file, onProgress: onProgress),
    '.pdf' => _importPdf(file, onProgress, ocrEngineFactory, ocrCacheDirectory),
    _ => throw StateError('Unsupported file type: $extension'),
  };
}

Future<Document> _importPdf(
  File file,
  void Function(ImportProgress progress) onProgress,
  OcrEngineFactory ocrEngineFactory,
  Directory? ocrCacheDirectory,
) async {
  await pdfrxInitialize();
  final pdfDocument = await PdfDocument.openFile(file.path);
  final kind = await detectPdfKind(pdfDocument);

  if (kind == PdfKind.text) {
    return const PdfTextImporter().import(
      file,
      onProgress: onProgress,
      preOpened: pdfDocument,
    );
  }

  await pdfDocument.dispose();
  return ScannedPdfImporter(
    ocrEngineFactory,
    cacheDirectory: ocrCacheDirectory,
  ).import(file, onProgress: onProgress);
}

String _extensionOf(String path) {
  final dot = path.lastIndexOf('.');
  return dot == -1 ? '' : path.substring(dot).toLowerCase();
}
