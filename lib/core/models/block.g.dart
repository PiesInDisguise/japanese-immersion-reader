// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Block _$BlockFromJson(Map<String, dynamic> json) => _Block(
  id: json['id'] as String,
  index: (json['index'] as num).toInt(),
  kind: $enumDecode(_$BlockKindEnumMap, json['kind']),
  sentences: (json['sentences'] as List<dynamic>)
      .map((e) => Sentence.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BlockToJson(_Block instance) => <String, dynamic>{
  'id': instance.id,
  'index': instance.index,
  'kind': _$BlockKindEnumMap[instance.kind]!,
  'sentences': instance.sentences.map((e) => e.toJson()).toList(),
};

const _$BlockKindEnumMap = {
  BlockKind.paragraph: 'paragraph',
  BlockKind.page: 'page',
  BlockKind.speechBubble: 'speechBubble',
  BlockKind.subtitleLine: 'subtitleLine',
};
