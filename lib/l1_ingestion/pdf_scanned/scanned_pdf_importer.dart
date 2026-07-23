import 'dart:io';

import 'package:japanese_immersion_reader/core/ids/stable_id.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/core/util/sentence_splitter.dart';
import 'package:japanese_immersion_reader/l1_ingestion/importer.dart';
import 'package:path/path.dart' as p;

import 'ocr_engine.dart';
import 'ocr_result_cache.dart';
import 'ocr_worker.dart';
import 'pdf_page_rasterizer.dart';

/// Imports a scanned (image-only) PDF by rasterizing each page and running
/// OCR over it, producing one `Block` (`kind: BlockKind.page`) per page.
///
/// **Scope note (this pass is an orchestration shell, not real OCR):** per
/// docs/research/r3-ocr.md, real OCR backend integration (Manga OCR needs a
/// hand-ported ONNX autoregressive decode loop; neither Manga OCR nor
/// Tesseract's background-isolate safety is verified on real hardware) is
/// heavy enough that it's explicitly deferred to a later phase. This
/// importer takes an [OcrEngine] purely as a constructor-injected
/// dependency -- a real implementation can swap in later without touching
/// this class -- and is exercised in tests entirely against a fake engine.
///
/// **Region detection is stubbed.** Spec §4 calls for "page → text-region
/// detection → OCR per region"; full text-region detection is out of scope
/// for this pass, so every page is treated as a single whole-page region.
/// [OcrEngine.recognize] and [OcrRegionResult] already support several
/// regions per page (see their doc comments), so adding real region
/// detection later only changes what feeds this importer's per-page loop,
/// not the interfaces around it.
///
/// **Orientation is also not auto-detected.** [assumeVertical] is passed to
/// the engine for every page/region as-is; real per-region orientation
/// detection (needed because Tesseract can't reliably infer it -- see
/// r3-ocr.md §2.2) should reuse whatever gets built for the PDF-text-layer
/// importer's vertical-reading-order reconstruction (spec §4), not
/// duplicate it here.
///
/// **Background isolate.** All of one import's OCR calls run inside a
/// single long-lived worker isolate ([OcrWorker]), spawned once per [import]
/// call and holding one constructed [OcrEngine] instance for every page --
/// see that class's own doc comment for why (in short: an earlier version of
/// this importer used `Isolate.run` per page, which spawns a *fresh* isolate
/// and sends a *copy* of the engine each time; harmless for a stateless
/// fake, but wrong for a real engine wrapping loaded ONNX Runtime sessions,
/// which shouldn't be reloaded every single page). A slow or hung
/// recognition call still never blocks the isolate driving [import]'s
/// `onProgress` callback (see docs/research/r3-ocr.md finding 3, whose
/// standalone spike at research/r3_ocr/isolate_progress_demo.dart validated
/// the underlying spawn/report/recover mechanics this leans on) -- that
/// property doesn't depend on whether the worker is short- or long-lived.
///
/// **Per-page resilience.** A page that fails to rasterize or OCR does not
/// abort the whole import (mirroring the spike's per-chapter recovery) --
/// it's recorded as an empty-region page instead, so one bad scan doesn't
/// take down an entire multi-hundred-page document.
///
/// **Disk cache.** Results are cached per source file (see
/// [OcrResultCache]) so re-opening the same, unchanged document skips both
/// OCR and rasterization entirely -- and, since the cache hit path never
/// spawns [OcrWorker] at all, skips paying for engine construction (a real
/// engine's ONNX session loading) too.
class ScannedPdfImporter implements Importer {
  ScannedPdfImporter(
    this.ocrEngineFactory, {
    this.rasterizer = const PdfrxPageRasterizer(),
    Directory? cacheDirectory,
    this.assumeVertical = false,
  }) : cache = OcrResultCache(directoryOverride: cacheDirectory);

  /// Constructs the [OcrEngine] to use for this import -- called once,
  /// inside [OcrWorker]'s worker isolate, not on the calling isolate. See
  /// [OcrWorker]'s own doc comment for why this is a factory rather than a
  /// ready instance, and prefer a bare constructor tear-off (e.g.
  /// `MyEngine.new`) or a closure that captures no mutable state when
  /// supplying one, since that's what's actually been verified to cross the
  /// isolate boundary cleanly (`ocr_worker_test.dart`).
  final OcrEngineFactory ocrEngineFactory;
  final PdfPageRasterizer rasterizer;
  final OcrResultCache cache;

  /// Passed as [OcrEngine.recognize]'s `vertical` argument for every page,
  /// since this pass has no per-region orientation detection (see class
  /// doc comment). Defaults to horizontal, matching the
  /// `synthetic_horizontal_ja.pdf` fixture.
  final bool assumeVertical;

  /// Fraction reserved for the OCR phase; the remainder covers `indexing`
  /// (building the `Document` from cached/fresh OCR output) and `done`.
  static const _ocrPhaseEnd = 0.9;
  static const _indexingFraction = 0.95;

  @override
  Future<Document> import(
    File file, {
    required void Function(ImportProgress progress) onProgress,
  }) async {
    onProgress(const ImportProgress(fraction: 0.0, stage: ImportStage.parsing));

    final documentId = await _documentIdFor(file);

    var pages = await cache.read(file);
    if (pages == null) {
      pages = await _ocrAllPages(file, onProgress);
      await cache.write(file, pages);
    } else {
      // Cache hit: still report per-page progress so callers see the same
      // shape of progress sequence regardless of whether OCR actually ran,
      // even though no rasterization or recognition happens on this path.
      for (var i = 0; i < pages.length; i++) {
        _reportPageProgress(i, pages.length, onProgress);
      }
    }

    onProgress(
      const ImportProgress(
        fraction: _indexingFraction,
        stage: ImportStage.indexing,
      ),
    );
    final document = _buildDocument(
      documentId: documentId,
      title: p.basenameWithoutExtension(file.path),
      pages: pages,
    );
    onProgress(const ImportProgress(fraction: 1.0, stage: ImportStage.done));
    return document;
  }

  Future<List<PageOcrResult>> _ocrAllPages(
    File file,
    void Function(ImportProgress progress) onProgress,
  ) async {
    final session = await rasterizer.open(file);
    // One worker for the whole import (all pages share the one constructed
    // engine instance) -- see [OcrWorker]'s and this class's own doc
    // comments for why that matters for a real engine.
    final worker = await OcrWorker.spawn(ocrEngineFactory);
    try {
      final pageCount = session.pageCount;
      final results = <PageOcrResult>[];
      for (var i = 0; i < pageCount; i++) {
        results.add(await _ocrOnePage(session, worker, i));
        _reportPageProgress(i, pageCount, onProgress);
      }
      return results;
    } finally {
      worker.dispose();
      await session.close();
    }
  }

  Future<PageOcrResult> _ocrOnePage(
    PdfPageRasterizerSession session,
    OcrWorker worker,
    int pageIndex,
  ) async {
    try {
      final page = await session.renderPage(pageIndex);
      if (page == null) {
        return const PageOcrResult(pageWidth: 0, pageHeight: 0, regions: []);
      }
      final regions = await worker.recognize(
        page.pixels,
        width: page.width,
        height: page.height,
        vertical: assumeVertical,
      );
      return PageOcrResult(
        pageWidth: page.width.toDouble(),
        pageHeight: page.height.toDouble(),
        regions: regions,
      );
    } catch (_) {
      // A single bad page must not abort the whole document -- see class
      // doc comment and docs/research/r3-ocr.md §1.4/§3.
      return const PageOcrResult(pageWidth: 0, pageHeight: 0, regions: []);
    }
  }

  void _reportPageProgress(
    int pageIndex,
    int totalPages,
    void Function(ImportProgress progress) onProgress,
  ) {
    final fraction = totalPages == 0
        ? _ocrPhaseEnd
        : _ocrPhaseEnd * (pageIndex + 1) / totalPages;
    onProgress(
      ImportProgress(
        fraction: fraction,
        stage: ImportStage.ocr,
        // Exactly one Chapter exists for the whole document (see
        // `_buildDocument` -- scanned-PDF chapter/TOC detection is as out
        // of scope as region detection), so this never varies; per-page
        // granularity is carried by `fraction` instead.
        currentChapterIndex: 0,
      ),
    );
  }

  Document _buildDocument({
    required String documentId,
    required String title,
    required List<PageOcrResult> pages,
  }) {
    final blocks = <Block>[];
    for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final page = pages[pageIndex];
      final sentences = <Sentence>[];
      var sentenceIndex = 0;
      for (final region in page.regions) {
        final spans = splitIntoSentenceSpans(region.text);
        for (final span in spans) {
          final surface = region.text.substring(span.start, span.end);
          sentences.add(
            Sentence(
              id: stableNodeId(documentId, [0, pageIndex, sentenceIndex]),
              index: sentenceIndex,
              tokens: [
                Token(
                  surface: surface,
                  confidence: region.confidence,
                  sourceRect: SourceRect(
                    pageIndex: pageIndex,
                    x: region.x,
                    y: region.y,
                    width: region.width,
                    height: region.height,
                    pageWidth: page.pageWidth,
                    pageHeight: page.pageHeight,
                  ),
                ),
              ],
            ),
          );
          sentenceIndex++;
        }
      }
      blocks.add(
        Block(
          id: stableNodeId(documentId, [0, pageIndex]),
          index: pageIndex,
          kind: BlockKind.page,
          sentences: sentences,
          direction: assumeVertical
              ? WritingDirection.vertical
              : WritingDirection.horizontal,
        ),
      );
    }

    final chapter = Chapter(
      id: stableNodeId(documentId, [0]),
      index: 0,
      blocks: blocks,
    );

    return Document(
      id: documentId,
      title: title,
      sourceType: DocumentSourceType.pdfScanned,
      chapters: [chapter],
    );
  }
}

/// Content-derived via `contentDerivedDocumentId`, hashing the source PDF's
/// own bytes -- not OCR's recognized text, and not the file path. Hashing
/// the source bytes (rather than the path) means the same scan re-imported
/// from a different location resolves to the same `Document`; hashing the
/// source bytes (rather than OCR's output) means every
/// Chapter/Block/Sentence ID derived from this stays stable across
/// re-imports even if re-running OCR recognizes some token's text slightly
/// differently, since the underlying scan hasn't changed. Every importer
/// must use `contentDerivedDocumentId` rather than inventing its own scheme,
/// so `Document.id` derivation stays consistent across sources.
///
/// The OCR disk cache ([OcrResultCache]) intentionally uses a *different*
/// key (source file size + modified time) for its own, unrelated purpose of
/// invalidating stale cached OCR output when the source file itself changes.
Future<String> _documentIdFor(File file) async =>
    contentDerivedDocumentId('pdfScanned', await file.readAsBytes());
