// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Token _$TokenFromJson(Map<String, dynamic> json) => _Token(
  surface: json['surface'] as String,
  dictForm: json['dictForm'] as String?,
  reading: json['reading'] as String?,
  pos: json['pos'] as String?,
  inflection: json['inflection'] as String?,
  sourceRect: json['sourceRect'] == null
      ? null
      : SourceRect.fromJson(json['sourceRect'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TokenToJson(_Token instance) => <String, dynamic>{
  'surface': instance.surface,
  'dictForm': instance.dictForm,
  'reading': instance.reading,
  'pos': instance.pos,
  'inflection': instance.inflection,
  'sourceRect': instance.sourceRect?.toJson(),
};
