// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sentence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Sentence _$SentenceFromJson(Map<String, dynamic> json) => _Sentence(
  id: json['id'] as String,
  index: (json['index'] as num).toInt(),
  tokens: (json['tokens'] as List<dynamic>)
      .map((e) => Token.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SentenceToJson(_Sentence instance) => <String, dynamic>{
  'id': instance.id,
  'index': instance.index,
  'tokens': instance.tokens.map((e) => e.toJson()).toList(),
};
