import 'package:freezed_annotation/freezed_annotation.dart';

part 'source_rect.freezed.dart';
part 'source_rect.g.dart';

/// A tap-target region on a rendered page. `x`/`y`/`width`/`height` share a
/// unit with `pageWidth`/`pageHeight` (PDF points for text-layer PDFs, raster
/// pixels for OCR) so consumers normalize to a fraction via division instead
/// of needing a separate coordinate-space enum. `null` on the owning
/// Token/Block for reflowable EPUB, where there is no fixed page geometry.
///
/// Origin is always top-left with y growing downward, matching both OCR's
/// natural output and Flutter's own Rect/Offset/Canvas convention — the same
/// regardless of source. PDFium (and therefore pdfrx) reports bottom-left/
/// y-up, so the PDF-text importer must flip (`y = pageHeight - rawTop`)
/// before constructing a SourceRect; it must never store PDFium's raw y
/// un-flipped. Getting this backwards only shows up as vertically-flipped
/// tap targets during manual QA, not a test failure, so this is called out
/// explicitly rather than left for each importer to assume one way or the
/// other. (Flagged by the R2 PDF research spike, which found this convention
/// undocumented — see docs/research/r2-pdf-text.md §2.)
@freezed
abstract class SourceRect with _$SourceRect {
  const factory SourceRect({
    required int pageIndex,
    required double x,
    required double y,
    required double width,
    required double height,
    required double pageWidth,
    required double pageHeight,
  }) = _SourceRect;

  factory SourceRect.fromJson(Map<String, dynamic> json) =>
      _$SourceRectFromJson(json);
}
