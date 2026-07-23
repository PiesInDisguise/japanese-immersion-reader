import 'package:freezed_annotation/freezed_annotation.dart';

import 'sentence.dart';

part 'block.freezed.dart';
part 'block.g.dart';

enum BlockKind { paragraph, page, speechBubble, subtitleLine }

@freezed
abstract class Block with _$Block {
  const factory Block({
    required String id,
    required int index,
    required BlockKind kind,
    required List<Sentence> sentences,
  }) = _Block;

  factory Block.fromJson(Map<String, dynamic> json) => _$BlockFromJson(json);
}
