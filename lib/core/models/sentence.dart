import 'package:freezed_annotation/freezed_annotation.dart';

import 'token.dart';

part 'sentence.freezed.dart';
part 'sentence.g.dart';

/// `id` is a stable, position-derived identifier (see `core/ids/stable_id.dart`)
/// so Card Mode and Document Mode can sync position across mode switches, and
/// so re-imports/OCR reprocessing don't shift IDs that mining/SRS rows key off.
///
/// `tokens` is never empty. Immediately after L1 ingestion (before Sudachi
/// segmentation runs in L2), a sentence holds exactly one placeholder Token
/// spanning its full text with null linguistic fields — L2 replaces that
/// placeholder with the real multi-token Sudachi output. This keeps the type
/// shape identical before and after L2, so nothing downstream needs to know
/// whether tokenization has happened yet.
@freezed
abstract class Sentence with _$Sentence {
  const Sentence._();

  const factory Sentence({
    required String id,
    required int index,
    required List<Token> tokens,
  }) = _Sentence;

  factory Sentence.fromJson(Map<String, dynamic> json) =>
      _$SentenceFromJson(json);

  String get surfaceText => tokens.map((t) => t.surface).join();
}
