import 'package:japanese_immersion_reader/core/models/models.dart';

/// Spec §15: "comprehension % per page (share of words already known/
/// collected)". A pure function over already-tokenized sentences (the
/// caller decides *which* sentences count as "the page" -- realistically
/// the current chapter, not a whole book) and an injected "is this word
/// collected" check, so this has no tokenizer/database dependency of its
/// own and is trivially testable.
class ComprehensionCalculator {
  const ComprehensionCalculator(this._isCollected);

  final Future<bool> Function({
    required String dictForm,
    required String reading,
  })
  _isCollected;

  /// Punctuation-only tokens (periods, brackets, ideographic spaces...)
  /// are excluded from both the numerator and denominator -- they're never
  /// "collected" words, and counting them would only dilute the percentage
  /// toward whatever fraction of a sentence happens to be punctuation.
  static final _punctuationOnly = RegExp(
    r'^[\p{P}\p{Z}\s。、！？「」『』・…]+$',
    unicode: true,
  );

  /// `null` if [tokenizedSentences] contained no countable (non-punctuation)
  /// tokens at all -- distinct from `0.0`, which means real words were
  /// found and none of them are collected yet.
  Future<double?> compute(List<List<Token>> tokenizedSentences) async {
    var total = 0;
    var known = 0;

    for (final tokens in tokenizedSentences) {
      for (final token in tokens) {
        if (_punctuationOnly.hasMatch(token.surface)) continue;
        total++;
        final isKnown = await _isCollected(
          dictForm: token.dictForm ?? token.surface,
          reading: token.reading ?? token.surface,
        );
        if (isKnown) known++;
      }
    }

    if (total == 0) return null;
    return known / total;
  }
}
