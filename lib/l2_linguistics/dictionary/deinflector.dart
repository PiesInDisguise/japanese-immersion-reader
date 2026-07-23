/// A deliberately non-exhaustive, single-step reverse-conjugation
/// ("deinflection") pass over a surface-form string, covering only the most
/// common Japanese inflection patterns -- explicitly NOT a complete
/// deinflection engine. See the [Deinflector] doc comment for the exact
/// scope and why single-step coverage is enough for what this fallback tier
/// actually needs to do.
library;

/// The Yomitan `rules` string tags (docs/research/r5-dictionary.md §1) that
/// a [DeinflectionCandidate]'s implied part-of-speech corresponds to. A
/// candidate's [yomitanRuleTag] must appear in a matched dictionary entry's
/// own `rules` field for that candidate to be accepted -- see
/// `dictionary_repository.dart`'s tier-3 lookup.
enum InflectionRule {
  /// Ichidan ("ru-verb") -- Yomitan rule tag `v1`.
  ichidanVerb,

  /// Godan ("u-verb"), all nine consonant rows -- Yomitan rule tag `v5`.
  godanVerb,

  /// する and "noun+する" compound verbs -- Yomitan rule tag `vs`.
  suruVerb,

  /// 来る (くる) only -- Yomitan rule tag `vk`.
  kuruVerb,

  /// i-adjectives -- Yomitan rule tag `adj-i`.
  iAdjective;

  String get yomitanRuleTag => switch (this) {
    InflectionRule.ichidanVerb => 'v1',
    InflectionRule.godanVerb => 'v5',
    InflectionRule.suruVerb => 'vs',
    InflectionRule.kuruVerb => 'vk',
    InflectionRule.iAdjective => 'adj-i',
  };
}

/// One candidate dictionary form produced by [Deinflector.deinflect]:
/// [term] is the guessed uninflected headword, [rule] is the
/// part-of-speech category that guess implies (and thus what a matching
/// dictionary entry's `rules` field must contain for the candidate to be
/// considered valid).
class DeinflectionCandidate {
  const DeinflectionCandidate({required this.term, required this.rule});

  final String term;
  final InflectionRule rule;

  @override
  String toString() => 'DeinflectionCandidate($term, ${rule.yomitanRuleTag})';

  @override
  bool operator ==(Object other) =>
      other is DeinflectionCandidate &&
      other.term == term &&
      other.rule == rule;

  @override
  int get hashCode => Object.hash(term, rule);
}

/// Tier-3 fallback for spec §10's lookup chain ("dictionary form, with
/// fallback to surface form and a deconjugation retry"): guesses what
/// dictionary-form word a conjugated surface string might come from.
///
/// **Deliberately non-exhaustive -- covers only common patterns, not a full
/// deinflection engine.** Real deinflectors (Yomitan's own included) are
/// substantial standalone projects: they chain multiple deinflection steps
/// together (e.g. 食べさせられた needs three successive un-conjugations to
/// reach 食べる) via a reason graph, and cover dozens of rarer forms
/// (volitional, imperative, the -たり/-たら family, honorific keigo, colloquial
/// contractions like てる for ている, ...). None of that is attempted here.
/// Instead:
///
/// - Every rule below is a single suffix-for-suffix substitution: one
///   inflection layer, not a chain. This is a scoping decision, not an
///   oversight -- by the time text reaches this fallback, in the
///   overwhelmingly common case it has already been through Sudachi, whose
///   morphological segmentation *is* a real deinflection engine: a
///   multi-morpheme conjugation like 食べさせられた is already split into
///   食べ/させ/られ/た before a `Token`'s `dictForm` is even read, so tier-3
///   here only runs when *that* lookup still misses. The main case this
///   fallback actually needs to cover is spec §10's "drag across
///   characters" arbitrary span -- text Sudachi never tokenized at all --
///   which is typically exactly one inflection layer (a user drag-selecting
///   "食べた" as a whole span, say), not a deep chain.
/// - Only five part-of-speech categories are covered: i-adjectives, ichidan
///   verbs, godan verbs (all nine consonant rows), する/"noun+する" verbs, and
///   来る specifically (the only common kuru-type verb). These are exactly
///   the categories spec §10 names as examples.
/// - Over-generation is deliberate and safe: a suffix rule can match more
///   broadly than is linguistically correct (e.g. the ichidan "past" rule
///   also fires on godan words, since both can end in た), because
///   `dictionary_repository.dart` validates every candidate against a
///   matched entry's actual `rules` field before accepting it
///   (docs/research/r5-dictionary.md §3 finding 2) -- a spurious candidate
///   simply fails to validate rather than needing to be prevented from
///   being generated in the first place.
///
/// Known, accepted gaps: no volitional/imperative forms, no たり/たら, no
/// keigo, no colloquial contractions, no recursive/chained deinflection, and
/// 来る is only recognized in its kanji-prefixed spellings (来ない/来た/...),
/// not written fully in kana (くる/こない/きた/...) -- the kana spellings
/// would be indistinguishable from ordinary godan/ichidan verb endings
/// without much deeper analysis than this fallback is scoped to do.
abstract final class Deinflector {
  static List<DeinflectionCandidate> deinflect(String surfaceForm) {
    final candidates = <DeinflectionCandidate>[];
    for (final rule in _allRules) {
      final candidate = rule._tryApply(surfaceForm);
      if (candidate != null) candidates.add(candidate);
    }
    return candidates;
  }
}

class _SuffixRule {
  const _SuffixRule(
    this.suffix,
    this.replacement,
    this.rule, {
    this.minStemLength = 1,
  });

  /// Surface-form suffix this rule matches, e.g. `た`.
  final String suffix;

  /// What replaces [suffix] to produce the guessed dictionary form, e.g.
  /// `る`.
  final String replacement;
  final InflectionRule rule;

  /// Shortest stem (the part of the surface form *before* [suffix]) this
  /// rule accepts. `1` for regular godan/ichidan/i-adjective rules, since a
  /// real word always has at least one lexical character before its
  /// conjugation ending -- a bare ending with no stem at all isn't a real
  /// word. `0` for irregular verbs (する/来る/行く) whose fixed kanji+kana
  /// spelling is baked entirely into [suffix] itself, so the bare
  /// conjugated form (`した`, `来た`, `行った`, ...) with nothing prepended is
  /// itself a valid, common surface form.
  final int minStemLength;

  DeinflectionCandidate? _tryApply(String surface) {
    if (surface.length - suffix.length < minStemLength) return null;
    if (!surface.endsWith(suffix)) return null;
    final stem = surface.substring(0, surface.length - suffix.length);
    return DeinflectionCandidate(term: stem + replacement, rule: rule);
  }
}

const _iAdjectiveRules = [
  _SuffixRule('かった', 'い', InflectionRule.iAdjective), // 高かった -> 高い (past)
  _SuffixRule('くない', 'い', InflectionRule.iAdjective), // 高くない -> 高い (negative)
  _SuffixRule(
    'ければ',
    'い',
    InflectionRule.iAdjective,
  ), // 高ければ -> 高い (conditional)
  _SuffixRule('くて', 'い', InflectionRule.iAdjective), // 高くて -> 高い (te-form)
  _SuffixRule('く', 'い', InflectionRule.iAdjective), // 高く -> 高い (adverbial)
];

const _ichidanRules = [
  _SuffixRule('られる', 'る', InflectionRule.ichidanVerb), // passive/potential
  _SuffixRule('させる', 'る', InflectionRule.ichidanVerb), // causative
  _SuffixRule('ます', 'る', InflectionRule.ichidanVerb), // polite
  _SuffixRule('れば', 'る', InflectionRule.ichidanVerb), // conditional
  _SuffixRule('ない', 'る', InflectionRule.ichidanVerb), // negative
  _SuffixRule('た', 'る', InflectionRule.ichidanVerb), // past
  _SuffixRule('て', 'る', InflectionRule.ichidanVerb), // te-form
];

/// One godan ("u-verb") consonant row: the dictionary-form ending plus the
/// three conjugation stems (negative/passive/causative; polite; potential/
/// conditional) and the euphonic past/te-form suffix, which differs per row
/// (e.g. く -> いた/いて, ぬ/ぶ/む -> んだ/んで) rather than following a single
/// mechanical pattern.
class _GodanRow {
  const _GodanRow(
    this.dictionaryEnding,
    this.aRow,
    this.iRow,
    this.eRow,
    this.pastSuffix,
    this.teSuffix,
  );

  final String dictionaryEnding;
  final String aRow;
  final String iRow;
  final String eRow;
  final String pastSuffix;
  final String teSuffix;
}

const _godanRows = [
  _GodanRow('う', 'わ', 'い', 'え', 'った', 'って'),
  _GodanRow('く', 'か', 'き', 'け', 'いた', 'いて'),
  _GodanRow('ぐ', 'が', 'ぎ', 'げ', 'いだ', 'いで'),
  _GodanRow('す', 'さ', 'し', 'せ', 'した', 'して'),
  _GodanRow('つ', 'た', 'ち', 'て', 'った', 'って'),
  _GodanRow('ぬ', 'な', 'に', 'ね', 'んだ', 'んで'),
  _GodanRow('ぶ', 'ば', 'び', 'べ', 'んだ', 'んで'),
  _GodanRow('む', 'ま', 'み', 'め', 'んだ', 'んで'),
  _GodanRow('る', 'ら', 'り', 'れ', 'った', 'って'),
];

List<_SuffixRule> _buildGodanRules() {
  final rules = <_SuffixRule>[];
  for (final row in _godanRows) {
    rules.addAll([
      _SuffixRule(
        '${row.aRow}ない',
        row.dictionaryEnding,
        InflectionRule.godanVerb,
      ), // negative
      _SuffixRule(
        '${row.iRow}ます',
        row.dictionaryEnding,
        InflectionRule.godanVerb,
      ), // polite
      _SuffixRule(
        '${row.aRow}れる',
        row.dictionaryEnding,
        InflectionRule.godanVerb,
      ), // passive
      _SuffixRule(
        '${row.aRow}せる',
        row.dictionaryEnding,
        InflectionRule.godanVerb,
      ), // causative
      _SuffixRule(
        '${row.eRow}る',
        row.dictionaryEnding,
        InflectionRule.godanVerb,
      ), // potential
      _SuffixRule(
        '${row.eRow}ば',
        row.dictionaryEnding,
        InflectionRule.godanVerb,
      ), // conditional
      _SuffixRule(
        row.pastSuffix,
        row.dictionaryEnding,
        InflectionRule.godanVerb,
      ), // past
      _SuffixRule(
        row.teSuffix,
        row.dictionaryEnding,
        InflectionRule.godanVerb,
      ), // te-form
    ]);
  }
  return rules;
}

/// 行く's past/te-form is irregular (行った/行って, not the いた/いて a
/// mechanical く-row rule would produce) -- the one well-known exception to
/// the godan く-row pattern, common enough to special-case explicitly.
/// `minStemLength: 0` because -- like the する/来る rules below -- 行く's
/// kanji is fixed and baked into the suffix itself, so the bare conjugated
/// form with nothing prepended is a valid, common surface form on its own.
const _ikuExceptionRules = [
  _SuffixRule('行った', '行く', InflectionRule.godanVerb, minStemLength: 0),
  _SuffixRule('行って', '行く', InflectionRule.godanVerb, minStemLength: 0),
];

const _suruRules = [
  _SuffixRule('します', 'する', InflectionRule.suruVerb, minStemLength: 0),
  _SuffixRule('した', 'する', InflectionRule.suruVerb, minStemLength: 0),
  _SuffixRule('して', 'する', InflectionRule.suruVerb, minStemLength: 0),
  _SuffixRule('しない', 'する', InflectionRule.suruVerb, minStemLength: 0),
  _SuffixRule(
    'できる',
    'する',
    InflectionRule.suruVerb,
    minStemLength: 0,
  ), // potential
  _SuffixRule(
    'される',
    'する',
    InflectionRule.suruVerb,
    minStemLength: 0,
  ), // passive
  _SuffixRule(
    'させる',
    'する',
    InflectionRule.suruVerb,
    minStemLength: 0,
  ), // causative
];

/// 来る (くる) only, and only in its kanji-prefixed spellings -- see the
/// class doc comment's "known gaps" for why the kana-only forms aren't
/// covered.
const _kuruRules = [
  _SuffixRule('来ない', '来る', InflectionRule.kuruVerb, minStemLength: 0),
  _SuffixRule('来た', '来る', InflectionRule.kuruVerb, minStemLength: 0),
  _SuffixRule('来て', '来る', InflectionRule.kuruVerb, minStemLength: 0),
  _SuffixRule('来ます', '来る', InflectionRule.kuruVerb, minStemLength: 0),
  _SuffixRule('来られる', '来る', InflectionRule.kuruVerb, minStemLength: 0),
  _SuffixRule('来させる', '来る', InflectionRule.kuruVerb, minStemLength: 0),
];

final List<_SuffixRule> _allRules = [
  ..._iAdjectiveRules,
  ..._ichidanRules,
  ..._buildGodanRules(),
  ..._ikuExceptionRules,
  ..._suruRules,
  ..._kuruRules,
];
