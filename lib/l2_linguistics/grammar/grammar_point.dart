/// One example sentence for a [GrammarPoint], shown alongside its
/// explanation (spec §8 layer 2: "shaped like DoJG/Bunpro entries").
/// Original content authored for this project, not copied verbatim from any
/// third-party grammar reference -- same reasoning as `sample_content.dart`
/// using its own dictionary fixture rather than real Yomitan/JMdict data.
class GrammarExample {
  const GrammarExample({required this.japanese, required this.english});

  final String japanese;
  final String english;

  factory GrammarExample.fromJson(Map<String, dynamic> json) => GrammarExample(
    japanese: json['japanese'] as String,
    english: json['english'] as String,
  );

  Map<String, dynamic> toJson() => {'japanese': japanese, 'english': english};
}

/// One entry in the grammar-point database (spec §8 layer 2): `{ id,
/// pattern, matcher, jlptLevel, explanation, examples }`, exactly spec's own
/// schema. Data-only -- adding a new grammar point never requires a code
/// change, only a new entry in `assets/grammar/grammar_points.json` (spec
/// §8's content note: "a schema that allows adding points as data").
///
/// [matcher] is a regular expression run against a sentence's plain surface
/// text (`Sentence.surfaceText`), not a token-sequence/POS-aware pattern --
/// see `grammar_matcher.dart`'s own doc comment for why that's the right
/// tradeoff for a ~200-entry, hand-correctable, data-driven database rather
/// than a bespoke matching DSL.
class GrammarPoint {
  const GrammarPoint({
    required this.id,
    required this.pattern,
    required this.matcher,
    required this.jlptLevel,
    required this.explanation,
    required this.examples,
  });

  /// Stable, unique identifier -- this *is* the point's collection identity
  /// (see `core/ids/stable_id.dart`'s `contentDerivedGrammarId`, which just
  /// namespaces this value rather than hashing it, since a grammar point's
  /// own id is already unique by construction). Convention: a short,
  /// romanized/ASCII slug describing the pattern (e.g. `te-iru-progressive`),
  /// stable across content edits so re-shipping a corrected explanation
  /// never orphans a user's already-mined `CollectedGrammar` row.
  final String id;

  /// Display form of the pattern itself, as a learner would recognize it in
  /// a reference book (e.g. `～ている`).
  final String pattern;

  /// A [RegExp]-pattern string matched against a sentence's surface text.
  final String matcher;

  /// `N5`-`N1`. String, not an enum: keeps the schema pure data (a new JLPT
  /// convention or a non-JLPT tag would otherwise need a code change).
  final String jlptLevel;

  /// Short, plain-language explanation of what the pattern means/does.
  final String explanation;

  final List<GrammarExample> examples;

  factory GrammarPoint.fromJson(Map<String, dynamic> json) => GrammarPoint(
    id: json['id'] as String,
    pattern: json['pattern'] as String,
    matcher: json['matcher'] as String,
    jlptLevel: json['jlptLevel'] as String,
    explanation: json['explanation'] as String,
    examples: (json['examples'] as List)
        .map((e) => GrammarExample.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'pattern': pattern,
    'matcher': matcher,
    'jlptLevel': jlptLevel,
    'explanation': explanation,
    'examples': examples.map((e) => e.toJson()).toList(),
  };
}
