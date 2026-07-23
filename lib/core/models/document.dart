import 'package:freezed_annotation/freezed_annotation.dart';

import 'chapter.dart';

part 'document.freezed.dart';
part 'document.g.dart';

enum DocumentSourceType { epub, pdfText, pdfScanned }

@freezed
abstract class Document with _$Document {
  const factory Document({
    required String id,
    required String title,
    required DocumentSourceType sourceType,
    required List<Chapter> chapters,
  }) = _Document;

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);
}
