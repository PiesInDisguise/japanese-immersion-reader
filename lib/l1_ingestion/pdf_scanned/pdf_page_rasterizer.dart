import 'dart:io';
import 'dart:typed_data';

import 'package:pdfrx_engine/pdfrx_engine.dart';

/// One rasterized page: raw BGRA8888 pixels plus the dimensions needed to
/// interpret them and to populate `SourceRect.pageWidth`/`pageHeight`.
class RasterizedPage {
  const RasterizedPage({
    required this.pixels,
    required this.width,
    required this.height,
  });

  /// Raw BGRA8888 pixel data, `width * height * 4` bytes.
  final Uint8List pixels;
  final int width;
  final int height;
}

/// An open handle on one PDF document's pages, ready to rasterize any of
/// them by index. Must be [close]d when done.
abstract class PdfPageRasterizerSession {
  /// Total number of pages in the document.
  int get pageCount;

  /// Renders [pageIndex] (0-based) to a raster image, or `null` if the page
  /// could not be rendered (e.g. not yet loaded -- see `PdfPage.render`'s
  /// own doc comment; not expected in this importer's non-progressive-load
  /// usage, but handled rather than assumed away).
  Future<RasterizedPage?> renderPage(int pageIndex);

  Future<void> close();
}

/// Rasterizes PDF pages into raw images for OCR.
///
/// [ScannedPdfImporter] defaults to [PdfrxPageRasterizer], which renders via
/// `pdfrx_engine` as required for production use. Tests may inject a
/// synthetic implementation instead so orchestration tests (progress
/// sequencing, disk-cache behavior, confidence flow-through) can exercise
/// many pages fast and deterministically without needing several
/// multi-page real PDF fixtures on disk -- `FakeOcrEngine` never looks at
/// pixel content anyway (see its doc comment), so real rasterized pixels
/// buy nothing in those tests. A separate test exercises [PdfrxPageRasterizer]
/// itself against a real fixture to prove the production wiring works.
abstract class PdfPageRasterizer {
  /// Opens [file] for page-by-page rendering. The caller must
  /// [PdfPageRasterizerSession.close] the returned session when done.
  Future<PdfPageRasterizerSession> open(File file);
}

/// Default, production [PdfPageRasterizer], backed by `pdfrx_engine`'s
/// PDFium bindings.
///
/// Opens the document once per [open] call and renders pages one at a time
/// on demand (rather than rasterizing every page up front) so a large
/// scanned novel doesn't hold every page's raw pixel buffer in memory
/// simultaneously -- at BGRA8888, a few hundred pages of a decent-resolution
/// scan would otherwise add up to gigabytes.
class PdfrxPageRasterizer implements PdfPageRasterizer {
  const PdfrxPageRasterizer();

  @override
  Future<PdfPageRasterizerSession> open(File file) async {
    // Dart-only init path (this project depends on `pdfrx_engine` directly,
    // not the Flutter-widget `pdfrx` package, so `pdfrxFlutterInitialize`
    // isn't available -- this is the documented alternative for that case).
    // Idempotent: safe to call before every open.
    await pdfrxInitialize();
    final document = await PdfDocument.openFile(file.path);
    return _PdfrxPageRasterizerSession(document);
  }
}

class _PdfrxPageRasterizerSession implements PdfPageRasterizerSession {
  _PdfrxPageRasterizerSession(this._document);

  final PdfDocument _document;

  @override
  int get pageCount => _document.pages.length;

  @override
  Future<RasterizedPage?> renderPage(int pageIndex) async {
    final image = await _document.pages[pageIndex].render();
    if (image == null) return null;
    try {
      // Defensive copy: `image.pixels` may be a view over natively-owned
      // memory that becomes invalid once `image.dispose()` runs below.
      // `Uint8List.fromList` guarantees a plain Dart-heap copy, which is
      // also what an `Isolate.run` message-send would produce anyway --
      // making it explicit here means the safety doesn't depend on exactly
      // how/when the caller disposes relative to sending it across an
      // isolate boundary.
      return RasterizedPage(
        pixels: Uint8List.fromList(image.pixels),
        width: image.width,
        height: image.height,
      );
    } finally {
      image.dispose();
    }
  }

  @override
  Future<void> close() => _document.dispose();
}
