// THROWAWAY research script (r2_pdf_text spike). Loads a PDF via
// pdfrx_engine and dumps full text, per-character bounding boxes, and
// per-fragment text-direction data, so we can inspect whether it's usable
// to populate the frozen SourceRect contract and to detect/reconstruct
// vertical (縦書き) reading order. See docs/research/r2-pdf-text.md.
import 'dart:io';

import 'package:pdfrx_engine/pdfrx_engine.dart';
// PdfTextFormatter.loadStructuredText() (the entry point that returns
// fragments+direction, not just flat charRects) is NOT re-exported from the
// public pdfrx_engine.dart barrel file -- it has to be reached via this
// internal src/ import. That itself is a finding worth flagging: as of
// pdfrx_engine 0.4.6 the fragment/direction API is only reachable through an
// unstable-by-convention import path.
import 'package:pdfrx_engine/src/pdf_text_formatter.dart';

Future<void> main(List<String> args) async {
  final path = args.isNotEmpty ? args[0] : 'fixtures/fixture_horizontal.pdf';

  await pdfrxInitialize();
  final document = await PdfDocument.openFile(path);

  stdout.writeln('=== $path ===');
  stdout.writeln('pageCount: ${document.pages.length}');

  for (var pageIndex = 0; pageIndex < document.pages.length; pageIndex++) {
    final page = document.pages[pageIndex];
    stdout.writeln(
      '--- page $pageIndex: ${page.width.toStringAsFixed(2)} x '
      '${page.height.toStringAsFixed(2)} pt ---',
    );

    // page.loadText() only returns the flat PdfPageRawText (fullText +
    // charRects, no fragments/direction). The fragment/direction grouping
    // logic lives in PdfTextFormatter.loadStructuredText(), which is the
    // actual public entry point for PdfPageText.
    final text = await PdfTextFormatter.loadStructuredText(
      page,
      pageNumberOverride: pageIndex + 1,
    );

    stdout.writeln(
      'fullText (${text.fullText.length} chars): '
      '${text.fullText.replaceAll('\n', '\\n')}',
    );
    stdout.writeln('charRects.length: ${text.charRects.length}');

    final n = text.charRects.length < 20 ? text.charRects.length : 20;
    for (var i = 0; i < n; i++) {
      final r = text.charRects[i];
      final ch = text.fullText.substring(i, i + 1).replaceAll('\n', '\\n');
      stdout.writeln(
        '  [$i] "$ch" '
        'l=${r.left.toStringAsFixed(2)} '
        't=${r.top.toStringAsFixed(2)} '
        'r=${r.right.toStringAsFixed(2)} '
        'b=${r.bottom.toStringAsFixed(2)} '
        'w=${r.width.toStringAsFixed(2)} '
        'h=${r.height.toStringAsFixed(2)}',
      );
    }

    stdout.writeln('fragments: ${text.fragments.length}');
    for (final f in text.fragments) {
      stdout.writeln(
        '  frag idx=${f.index} len=${f.length} end=${f.end} '
        'dir=${f.direction} '
        'bounds=(l=${f.bounds.left.toStringAsFixed(2)},'
        't=${f.bounds.top.toStringAsFixed(2)},'
        'r=${f.bounds.right.toStringAsFixed(2)},'
        'b=${f.bounds.bottom.toStringAsFixed(2)}) '
        'text="${f.text.replaceAll('\n', '\\n')}"',
      );
    }

    // Sanity check for the frozen SourceRect contract: can we normalize the
    // first char's rect to a [0,1] fraction using (pageWidth, pageHeight) in
    // the SAME unit, the way SourceRect's doc comment says consumers should?
    if (text.charRects.isNotEmpty) {
      final r = text.charRects.first;
      stdout.writeln(
        'normalized-fraction check (char 0): '
        'x/pageWidth=${(r.left / page.width).toStringAsFixed(4)} '
        'y/pageHeight=${(r.top / page.height).toStringAsFixed(4)} '
        '(page.width/height are in the same "points" unit as charRects, '
        'confirming the shared-unit assumption SourceRect relies on)',
      );
    }
  }

  stdout.writeln();
}
