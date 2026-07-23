import 'package:freezed_annotation/freezed_annotation.dart';

import 'token.dart';

part 'sentence.freezed.dart';
part 'sentence.g.dart';

/// `id` is a stable, position-derived identifier (see `core/ids/stable_id.dart`)
/// so Card Mode and Document Mode can sync position across mode switches, and
/// so re-imports/OCR reprocessing don't shift IDs that mining/SRS rows key off.
///
/// `tokens` is never empty. Immediately after L1 ingestion (before Sudachi
/// segmentation runs in L2), a sentence holds one or more placeholder Tokens,
/// pre-split only at boundaries L1 has independent evidence for — e.g. an
/// EPUB author-supplied `<ruby>` span, where `surface` is the base text and
/// `reading` is the furigana. Absent such evidence, L1 emits a single token
/// spanning the whole sentence. Either way, `dictForm`/`pos`/`inflection`
/// stay null until L2 runs — those are exclusively Sudachi's job. L2 replaces
/// this placeholder list with the real Sudachi segmentation, reconciling any
/// L1-supplied readings onto whichever resulting token(s) overlap that span.
///
/// (Revised after the R1 EPUB research spike found the original "always
/// exactly one placeholder" rule left author-supplied furigana with nowhere
/// to live — a sentence routinely contains more than one independent ruby
/// span, and one token's `reading` field can't hold more than one. See
/// docs/research/r1-epub.md.)
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
