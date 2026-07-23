import 'package:freezed_annotation/freezed_annotation.dart';

import 'source_rect.dart';

part 'token.freezed.dart';
part 'token.g.dart';

/// `dictForm`/`pos`/`inflection` are null until L2 (Sudachi) processes the
/// sentence — those are exclusively L2's job. `reading` is usually null
/// pre-L2 too, but L1 may set it early when it has independent evidence
/// (e.g. an EPUB author-supplied `<ruby>` span) — see `Sentence` for how an
/// unsegmented sentence is represented before L2 runs, and why this can't
/// wait for L2 without losing that data.
///
/// `confidence` (0.0-1.0) is set only by scanned-PDF/OCR ingestion, null
/// otherwise (EPUB and PDF-text-layer extraction are exact). Like `reading`,
/// it's an L1-time signal on a pre-L2 token that L2 must carry forward onto
/// whichever real Sudachi token(s) end up covering that span, rather than
/// dropping it when segmentation replaces the placeholder. (Added per the
/// R3 OCR research spike — see docs/research/r3-ocr.md.)
@freezed
abstract class Token with _$Token {
  const factory Token({
    required String surface,
    String? dictForm,
    String? reading,
    String? pos,
    String? inflection,
    SourceRect? sourceRect,
    double? confidence,
  }) = _Token;

  factory Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);
}
