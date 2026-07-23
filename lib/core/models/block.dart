import 'package:freezed_annotation/freezed_annotation.dart';

import 'sentence.dart';

part 'block.freezed.dart';
part 'block.g.dart';

enum BlockKind { paragraph, page, speechBubble, subtitleLine }

/// Horizontal (横書き) or vertical (縦書き) reading direction. Defaults to
/// [horizontal] on [Block] since most sources (EPUB, scanned-page-as-whole-
/// block content) are horizontal or don't carry direction evidence at all --
/// only the PDF text-layer importer currently has real per-page evidence to
/// set this from (`l1_ingestion/pdf_text/reading_order.dart`'s
/// `ReadingRegime`, computed geometrically per docs/research/r2-pdf-text.md
/// §3.4). Lives here rather than being imported from that importer: `core/
/// models` is the frozen, dependency-free layer every importer depends *on*,
/// never the reverse, so the shared vocabulary for "which way does this
/// block read" belongs to the model, with importers translating their own
/// internal concepts into it.
enum WritingDirection { horizontal, vertical }

@freezed
abstract class Block with _$Block {
  const factory Block({
    required String id,
    required int index,
    required BlockKind kind,
    required List<Sentence> sentences,
    @Default(WritingDirection.horizontal) WritingDirection direction,
  }) = _Block;

  factory Block.fromJson(Map<String, dynamic> json) => _$BlockFromJson(json);
}
