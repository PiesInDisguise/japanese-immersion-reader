import 'grammar_point.dart';

/// One [GrammarPoint] found in a sentence.
class GrammarMatch {
  const GrammarMatch({required this.point, required this.matchedText});

  final GrammarPoint point;

  /// The literal substring [GrammarPoint.matcher] matched -- shown in the UI
  /// so a learner can see exactly which part of the sentence the point
  /// refers to, not just its abstract pattern name.
  final String matchedText;
}

/// Matches a sentence's surface text against every loaded [GrammarPoint]
/// (spec §8 layer 2), returning every point that appears in it.
///
/// **Regex-over-surface-text, not a token-sequence/POS-aware matcher --
/// a deliberate scope choice, not an oversight.** Spec §8's own content note
/// calls the grammar-point database "the largest content-authoring task in
/// the project" and explicitly recommends "LLM-generating a first pass for
/// hand-correction" over ~200 patterns. A token-sequence DSL (matching
/// against Sudachi POS/inflection tags, not just characters) would be more
/// precise -- immune to a pattern coincidentally appearing inside unrelated
/// text -- but every one of those ~200 entries would need a correct,
/// hand-verified token-sequence rule instead of a single regex, which is
/// dramatically harder to both author in bulk and hand-correct later. A
/// surface-text regex is exactly what "add points as data, no code changes"
/// (spec §8) can practically scale to for a first pass, at the cost of
/// occasional false positives (e.g. a pattern's characters appearing by
/// coincidence across a word boundary the pattern doesn't actually apply
/// to). Nothing about [GrammarPoint]'s schema forecloses a richer matcher
/// later -- `matcher` is just a string; a future pass could interpret it as
/// a small token-sequence DSL instead of a bare [RegExp] without touching
/// the JSON data format itself, only this class.
///
/// Compiles every [GrammarPoint.matcher] once, at construction, rather than
/// on every [matchSentence] call -- this runs once per sentence a reader
/// actually opens the grammar breakdown for, not once per token, so
/// per-sentence cost matters more than construction cost.
class GrammarMatcher {
  GrammarMatcher(List<GrammarPoint> points)
    : _compiled = [for (final point in points) (point, RegExp(point.matcher))];

  final List<(GrammarPoint, RegExp)> _compiled;

  /// Every [GrammarPoint] whose [GrammarPoint.matcher] matches somewhere in
  /// [surfaceText], in the same order [GrammarMatcher] was constructed with
  /// (i.e. the order the grammar-point database itself lists them in --
  /// callers that want e.g. JLPT-level ordering should sort the input list
  /// before constructing this, not after matching).
  List<GrammarMatch> matchSentence(String surfaceText) {
    final matches = <GrammarMatch>[];
    for (final (point, regex) in _compiled) {
      final match = regex.firstMatch(surfaceText);
      if (match != null) {
        matches.add(GrammarMatch(point: point, matchedText: match.group(0)!));
      }
    }
    return matches;
  }
}
