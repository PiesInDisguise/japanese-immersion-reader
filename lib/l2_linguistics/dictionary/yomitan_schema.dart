/// Parsed representations of the Yomitan v3 dictionary JSON shapes
/// confirmed in docs/research/r5-dictionary.md §1 (checked directly against
/// the `yomidevs/yomitan` schema files, not just its prose docs). Pure data
/// and parsing only -- no I/O, no zip handling, no database -- see
/// `dictionary_importer.dart` for how these get read out of a zip and
/// written into `AppDatabase`.
library;

/// `index.json`. Required: `title`, `revision`, and either `format` or
/// `version` (the schema aliases the two spellings of the same field) --
/// [formatVersion] always holds whichever of the two was present in the
/// source JSON, preferring `format`.
class YomitanIndex {
  const YomitanIndex({
    required this.title,
    required this.revision,
    required this.formatVersion,
    this.author,
    this.url,
    this.description,
    this.attribution,
    this.sourceLanguage,
    this.targetLanguage,
    this.frequencyMode,
    this.sequenced = false,
  });

  final String title;
  final String revision;
  final int formatVersion;
  final String? author;
  final String? url;
  final String? description;
  final String? attribution;
  final String? sourceLanguage;
  final String? targetLanguage;
  final String? frequencyMode;
  final bool sequenced;

  factory YomitanIndex.fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    final revision = json['revision'];
    final formatVersion = json['format'] ?? json['version'];
    if (title is! String || revision is! String || formatVersion is! int) {
      throw FormatException(
        'index.json must have a string "title", a string "revision", and '
        'an integer "format" (or "version"): $json',
      );
    }
    return YomitanIndex(
      title: title,
      revision: revision,
      formatVersion: formatVersion,
      author: json['author'] as String?,
      url: json['url'] as String?,
      description: json['description'] as String?,
      attribution: json['attribution'] as String?,
      sourceLanguage: json['sourceLanguage'] as String?,
      targetLanguage: json['targetLanguage'] as String?,
      frequencyMode: json['frequencyMode'] as String?,
      sequenced: json['sequenced'] as bool? ?? false,
    );
  }
}

/// One `term_bank_N.json` entry -- a fixed 8-element tuple (R5 §1):
/// `[term, reading, definitionTags, rules, score, definitions, sequence,
/// termTags]`.
class YomitanTermEntry {
  const YomitanTermEntry({
    required this.term,
    required this.reading,
    required this.definitionTags,
    required this.rules,
    required this.score,
    required this.definitions,
    required this.sequence,
    required this.termTags,
  });

  final String term;

  /// Raw as read from the tuple -- may be the empty string. See
  /// [readingNormalized].
  final String reading;
  final String? definitionTags;

  /// Space-separated deinflection rule identifiers (e.g. `v5`, `vk`,
  /// `adj-i`); the empty string for uninflectable words. This is what the
  /// tier-3 deconjugation retry validates a deinflection candidate's rule
  /// against -- see `deinflector.dart` and `dictionary_repository.dart`.
  final String rules;
  final double score;

  /// Opaque and heterogeneous per R5 §1: each element is a plain string, a
  /// `{type: text}` object, a `{type: image}` object, a
  /// `{type: structured-content}` object, or a 2-element cross-reference
  /// list. Stored verbatim as JSON at import time -- rendering this tree is
  /// separate, later UI work, not this importer's concern.
  final List<dynamic> definitions;
  final int sequence;
  final String termTags;

  /// `reading.isEmpty ? term : reading`. An empty reading in the source
  /// JSON means "same as term" (R5 §1); normalized here so lookup queries
  /// never have to special-case that rule themselves.
  String get readingNormalized => reading.isEmpty ? term : reading;

  factory YomitanTermEntry.fromTuple(List<dynamic> tuple) {
    if (tuple.length != 8) {
      throw FormatException(
        'term_bank entry must have exactly 8 elements, got '
        '${tuple.length}: $tuple',
      );
    }
    final term = tuple[0];
    final reading = tuple[1];
    final definitionTags = tuple[2];
    final rules = tuple[3];
    final score = tuple[4];
    final definitions = tuple[5];
    final sequence = tuple[6];
    final termTags = tuple[7];
    if (term is! String ||
        reading is! String ||
        (definitionTags != null && definitionTags is! String) ||
        rules is! String ||
        score is! num ||
        definitions is! List ||
        sequence is! num ||
        termTags is! String) {
      throw FormatException('term_bank entry has an unexpected shape: $tuple');
    }
    return YomitanTermEntry(
      term: term,
      reading: reading,
      definitionTags: definitionTags as String?,
      rules: rules,
      score: score.toDouble(),
      definitions: definitions,
      sequence: sequence.toInt(),
      termTags: termTags,
    );
  }
}

/// `term_meta_bank_N.json`'s second tuple element.
enum YomitanTermMetaMode { freq, pitch, ipa }

/// One `term_meta_bank_N.json` entry -- a fixed 3-element tuple (R5 §1):
/// `[term, mode, data]`, where `data`'s shape depends on `mode`.
class YomitanTermMetaEntry {
  const YomitanTermMetaEntry({
    required this.term,
    required this.mode,
    required this.data,
  });

  final String term;
  final YomitanTermMetaMode mode;

  /// Raw mode-specific payload, exactly as it appeared in the tuple's third
  /// element -- stored verbatim as JSON at import time. Callers needing
  /// pitch/ipa detail must interpret this themselves; only
  /// [readingForIndex] is pulled out eagerly here, since it doubles as an
  /// indexed lookup column.
  final Object? data;

  factory YomitanTermMetaEntry.fromTuple(List<dynamic> tuple) {
    if (tuple.length != 3) {
      throw FormatException(
        'term_meta_bank entry must have exactly 3 elements, got '
        '${tuple.length}: $tuple',
      );
    }
    final term = tuple[0];
    final modeString = tuple[1];
    if (term is! String || modeString is! String) {
      throw FormatException(
        'term_meta_bank entry has an unexpected shape: $tuple',
      );
    }
    final YomitanTermMetaMode mode;
    try {
      mode = YomitanTermMetaMode.values.byName(modeString);
    } on ArgumentError {
      throw FormatException(
        'Unknown term_meta_bank mode "$modeString": $tuple',
      );
    }
    return YomitanTermMetaEntry(term: term, mode: mode, data: tuple[2]);
  }

  /// The reading this payload is scoped to (R5 §1/§2), pulled out of the
  /// mode-specific [data] shape so reading-scoped queries don't need to
  /// parse JSON to filter. `null` means the payload applies to every
  /// reading of [term] -- always true for a bare `freq` number or a
  /// `{value, displayValue?}` freq shape; never true for pitch/ipa, whose
  /// payload always carries a `reading`.
  String? get readingForIndex {
    final payload = data;
    if (payload is! Map) return null;
    final reading = payload['reading'];
    return reading is String ? reading : null;
  }
}

/// One `tag_bank_N.json` entry -- a fixed 5-element tuple (R5 §1):
/// `[name, category, order, notes, score]`. Purely display metadata,
/// resolved against a term's `definitionTags`/`termTags` at render time.
class YomitanTagEntry {
  const YomitanTagEntry({
    required this.name,
    required this.category,
    required this.order,
    required this.notes,
    required this.score,
  });

  final String name;
  final String category;
  final int order;
  final String notes;
  final double score;

  factory YomitanTagEntry.fromTuple(List<dynamic> tuple) {
    if (tuple.length != 5) {
      throw FormatException(
        'tag_bank entry must have exactly 5 elements, got '
        '${tuple.length}: $tuple',
      );
    }
    final name = tuple[0];
    final category = tuple[1];
    final order = tuple[2];
    final notes = tuple[3];
    final score = tuple[4];
    if (name is! String ||
        category is! String ||
        order is! num ||
        notes is! String ||
        score is! num) {
      throw FormatException('tag_bank entry has an unexpected shape: $tuple');
    }
    return YomitanTagEntry(
      name: name,
      category: category,
      order: order.toInt(),
      notes: notes,
      score: score.toDouble(),
    );
  }
}
