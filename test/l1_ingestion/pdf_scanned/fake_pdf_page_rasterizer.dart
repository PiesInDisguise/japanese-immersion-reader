import 'dart:io';
import 'dart:typed_data';

import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/pdf_page_rasterizer.dart';

/// Synthetic [PdfPageRasterizer] test double: manufactures [pageCount]
/// pages of [width]x[height] filled with meaningless zero bytes, without
/// touching the file passed to [open] at all.
///
/// This lets orchestration tests (progress sequencing, disk-cache behavior,
/// confidence flow-through) exercise many pages fast and deterministically
/// without needing several multi-page real PDF fixtures on disk --
/// `FakeOcrEngine` never looks at pixel content (see its own doc comment),
/// so real rasterized pixels wouldn't buy these tests anything.
/// `scanned_pdf_importer_real_fixture_test.dart` separately proves the
/// real, `pdfrx_engine`-backed [PdfrxPageRasterizer] against an actual
/// fixture.
class FakePdfPageRasterizer implements PdfPageRasterizer {
  FakePdfPageRasterizer({
    required this.pageCount,
    this.width = 100,
    this.height = 200,
    this.failPageIndices = const {},
  });

  final int pageCount;
  final int width;
  final int height;

  /// Page indices for which [PdfPageRasterizerSession.renderPage] returns
  /// `null`, simulating a page that failed to render -- exercises
  /// `ScannedPdfImporter`'s per-page resilience path.
  final Set<int> failPageIndices;

  /// Number of times [open] has been called, so tests can confirm the
  /// cache-hit path skips rasterization entirely (never opens the PDF).
  int openCount = 0;

  @override
  Future<PdfPageRasterizerSession> open(File file) async {
    openCount++;
    return _FakePdfPageRasterizerSession(this);
  }
}

class _FakePdfPageRasterizerSession implements PdfPageRasterizerSession {
  _FakePdfPageRasterizerSession(this._owner);

  final FakePdfPageRasterizer _owner;
  bool closed = false;

  @override
  int get pageCount => _owner.pageCount;

  @override
  Future<RasterizedPage?> renderPage(int pageIndex) async {
    if (_owner.failPageIndices.contains(pageIndex)) return null;
    return RasterizedPage(
      pixels: Uint8List(_owner.width * _owner.height * 4),
      width: _owner.width,
      height: _owner.height,
    );
  }

  @override
  Future<void> close() async {
    closed = true;
  }
}
