import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'grammar_point.dart';

/// Loads the bundled grammar-point database (spec §8 layer 2) from
/// `assets/grammar/grammar_points.json`. Small (~200 entries) and original
/// content authored for this project -- bundled as a real asset rather than
/// fetched at runtime, unlike the Yomitan dictionary/Sudachi/OCR-model
/// assets, which are large and/or third-party-licensed (see
/// `dictionary_paths.dart`/`model_fetcher.dart`'s own doc comments for that
/// distinction).
Future<List<GrammarPoint>> loadGrammarPoints({AssetBundle? bundle}) async {
  final raw = await (bundle ?? rootBundle).loadString(
    'assets/grammar/grammar_points.json',
  );
  final decoded = jsonDecode(raw) as List;
  return decoded
      .map((e) => GrammarPoint.fromJson(e as Map<String, dynamic>))
      .toList();
}
