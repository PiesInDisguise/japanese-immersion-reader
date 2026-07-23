import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pdfrx_engine/pdfrx_engine.dart';

import '../../core/ids/stable_id.dart';
import '../../core/models/models.dart';
import '../../core/util/sentence_splitter.dart';
import '../importer.dart';
import 'reading_order.dart';

/// Imports a text-layer PDF (spec §4) into the normalized `Document` model.
///
/// Scope for this pass: PDFs don't expose TOC/chapter metadata at the text
/// layer the way EPUB's OPF/NCX does, so the whole document becomes a single
/// `Chapter`, with one `Block` (`BlockKind.page`) per page. Real chapter
/// detection (e.g. from bookmarks/outline or heading heuristics) is left for
/// a later pass rather than over-building it here.
///
/// Reading order within a page is reconstructed geometrically, not trusted
/// from extraction order -- see `reading_order.dart` and
/// docs/research/r2-pdf-text.md §3.4 for why that matters for vertical
/// (縦書き) text. Every sentence's single token gets a `sourceRect` that is
/// the aggregate bounding box of every character in that sentence (per
/// `lib/core/models/sentence.dart`'s doc comment: PDF text has no ruby-like
/// evidence to pre-split on, so each sentence is exactly one token), flipped
/// from PDFium's bottom-left/y-up coordinates to the frozen top-left/y-down
/// `SourceRect` convention (`lib/core/models/source_rect.dart`).
class PdfTextImporter implements Importer {
  const PdfTextImporter();

  @override
  Future<Document> import(
    File file, {
    required void Function(ImportProgress progress) onProgress,
  }) async {
    await pdfrxInitialize();
    final pdfDocument = await PdfDocument.openFile(file.path);
    try {
      final documentId = await _documentIdFor(file);
      final pageCount = pdfDocument.pages.length;
      final blocks = <Block>[];

      for (var pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        final page = pdfDocument.pages[pageIndex];
        final pageText = await page.loadStructuredText();
        blocks.add(
          _buildPageBlock(
            documentId: documentId,
            pageIndex: pageIndex,
            page: page,
            pageText: pageText,
          ),
        );
        onProgress(
          ImportProgress(
            fraction: (pageIndex + 1) / pageCount,
            stage: ImportStage.parsing,
            currentChapterIndex: 0,
          ),
        );
      }

      final chapter = Chapter(
        id: stableNodeId(documentId, const [0]),
        index: 0,
        blocks: blocks,
      );

      onProgress(
        const ImportProgress(
          fraction: 1,
          stage: ImportStage.done,
          currentChapterIndex: 0,
        ),
      );

      return Document(
        id: documentId,
        title: p.basenameWithoutExtension(file.path),
        sourceType: DocumentSourceType.pdfText,
        chapters: [chapter],
      );
    } finally {
      await pdfDocument.dispose();
    }
  }

  Block _buildPageBlock({
    required String documentId,
    required int pageIndex,
    required PdfPage page,
    required PdfPageText pageText,
  }) {
    final orderedChars = reconstructReadingOrder(pageText);
    final pageReadingOrderText = orderedChars.map((c) => c.char).join();
    final spans = splitIntoSentenceSpans(pageReadingOrderText);

    final sentences = <Sentence>[
      for (var sentenceIndex = 0; sentenceIndex < spans.length; sentenceIndex++)
        _buildSentence(
          documentId: documentId,
          pageIndex: pageIndex,
          sentenceIndex: sentenceIndex,
          span: spans[sentenceIndex],
          orderedChars: orderedChars,
          page: page,
        ),
    ];

    return Block(
      id: stableNodeId(documentId, [0, pageIndex]),
      index: pageIndex,
      kind: BlockKind.page,
      sentences: sentences,
    );
  }

  Sentence _buildSentence({
    required String documentId,
    required int pageIndex,
    required int sentenceIndex,
    required SentenceSpan span,
    required List<PositionedChar> orderedChars,
    required PdfPage page,
  }) {
    final spanChars = orderedChars.sublist(span.start, span.end);
    final surface = spanChars.map((c) => c.char).join();
    final sourceRect = _aggregateSourceRect(
      pageIndex: pageIndex,
      rects: spanChars.map((c) => c.rect),
      pageWidth: page.width,
      pageHeight: page.height,
    );

    return Sentence(
      id: stableNodeId(documentId, [0, pageIndex, sentenceIndex]),
      index: sentenceIndex,
      tokens: [Token(surface: surface, sourceRect: sourceRect)],
    );
  }

  /// Unions raw PDF-space (bottom-left origin, y-up) character rects, then
  /// flips ONCE to the frozen top-left/y-down `SourceRect` convention --
  /// `y = pageHeight - unionTop`, `height` unchanged. Must never store
  /// PDFium's raw top/bottom un-flipped (see `source_rect.dart`'s doc
  /// comment); getting this backwards only shows up as vertically-flipped
  /// tap targets during manual QA, not a test failure.
  SourceRect _aggregateSourceRect({
    required int pageIndex,
    required Iterable<PdfRect> rects,
    required double pageWidth,
    required double pageHeight,
  }) {
    final union = rects.reduce((a, b) => a.merge(b));
    return SourceRect(
      pageIndex: pageIndex,
      x: union.left,
      y: pageHeight - union.top,
      width: union.width,
      height: union.height,
      pageWidth: pageWidth,
      pageHeight: pageHeight,
    );
  }

  /// Content-derived via `contentDerivedDocumentId`, not path-derived: the
  /// same PDF re-imported from a different location must resolve to the
  /// same `Document` rather than a duplicate. See that function's doc
  /// comment; every importer must use it rather than inventing its own
  /// scheme, so `Document.id` derivation stays consistent across sources.
  Future<String> _documentIdFor(File file) async =>
      contentDerivedDocumentId('pdfText', await file.readAsBytes());
}
