// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_rect.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SourceRect _$SourceRectFromJson(Map<String, dynamic> json) => _SourceRect(
  pageIndex: (json['pageIndex'] as num).toInt(),
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
  width: (json['width'] as num).toDouble(),
  height: (json['height'] as num).toDouble(),
  pageWidth: (json['pageWidth'] as num).toDouble(),
  pageHeight: (json['pageHeight'] as num).toDouble(),
);

Map<String, dynamic> _$SourceRectToJson(_SourceRect instance) =>
    <String, dynamic>{
      'pageIndex': instance.pageIndex,
      'x': instance.x,
      'y': instance.y,
      'width': instance.width,
      'height': instance.height,
      'pageWidth': instance.pageWidth,
      'pageHeight': instance.pageHeight,
    };
