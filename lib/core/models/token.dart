import 'package:freezed_annotation/freezed_annotation.dart';

import 'source_rect.dart';

part 'token.freezed.dart';
part 'token.g.dart';

/// `dictForm`/`reading`/`pos`/`inflection` are null until L2 (Sudachi)
/// processes the sentence — L1 ingestion only ever populates `surface` and
/// `sourceRect`. See `Sentence` for how an unsegmented sentence is
/// represented before L2 runs.
@freezed
abstract class Token with _$Token {
  const factory Token({
    required String surface,
    String? dictForm,
    String? reading,
    String? pos,
    String? inflection,
    SourceRect? sourceRect,
  }) = _Token;

  factory Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);
}
