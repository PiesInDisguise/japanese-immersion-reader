import 'package:freezed_annotation/freezed_annotation.dart';

part 'source_rect.freezed.dart';
part 'source_rect.g.dart';

/// A tap-target region on a rendered page. `x`/`y`/`width`/`height` share a
/// unit with `pageWidth`/`pageHeight` (PDF points for text-layer PDFs, raster
/// pixels for OCR) so consumers normalize to a fraction via division instead
/// of needing a separate coordinate-space enum. `null` on the owning
/// Token/Block for reflowable EPUB, where there is no fixed page geometry.
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
