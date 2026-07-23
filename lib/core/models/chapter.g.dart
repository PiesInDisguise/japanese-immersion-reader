// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Chapter _$ChapterFromJson(Map<String, dynamic> json) => _Chapter(
  id: json['id'] as String,
  index: (json['index'] as num).toInt(),
  title: json['title'] as String?,
  blocks: (json['blocks'] as List<dynamic>)
      .map((e) => Block.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ChapterToJson(_Chapter instance) => <String, dynamic>{
  'id': instance.id,
  'index': instance.index,
  'title': instance.title,
  'blocks': instance.blocks.map((e) => e.toJson()).toList(),
};
