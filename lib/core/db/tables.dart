import 'package:drift/drift.dart';

/// One row per imported work. `updatedAt` is sync-ready per spec §13 (every
/// mutable row carries a stable ID + updatedAt so an optional sync layer can
/// use last-write-wins/CRDT later without a schema change).
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get sourceType => text()();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Block/Sentence/Token are stored as a single JSON blob per chapter rather
/// than normalized rows: OCR background jobs write per-chapter, and a fully
/// normalized per-token table would be expensive to write during that job.
/// The `sentences` table below is the queryable index over this blob.
class Chapters extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text().references(Documents, #id)();
  IntColumn get chapterIndex => integer().named('chapter_index')();
  TextColumn get title => text().nullable()();
  TextColumn get blocksJson => text().named('blocks_json')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Flat, queryable index over sentences so Card Mode/Document Mode can
/// resolve a stable Sentence ID to its chapter/position in O(1) instead of
/// scanning every chapter's blocksJson blob.
class Sentences extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text().references(Documents, #id)();
  TextColumn get chapterId => text().references(Chapters, #id)();
  IntColumn get chapterIndex => integer().named('chapter_index')();
  IntColumn get blockIndex => integer().named('block_index')();
  IntColumn get sentenceIndex => integer().named('sentence_index')();
  TextColumn get content => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Dictionary import/lookup (spec §10; design per docs/research/r5-dictionary.md).
// ---------------------------------------------------------------------------

/// One row per installed Yomitan dictionary (from `index.json` + import
/// bookkeeping) -- the user's installed-dictionaries list and their
/// priority order. Sync-ready per spec §13 (id/addedAt/updatedAt, matching
/// `Documents`' treatment): this is small, user-authored state (which
/// dictionaries are installed, in what order, enabled/disabled), not the
/// bulk imported content, which is why this table carries the sync-ready
/// columns but `DictionaryTermEntries`/`DictionaryTermMetaEntries`/
/// `DictionaryTagEntries` below don't -- spec §13 says dictionaries "stay
/// local-only (large, regenerable, not worth syncing)". See
/// docs/research/r5-dictionary.md §2.
@DataClassName('Dictionary')
class Dictionaries extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get revision => text()();
  IntColumn get formatVersion => integer().named('format_version')();
  TextColumn get author => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get attribution => text().nullable()();
  TextColumn get sourceLanguage => text().nullable().named('source_language')();
  TextColumn get targetLanguage => text().nullable().named('target_language')();

  /// `index.json`'s `frequencyMode`: `occurrence-based` | `rank-based`.
  /// Affects how a frequency-dictionary number should be displayed; not
  /// interpreted by storage/lookup, just carried through for the popup UI.
  TextColumn get frequencyMode => text().nullable().named('frequency_mode')();

  /// Whether term entries carry meaningful `sequence` numbers for
  /// `resultOutputMode: merge` display (`index.json`'s `sequenced`).
  BoolColumn get sequenced => boolean().withDefault(const Constant(false))();

  /// User-ordered lookup priority. Lower = higher priority = preferred for
  /// the popup's default definition. Dense (0..N-1) and fully renumbered on
  /// every reorder rather than left sparse -- the dictionary count is small
  /// (tens, not thousands), so a full renumber on drag-reorder is cheap and
  /// keeps queries simple (no gap-management logic).
  IntColumn get priority => integer()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tag display metadata from `tag_bank_N.json`. Scoped per-dictionary
/// because two dictionaries can define a tag with the same name and a
/// different category/notes (e.g. both ship a tag literally named `n`).
@DataClassName('DictionaryTagEntry')
class DictionaryTagEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dictionaryId => text().references(Dictionaries, #id)();
  TextColumn get name => text()();
  TextColumn get category => text()();

  /// `tag_bank`'s field name is `order` -- reserved in SQL, so this column
  /// is both Dart- and SQL-renamed.
  IntColumn get sortOrder => integer().named('sort_order')();
  TextColumn get notes => text()();
  RealColumn get score => real()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {dictionaryId, name},
  ];
}

/// Flattened `term_bank_N.json` entries -- one row per source 8-tuple, and
/// the core lookup table. `headword`/`readingNormalized` are indexed for
/// the tier-1/tier-2 lookup; `rules` is what the tier-3 deconjugation retry
/// validates candidates against. See docs/research/r5-dictionary.md §1-3.
///
/// NOTE: a Drift column literally named `text` collides with the `text()`
/// column-builder method and crashes codegen -- every text-ish column below
/// is named something else (`definitionsJson`, `dataJson`, ...) instead.
@TableIndex(name: 'idx_dict_term_headword', columns: {#headword})
@TableIndex(
  name: 'idx_dict_term_reading_normalized',
  columns: {#readingNormalized},
)
@TableIndex(
  name: 'idx_dict_term_dictionary_sequence',
  columns: {#dictionaryId, #sequence},
)
@DataClassName('DictionaryTermEntry')
class DictionaryTermEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dictionaryId => text().references(Dictionaries, #id)();

  TextColumn get headword => text()(); // term_bank[0]
  TextColumn get reading => text()(); // term_bank[1], raw (may be '')

  /// Normalized at import time: `reading.isEmpty ? headword : reading`, so
  /// lookup queries never special-case the "empty reading means same as
  /// term" schema rule -- every row has a real, non-empty reading to match
  /// against.
  TextColumn get readingNormalized => text().named('reading_normalized')();

  TextColumn get definitionTags =>
      text().nullable().named('definition_tags')(); // [2]
  TextColumn get rules =>
      text()(); // term_bank[3], space-separated, '' if uninflectable
  RealColumn get score => real()(); // term_bank[4] -- schema says "number"
  TextColumn get definitionsJson =>
      text().named('definitions_json')(); // term_bank[5], opaque JSON
  IntColumn get sequence => integer()(); // term_bank[6]
  TextColumn get termTags => text().named('term_tags')(); // term_bank[7]

  /// Position within the dictionary's term banks, counted across all
  /// `term_bank_N.json` files in filename order (file order first, then
  /// array order within each file). Used as the final tiebreaker when two
  /// entries share a dictionary and a score, so results stay deterministic
  /// and match the order the dictionary author shipped them in.
  IntColumn get importOrder => integer().named('import_order')();
}

/// Frequency/pitch/IPA data from `term_meta_bank_N.json`. The three modes'
/// payloads are genuinely different shapes (docs/research/r5-dictionary.md
/// §1) -- rather than force them into shared flat columns, the mode-specific
/// payload is stored as JSON and `reading` is pulled out as its own nullable
/// column (present for pitch/ipa always, present for freq only when the
/// entry is reading-specific) so reading-scoped queries don't have to parse
/// JSON to filter.
@TableIndex(
  name: 'idx_dict_term_meta_lookup',
  columns: {#dictionaryId, #headword, #mode},
)
@DataClassName('DictionaryTermMetaEntry')
class DictionaryTermMetaEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dictionaryId => text().references(Dictionaries, #id)();

  TextColumn get headword => text()(); // term_meta_bank[0]
  TextColumn get mode => text()(); // term_meta_bank[1]: freq|pitch|ipa
  TextColumn get reading =>
      text().nullable()(); // pulled from payload; null = all readings
  TextColumn get dataJson =>
      text().named('data_json')(); // full mode-specific payload, verbatim
}
