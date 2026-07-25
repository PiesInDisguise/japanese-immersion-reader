import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// Sync-readiness audit (spec §13: "every mutable row carries a stable UUID
// and updatedAt, so an optional cloud-sync layer... can be added later
// without reworking the data model"). Sync itself is out of scope (spec
// §17: "explicitly deferred") -- this is a review of whether the *schema*
// actually holds up to that promise, done once all of Phase 1-11's tables
// existed, rather than assumed.
//
// Already sync-ready (stable id + addedAt/updatedAt): Documents,
// Dictionaries, CollectedWords, CollectedGrammars.
//
// Fixed by this audit (schemaVersion 5->6, see database.dart): Settings had
// no `updatedAt` at all despite being genuinely mutable, user-authored
// state; CollectedWordSources/CollectedGrammarSources' only identity was an
// autoincrement int, which two devices would assign colliding values to
// independently -- both now also carry a real UUID (`uuid`), generated at
// insert time, without disturbing the existing autoincrement `id` that
// `MiningEngine`/`ReviewEngine`'s local undo/delete-by-id plumbing already
// depends on.
//
// Deliberately left alone, and why:
// - Chapters/Sentences: derived, regenerable content (re-importing the
//   same source file reproduces them byte-for-byte) -- the same "large,
//   regenerable, not worth syncing" bucket spec §13 explicitly puts
//   dictionaries in, just never said out loud for these two.
// - SentenceExplanations: a write-once cache keyed by content hash: never
//   updated after insert, and regenerable (at the cost of paying for the
//   LLM call again) -- same reasoning as Chapters/Sentences.
// - ReadingActivity: `date` (a UTC calendar day) is already a natural,
//   device-independent stable key -- no UUID needed. It's genuinely
//   mutable (`secondsRead` accumulates across calls) but deliberately
//   *doesn't* get an `updatedAt` here: the correct merge strategy across
//   two devices that both logged reading time on the same day is to *sum*
//   their independent contributions, not last-write-wins overwrite one
//   with the other -- an `updatedAt` column would invite the wrong
//   (lossy) merge strategy rather than actually preparing this table for
//   sync.
// ---------------------------------------------------------------------------

/// One row per imported work. `updatedAt` is sync-ready per spec §13 (every
/// mutable row carries a stable ID + updatedAt so an optional sync layer can
/// use last-write-wins/CRDT later without a schema change).
///
/// `@DataClassName('DocumentRow')`: Drift's default data-class name is the
/// singular of the table name -- `Document`, `Chapter`, `Sentence` here --
/// which collides with this project's own frozen domain models of the exact
/// same names (`lib/core/models/`). That collision was latent until a
/// dictionary-lookup function needed both `package:.../core/models/models.dart`
/// and this file in one import, at which point `Document`/`Chapter`/`Sentence`
/// became ambiguous. `Row` suffixes disambiguate "a raw DB row" from "the
/// domain model" everywhere both are needed together, rather than requiring
/// import prefixes at every future call site that needs both.
@DataClassName('DocumentRow')
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get sourceType => text()();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Absolute path to a locally-stored cover image (see `CoverArtStore`) --
  /// either auto-extracted at import time (EPUB manifest cover / PDF page-1
  /// render) or picked by the user via the Library's tap-to-customize flow.
  /// Nullable: no cover extracted/picked yet, in which case the Library
  /// falls back to a per-source-type placeholder icon.
  TextColumn get coverImagePath =>
      text().nullable().named('cover_image_path')();

  /// The stable Sentence ID (spec §5) either reading mode last showed for
  /// this document, so reopening resumes exactly where the user left off.
  /// Nullable: never opened, or opened before this feature existed.
  TextColumn get lastSentenceId =>
      text().nullable().named('last_sentence_id')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Block/Sentence/Token are stored as a single JSON blob per chapter rather
/// than normalized rows: OCR background jobs write per-chapter, and a fully
/// normalized per-token table would be expensive to write during that job.
/// The `sentences` table below is the queryable index over this blob.
@DataClassName('ChapterRow')
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
@DataClassName('SentenceRow')
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

// ---------------------------------------------------------------------------
// Collection layer (L4, spec §11): mined words/grammar points and their SRS
// state. `CollectedWords`/`CollectedGrammars` are structurally parallel --
// see lib/l4_mining/collection/mining_engine.dart for the shared mine/
// remove/undo state machine both are built on (spec §6: "the grammar side
// behaves identically" against the grammar dictionary). `CollectedGrammars`
// simply omits `senseIds`, since grammar points aren't dictionary senses.
//
// SRS state is stored as flat columns (`srsInterval`/`srsEase`/`srsDue`/
// `srsLapses`/`srsStatus`) rather than spec §11's nested `srsState` struct,
// since Drift columns are scalar -- see
// lib/l4_mining/collection/srs_state.dart for the in-memory shape these
// columns round-trip through. Values are schema-correct placeholders only;
// the real FSRS algorithm is a later phase (lib/l5_srs/fsrs/).
//
// `sourceRefs[]` (spec §11) is a proper joined table per entry
// (`CollectedWordSources`/`CollectedGrammarSources`), not JSON, because spec
// explicitly wants this queryable later ("first seen in Chapter 3 of X").
// Rows are deliberately not unique on (parent, workId, sentenceId): mining
// the same word from the same sentence twice, or from two different works,
// is two rows (spec §11: "the same word mined from a novel today and a
// subtitle later is one entry with two sightings").
//
// Neither pair needs `@DataClassName`: Drift's default singularization
// (`CollectedWords` -> `CollectedWord`, `CollectedGrammars` ->
// `CollectedGrammar`, `CollectedWordSources` -> `CollectedWordSource`,
// `CollectedGrammarSources` -> `CollectedGrammarSource`) doesn't collide
// with anything in lib/core/models/ today -- see Documents/Chapters/
// Sentences above for what to do if a future table's singular ever would.
// ---------------------------------------------------------------------------

/// One row per mined word, keyed by [contentDerivedWordId]'s content-derived
/// id so "is this word already collected" is a direct primary-key lookup.
/// Sync-ready per spec §13 (`addedAt`/`updatedAt`), matching `Documents`'/
/// `Dictionaries`' treatment: this is small, user-authored state, not bulk
/// regenerable content.
class CollectedWords extends Table {
  TextColumn get id => text()();
  TextColumn get dictForm => text().named('dict_form')();
  TextColumn get reading => text()();

  /// JSON-encoded `List<int>` of `DictionaryTermEntry.id`s (spec §11) this
  /// collection came from. Not independently queryable the way
  /// `sourceRefs` needs to be, so JSON is fine here. Set on a fresh add;
  /// deliberately left untouched by a reset-tap (spec §6's re-tap only
  /// appends a sighting and resets SRS state).
  TextColumn get senseIdsJson => text().named('sense_ids_json')();

  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Real FSRS memory state (spec §12, `lib/l5_srs/fsrs/fsrs_scheduler.dart`)
  /// -- null together with [stability]/[lastReviewedAt] exactly when
  /// [srsStatus] is `newCard` (never reviewed yet). Replaced the earlier
  /// SM-2-shaped `srsInterval`/`srsEase` placeholder columns in a
  /// schemaVersion 2->3 migration once the real FSRS scheduler existed to
  /// populate them -- see `database.dart`'s `migration` override.
  RealColumn get fsrsDifficulty => real().nullable().named('fsrs_difficulty')();
  RealColumn get fsrsStability => real().nullable().named('fsrs_stability')();
  DateTimeColumn get srsDue => dateTime().named('srs_due')();
  IntColumn get srsLapses => integer().named('srs_lapses')();
  TextColumn get srsStatus => text().named('srs_status')();
  DateTimeColumn get lastReviewedAt =>
      dateTime().nullable().named('last_reviewed_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per sighting of a `CollectedWords` entry (spec §11's
/// `sourceRefs[] -> { workId, sentenceId, mediaType }`). `workId`/
/// `sentenceId` reference `Documents`/`Sentences` (this codebase doesn't
/// enable SQLite's `PRAGMA foreign_keys`, so these aren't enforced at
/// runtime -- see `MiningStore.deleteEntry` implementations, which delete a
/// parent's sightings explicitly rather than relying on an FK cascade).
@TableIndex(
  name: 'idx_collected_word_sources_word',
  columns: {#collectedWordId},
)
class CollectedWordSources extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Spec §13 sync-readiness (schemaVersion 5->6 audit): [id] alone is only
  /// unique *within this device* -- two devices each mining independently
  /// would assign colliding autoincrement values. Generated at insert time
  /// (`WordCollectionRepository`'s `_WordMiningStore.insertSighting`) via
  /// `package:uuid`; nullable because rows created before this migration
  /// have none and aren't backfilled. [id] itself is left alone rather than
  /// replaced -- every existing `deleteSighting(int)`/`MineResult` call
  /// site already keys off it for same-device undo/delete, which has
  /// nothing to do with cross-device identity.
  TextColumn get uuid => text().nullable()();

  TextColumn get collectedWordId =>
      text().references(CollectedWords, #id).named('collected_word_id')();
  TextColumn get workId => text().references(Documents, #id).named('work_id')();
  TextColumn get sentenceId =>
      text().references(Sentences, #id).named('sentence_id')();

  /// `CollectionMediaType.name` (lib/l4_mining/collection/source_ref.dart) --
  /// deliberately not `DocumentSourceType`; see that enum's doc comment.
  TextColumn get mediaType => text().named('media_type')();
  DateTimeColumn get minedAt => dateTime().named('mined_at')();
}

/// Grammar-side mirror of `CollectedWords`, keyed by
/// [contentDerivedGrammarId]. `grammarPointId` is an opaque string id from
/// spec §8's grammar-point database, which doesn't exist as a concrete
/// model yet (a later phase) -- no `senseIds` here, since grammar points
/// aren't dictionary senses.
class CollectedGrammars extends Table {
  TextColumn get id => text()();
  TextColumn get grammarPointId => text().named('grammar_point_id')();

  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// See `CollectedWords.fsrsDifficulty`'s doc comment -- identical
  /// reasoning, grammar-side mirror.
  RealColumn get fsrsDifficulty => real().nullable().named('fsrs_difficulty')();
  RealColumn get fsrsStability => real().nullable().named('fsrs_stability')();
  DateTimeColumn get srsDue => dateTime().named('srs_due')();
  IntColumn get srsLapses => integer().named('srs_lapses')();
  DateTimeColumn get lastReviewedAt =>
      dateTime().nullable().named('last_reviewed_at')();
  TextColumn get srsStatus => text().named('srs_status')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Grammar-side mirror of `CollectedWordSources`.
@TableIndex(
  name: 'idx_collected_grammar_sources_grammar',
  columns: {#collectedGrammarId},
)
class CollectedGrammarSources extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// See `CollectedWordSources.uuid`'s doc comment -- identical reasoning,
  /// grammar-side mirror.
  TextColumn get uuid => text().nullable()();

  TextColumn get collectedGrammarId =>
      text().references(CollectedGrammars, #id).named('collected_grammar_id')();
  TextColumn get workId => text().references(Documents, #id).named('work_id')();
  TextColumn get sentenceId =>
      text().references(Sentences, #id).named('sentence_id')();
  TextColumn get mediaType => text().named('media_type')();
  DateTimeColumn get minedAt => dateTime().named('mined_at')();
}

// ---------------------------------------------------------------------------
// Settings + LLM explanation cache (spec §8 layer 3, spec §14) -- added in a
// schema migration (see database.dart's `migration` override), not just
// appended to schemaVersion 1's table list: this project has been under
// active local development long enough that a real on-disk dev database
// already exists without these tables, and Drift's default `onCreate`-only
// behavior never revisits an already-created database, so skipping a real
// migration here would crash the very next run against that existing file.
// ---------------------------------------------------------------------------

/// Single-row table (fixed `id = 0`) for the handful of user-configurable
/// settings spec §14 lists that this project has actually built UI for so
/// far -- just the LLM section (API key entry, grammar-explanation on/off).
/// The rest of spec §14's settings (reader appearance, mining auto-add,
/// definition popup fields, audio, dictionaries, decks, UI language) have no
/// settings UI yet and so have no columns here either; add them to this same
/// row when their own features get built, rather than a key-value table --
/// there's only ever one settings row per install, so a fixed schema is
/// simpler than a generic key-value store for this project's actual needs.
@DataClassName('SettingsRow')
class Settings extends Table {
  IntColumn get id => integer()();

  /// The user's own Anthropic API key (spec §14: "LLM — API key entry"; spec
  /// §2: "BYO", no hosted proxy). Stored in the same local SQLite database
  /// as everything else in this local-first app -- not OS keychain/secure
  /// storage, matching this project's own "local-first, no account, no
  /// cloud" posture; a future pass could move this to a platform secure-
  /// storage API without changing any caller of [SettingsRepository], only
  /// this column's own storage.
  TextColumn get llmApiKey => text().nullable().named('llm_api_key')();

  /// Spec §14: "grammar-explanation on/off". Defaults on: layer 3 is meant
  /// to be additive/optional (spec §8: "already fully usable without it"),
  /// so the only real gate on whether it actually runs is whether an API key
  /// is present, not this toggle needing an extra opt-in step too.
  BoolColumn get llmExplanationsEnabled =>
      boolean().withDefault(const Constant(true)).named('llm_explanations_enabled')();

  /// Spec §9/§14: "TTS on/off" -- unlike [llmExplanationsEnabled], this
  /// defaults *off*: spec §9 states audio is "optional, off by default" and
  /// "fully skippable" outright, not just gated behind a separate
  /// prerequisite the way layer 3 is gated behind an API key.
  BoolColumn get ttsEnabled =>
      boolean().withDefault(const Constant(false)).named('tts_enabled')();

  /// Spec §9/§14: "pitch-accent audio on/off" -- same off-by-default
  /// reasoning as [ttsEnabled]. Kept as its own toggle rather than folded
  /// into [ttsEnabled] since a user might want synthesized speech but not
  /// the network-fetched pitch-accent clips, or vice versa.
  BoolColumn get pitchAccentAudioEnabled => boolean()
      .withDefault(const Constant(false))
      .named('pitch_accent_audio_enabled')();

  /// Spec §13 sync-readiness (added by the schemaVersion 5->6 audit, see
  /// this file's own top-of-file note): this single row is genuinely
  /// mutable user state with no `updatedAt` until now. Nullable because a
  /// pre-migration row has no real value yet -- `SettingsRepository.update`
  /// sets a real one on every write from here on, same as `uuid` on the
  /// sighting tables below.
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();

  /// The document-wide mined-word highlight color (word-highlighting
  /// feature), stored as an ARGB `Color.toARGB32()` int. Nullable: null
  /// means "use `defaultHighlightColor`," same null-means-default pattern
  /// as every other column here rather than needing a separate
  /// has-the-user-customized-this flag.
  IntColumn get highlightColorValue =>
      integer().nullable().named('highlight_color_value')();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per cached LLM grammar explanation (spec §8 layer 3: "cached
/// permanently by sentence hash so it's paid for once"), keyed by
/// [contentDerivedExplanationId] (`core/ids/stable_id.dart`) -- a hash of the
/// sentence's own text *and* its surrounding context, not the position-
/// derived `Sentence.id`: the explanation depends on what was actually said,
/// not where it appears, so identical text+context in two different books
/// (or two editions of the same one) shares one cached call. Never updated
/// after insert -- a cache hit is a straight primary-key read, and there's
/// nothing to reconcile since the same key always implies the same prompt.
@DataClassName('SentenceExplanationRow')
class SentenceExplanations extends Table {
  TextColumn get id => text()();
  TextColumn get explanation => text()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per calendar day (UTC midnight) that had any active reading time
/// -- spec §15's "reading streak / heatmap" and "time read". Written to by
/// `ReadingTimeTracker` (`lib/l3_reader_ui/reading_time_tracker.dart`),
/// which accumulates elapsed time while a reader screen is open and
/// periodically flushes it here, rather than every screen tick writing its
/// own row. A day with no reading simply has no row (not a zero row) --
/// streak/heatmap queries treat "missing" and "zero" identically, so this
/// avoids writing a row for every day the app was never opened.
@DataClassName('ReadingActivityRow')
class ReadingActivity extends Table {
  DateTimeColumn get date => dateTime()();
  IntColumn get secondsRead =>
      integer().withDefault(const Constant(0)).named('seconds_read')();

  @override
  Set<Column> get primaryKey => {date};
}
