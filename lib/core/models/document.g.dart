// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Document _$DocumentFromJson(Map<String, dynamic> json) => _Document(
  id: json['id'] as String,
  title: json['title'] as String,
  sourceType: $enumDecode(_$DocumentSourceTypeEnumMap, json['sourceType']),
  chapters: (json['chapters'] as List<dynamic>)
      .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DocumentToJson(_Document instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'sourceType': _$DocumentSourceTypeEnumMap[instance.sourceType]!,
  'chapters': instance.chapters.map((e) => e.toJson()).toList(),
};

const _$DocumentSourceTypeEnumMap = {
  DocumentSourceType.epub: 'epub',
  DocumentSourceType.pdfText: 'pdfText',
  DocumentSourceType.pdfScanned: 'pdfScanned',
};
