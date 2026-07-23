# R5 — Dictionary Import: Yomitan Schema + Storage Design

**Status:** Research spike only. Nothing in this doc is wired into `lib/`. Written to
de-risk the L2 dictionary-import work described in spec §10 before a future pass
implements it. All Dart snippets below are sketches for review, not compiled/tested code.

Sources checked directly (raw GitHub, not secondhand): the `yomidevs/yomitan` repo
(the actively-maintained fork of Yomichan/Yomitan; the older `themoeway/yomitan` and
`FooSoft/yomichan` names redirect/are stale mirrors of the same lineage), specifically
`ext/data/schemas/dictionary-*-v3-schema.json`, `docs/making-yomitan-dictionaries.md`,
and the live `test/data/dictionaries/valid-dictionary1` fixture used by Yomitan's own
test suite (fetched and cross-checked against the schema files, not just described).

---

## 1. Confirmed Yomitan v3 schema

A Yomitan dictionary is a **zip with all JSON files at the zip root** (not in a
subfolder — confirmed in `making-yomitan-dictionaries.md`). Filenames follow
`{bank_type}_bank_{n}.json`, 1-indexed, split arbitrarily across multiple files for
large dictionaries (no documented max entries/file). Confirmed files:

| File | Required | Purpose |
|---|---|---|
| `index.json` | yes | dictionary metadata |
| `term_bank_N.json` | yes (for a word dictionary) | headword → reading/definitions |
| `term_meta_bank_N.json` | no | frequency / pitch-accent / IPA data, keyed by term |
| `tag_bank_N.json` | no | tag display names/categories referenced by term/kanji entries |
| `kanji_bank_N.json` | no | per-kanji readings/meanings (KANJIDIC-style) |
| `kanji_meta_bank_N.json` | no | per-kanji frequency data |
| `styles.css` | no | custom popup styling |

### `index.json` (object)

Required: `title` (string), `revision` (string, opaque version stamp shown to user
and used for update checks). Either `format` or `version` (aliased, both `enum [1,2,3]`)
must be present — **we only need to support 3**, per spec's Yomitan-as-anchor framing;
older format 1/2 dictionaries are rare in the wild now and can be a later fallback.
Also: `author`, `url`, `description`, `attribution`, `sourceLanguage`/`targetLanguage`
(ISO codes), `sequenced` (bool — whether term entries carry meaningful sequence
numbers for "merge" display), `frequencyMode` (`"occurrence-based"` \| `"rank-based"`
— affects how a frequency number should be interpreted/displayed), `isUpdatable` +
`indexUrl`/`downloadUrl` (self-update metadata, irrelevant to us since we're not
auto-updating installed dictionaries), and an obsolete `tagMeta` (superseded by
`tag_bank`).

### `term_bank_N.json` — array of fixed **8-element arrays** (`minItems`/`maxItems: 8`)

This is the entry point for lookup. Field order, confirmed from the schema's `items`
array (not just prose docs, which sometimes lag):

| # | Field | Type | Meaning |
|---|---|---|---|
| 0 | term | string | headword (dictionary/kanji form, e.g. 打つ) |
| 1 | reading | string | kana reading; **empty string means "same as term"** — must normalize at import time, don't leave it empty in the lookup index |
| 2 | definition tags | string \| null | space-separated tag names (→ `tag_bank`), scoped to this definition |
| 3 | rules | string | space-separated deinflection rule identifiers (e.g. `v5`, `vk`, `adj-i`); empty for uninflectable words. **This is the field a deconjugation retry must validate candidates against** — see §3. |
| 4 | score | number | popularity; negative=rarer, positive=commoner; also the intra-dictionary sort key |
| 5 | definitions | array | see below |
| 6 | sequence | integer | groups entries for `resultOutputMode: "merge"` display |
| 7 | term tags | string | space-separated tag names for the term itself (not a specific sense) |

Definitions (field 5) are heterogeneous — each array item is `oneOf`:
- a plain **string** (simple gloss),
- `{type: "text", text}`,
- `{type: "image", path, width, height, alt, title, description, ...}` (image bundled in the zip),
- `{type: "structured-content", content}` — recursive HTML-like tree (`div`, `span`,
  `ruby`/`rt`/`rp`, `table*`, `img`, links, inline `data-*` attributes, `style` objects).
  This is what monolingual dictionaries (新明解 etc.) typically use for richly
  formatted entries. Rendering this tree is real work — **treat it as opaque JSON at
  storage time**; a renderer is L2/L3 UI work, not a storage concern.
- a 2-tuple `[uninflectedTerm, ruleChain[]]` — a "this sense is itself an inflected
  form of X" cross-reference. Distinct from field 3; don't conflate the two.

### `term_meta_bank_N.json` — array of fixed **3-element arrays**

`[term: string, mode: "freq"|"pitch"|"ipa", data: <mode-specific>]`. Confirmed shapes:

- **`freq`**: `data` is either a bare `string|number`, `{value: number, displayValue?: string}`,
  or `{reading: string, frequency: <one of the previous two>}` when the frequency is
  reading-specific (a dictionary can give one frequency for 生物 read せいぶつ and a
  different one for なまもの).
- **`pitch`**: `data` is `{reading: string, pitches: [{position, nasal?, devoice?, tags?}]}`.
  `position` is either an integer mora index of the downstep (0 = 平板/heiban) **or** a
  string pattern `^[HL]+$` giving the full high/low mora pattern directly. `nasal`/
  `devoice` are mora positions (int or int[]) for pronunciation nuance; `tags` are
  usually POS qualifiers (a word can have different pitch per part of speech).
- **`ipa`**: `data` is `{reading: string, transcriptions: [{ipa: string, tags?: string[]}]}`.

### `tag_bank_N.json` — array of fixed **5-element arrays**

`[name, category, order: number, notes, score: number]`. Purely display metadata —
resolved against a term's `definitionTags`/`termTags` strings at render time.

### `kanji_bank_N.json` / `kanji_meta_bank_N.json`

Confirmed but not detailed here since spec §10's lookup path (word popup) doesn't need
them yet: kanji entries are 6-tuples `[kanji, onyomi, kunyomi, tags, meanings[], stats{}]`.
Same storage pattern as terms would apply (own table, `dictionaryId` FK) when kanji-dictionary
support is actually built — not designed further in this pass.

**Raw schema files** (draft-07 JSON Schema, useful to vendor a copy of for validation
later): `ext/data/schemas/dictionary-{index,term-bank-v3,term-meta-bank-v3,tag-bank-v3,kanji-bank-v3,kanji-meta-bank-v3}-schema.json`
in `yomidevs/yomitan`.

---

## 2. Drift table sketch

Mirrors this repo's existing conventions in `lib/core/db/tables.dart` (text UUID PKs
+ `updatedAt` for sync-ready rows per spec §13; `references()` for FKs). **Dictionary
content itself does *not* get the UUID/updatedAt sync treatment** — spec §13 says
dictionaries/OCR caches are "local-only (large, regenerable, not worth syncing)" — so
`DictionaryTerms`/`DictionaryTermMeta`/`DictionaryTags` use plain autoincrement ints.
The `Dictionaries` row (the install record + user's priority ordering) is small,
user-authored state, not regenerable, so it *does* get the sync-ready treatment.

```dart
import 'package:drift/drift.dart';

/// One row per installed dictionary (from index.json + import bookkeeping).
/// Sync-ready (spec §13): this is small user state (which dictionaries + what
/// order), not the bulk data, which is why it gets id/updatedAt but the term
/// tables below don't.
class Dictionaries extends Table {
  TextColumn get id => text()();                 // uuid, generated at import
  TextColumn get title => text()();               // index.json: title
  TextColumn get revision => text()();            // index.json: revision
  IntColumn get formatVersion => integer()();     // index.json: format|version (1/2/3)
  TextColumn get author => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get attribution => text().nullable()();
  TextColumn get sourceLanguage => text().nullable()();
  TextColumn get targetLanguage => text().nullable()();
  TextColumn get frequencyMode => text().nullable()(); // 'occurrence-based'|'rank-based'
  BoolColumn get sequenced => boolean().withDefault(const Constant(false))();

  /// User-ordered priority. Lower = higher priority = preferred for the
  /// popup's default definition. Reorderable in Settings (spec §14); dense
  /// (0..N-1), reassigned on every reorder rather than left sparse, since the
  /// dictionary count is small (tens, not thousands) and a full renumber on
  /// drag-reorder is cheap and keeps queries simple (no gap-management logic).
  IntColumn get priority => integer()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  DateTimeColumn get importedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tag display metadata from tag_bank_N.json. Scoped per-dictionary because
/// two dictionaries can define a tag with the same name and different
/// category/notes (e.g. both ship a tag literally named "n").
class DictionaryTagEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dictionaryId => text().references(Dictionaries, #id)();
  TextColumn get name => text()();
  TextColumn get category => text()();
  IntColumn get sortOrder => integer().named('sort_order')(); // schema field: "order" (reserved word)
  TextColumn get notes => text()();
  RealColumn get score => real()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {dictionaryId, name},
  ];
}

/// Flattened term_bank_N.json entries. One row per source 8-tuple. This is
/// the core lookup table — headword/reading are indexed for the tier-1/tier-2
/// lookup in §3; `rules` is what the tier-3 deconjugation retry validates
/// candidates against.
class DictionaryTermEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dictionaryId => text().references(Dictionaries, #id)();

  TextColumn get headword => text()();      // term_bank[0]
  TextColumn get reading => text()();       // term_bank[1], RAW (may be '')

  /// Normalized at import time: reading.isEmpty ? headword : reading.
  /// Exists so lookup queries never special-case the empty-reading rule —
  /// every row has a real, non-empty reading to match against.
  TextColumn get readingNormalized => text().named('reading_normalized')();

  TextColumn get definitionTags => text().nullable().named('definition_tags')(); // [2]
  TextColumn get rules => text()();          // term_bank[3], space-separated, '' if uninflectable
  RealColumn get score => real()();          // term_bank[4] — schema says "number", not integer
  TextColumn get definitionsJson => text().named('definitions_json')(); // term_bank[5], stored opaque (see §1)
  IntColumn get sequence => integer()();     // term_bank[6]
  TextColumn get termTags => text().named('term_tags')(); // term_bank[7]

  /// Original position within its source bank file. Yomitan preserves file
  /// order as a secondary sort key when scores tie; we do the same so
  /// results are deterministic and match what the dictionary author intended.
  IntColumn get importOrder => integer().named('import_order')();

  @override
  List<Set<Column>> get uniqueKeys => [];
}

/// Frequency/pitch/IPA data from term_meta_bank_N.json. The three modes'
/// payloads are genuinely different shapes (see §1) — rather than force them
/// into shared flat columns, store the mode-specific payload as JSON and
/// pull `reading` out as its own nullable column (present for pitch/ipa
/// always, present for freq only when the entry is reading-specific) so
/// reading-scoped queries don't have to parse JSON to filter.
class DictionaryTermMetaEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dictionaryId => text().references(Dictionaries, #id)();

  TextColumn get headword => text()();       // term_meta_bank[0]
  TextColumn get mode => text()();           // term_meta_bank[1]: 'freq'|'pitch'|'ipa'
  TextColumn get reading => text().nullable()(); // pulled from payload; null = applies to all readings
  TextColumn get dataJson => text().named('data_json')(); // full mode-specific payload, verbatim
}

/// Indexes (declared via Drift's `@TableIndex` or a migration's raw SQL —
/// sketch shows intent, not exact Drift syntax):
///  - DictionaryTermEntries(headword)
///  - DictionaryTermEntries(reading_normalized)
///  - DictionaryTermEntries(dictionary_id, sequence)   -- for "merge" grouping
///  - DictionaryTermMetaEntries(dictionary_id, headword, mode)
```

**Why headword and reading get *separate* single-column indexes rather than one
composite `(headword, reading)` index:** the tier-1/2 lookup (§3) queries
`WHERE headword = ? OR reading_normalized = ?` — Sudachi's dictionary form is always
matched against `headword`, but a token can also legitimately be looked up by its
*reading* alone (kana-only input, or a headword variant the dictionary didn't list).
**SQLite does not reliably use two separate indexes to satisfy one `OR`-ed `WHERE`
clause** the way Postgres's bitmap-or can — the safe, index-friendly rewrite is a
`UNION` of two independently-indexed queries rather than a single `OR`. Worth calling
out explicitly now so the L2 implementer doesn't write the natural-looking `OR` query,
get correct-but-slow results on a large dictionary, and have to rediscover this.

**FTS5 caveat (spec §2 calls for FTS5; don't assume it slots into the Dart tables
above):** Drift **cannot declare FTS5 virtual tables in Dart** — only in a `.drift`
file using raw `CREATE VIRTUAL TABLE ... USING fts5(...)`, with `fts5` also enabled
in `build.yaml`'s `drift_dev` → `sqlite_module` options (not currently configured in
this repo's `build.yaml`, which today only configures `json_serializable`). Practical
implication: the tap-to-lookup exact-match path in §3 should **not** go through FTS5
at all — it's a plain indexed-equality problem, and FTS5 would be slower and more
complex for it. FTS5 earns its keep for a *different*, not-yet-designed feature: a
manual "search the dictionary" box doing prefix/substring search over headword +
reading + flattened definition text. That would be a `DictionaryTermsFts` external-content
table declared in a `.drift` file, content-synced to `DictionaryTermEntries.id` — left
as a pointer for whoever builds that feature, not designed further here since spec
§10 doesn't ask for it explicitly (only the popup's tap-driven lookup does).

---

## 3. Lookup strategy: dictionary-form → surface-form → deconjugation

Spec §10: "Lookup keys on the dictionary form from Sudachi, with fallback to surface
form and a deconjugation retry." Two design decisions worth making explicit now,
since they're easy to get wrong silently:

1. **The three tiers are about progressively loosening the *match key*, not about
   which dictionary to consult.** Every tier, once it produces any hit, gathers
   matches across **all enabled dictionaries** (merged, then sorted by dictionary
   priority then in-dictionary score) — it does not stop at the first dictionary
   with a hit. This is required by spec §10's popup design: the default fields come
   from the top-priority dictionary, but "other installed dictionaries' entries...
   are available to add as further optional fields," which means the lookup must
   have already fetched every enabled dictionary's entry for that key, not just the
   winner's.
2. **Tier 3 (deconjugation) must validate candidates against a term's `rules` field**
   (term_bank[3]), not just string-match the deinflected candidate term. A rule-based
   deinflector (porting Yomitan's own `deinflect.json` reason chains is the obvious
   path — same rule identifiers like `v5`/`vk`/`adj-i` appear in both) produces
   `(candidateTerm, ruleChain)` pairs; a candidate is only accepted if some rule in
   its chain appears in a matched entry's `rules` string. Otherwise a deinflector
   will happily "un-conjugate" unrelated words that merely share a suffix.

```dart
class DictionaryLookupHit {
  DictionaryLookupHit({
    required this.term,
    required this.dictionaryTitle,
    required this.dictionaryPriority,
    required this.matchedVia,
  });

  final DictionaryTermEntry term; // generated Drift row class
  final String dictionaryTitle;
  final int dictionaryPriority;
  final MatchTier matchedVia;
}

enum MatchTier { dictionaryForm, surfaceForm, deconjugation }

class DictionaryRepository {
  DictionaryRepository(this._db);
  final AppDatabase _db;

  /// Implements spec §10's fallback chain. [dictForm]/[reading] come from
  /// Sudachi's analysis of the tapped token; [surfaceForm] is the as-written
  /// text (used as typed if Sudachi's dict form lookup misses, and as the
  /// input to deconjugation — also the only thing available at all when the
  /// user drag-selects an arbitrary span that Sudachi never tokenized).
  Future<List<DictionaryLookupHit>> lookup({
    required String dictForm,
    required String surfaceForm,
    String? reading,
  }) async {
    var hits = await _queryAllEnabled(headword: dictForm, reading: reading);
    if (hits.isNotEmpty) return _sortByPriority(hits, MatchTier.dictionaryForm);

    if (surfaceForm != dictForm) {
      hits = await _queryAllEnabled(headword: surfaceForm, reading: reading);
      if (hits.isNotEmpty) return _sortByPriority(hits, MatchTier.surfaceForm);
    }

    for (final candidate in Deinflector.deinflect(surfaceForm)) {
      final candidateHits = await _queryAllEnabled(headword: candidate.term, reading: null);
      final validated = candidateHits.where(
        (h) => candidate.rules.any((rule) => h.term.rules.split(' ').contains(rule)),
      );
      if (validated.isNotEmpty) {
        return _sortByPriority(validated.toList(), MatchTier.deconjugation);
      }
    }

    return const [];
  }

  /// UNION, not OR — see the indexing note in §2. Only rows whose owning
  /// dictionary is `enabled` are considered; priority ordering is applied by
  /// the caller (_sortByPriority), not baked into this query, so a disabled
  /// dictionary's entries are excluded but priority is a pure sort, not a filter.
  Future<List<DictionaryTermEntry>> _queryAllEnabled({
    required String headword,
    required String? reading,
  }) async {
    final byHeadword = _db.select(_db.dictionaryTermEntries).join([
      innerJoin(_db.dictionaries, _db.dictionaries.id.equalsExp(_db.dictionaryTermEntries.dictionaryId)),
    ])
      ..where(_db.dictionaryTermEntries.headword.equals(headword))
      ..where(_db.dictionaries.enabled.equals(true));

    if (reading == null) {
      return (await byHeadword.get()).map((r) => r.readTable(_db.dictionaryTermEntries)).toList();
    }

    final byReading = _db.select(_db.dictionaryTermEntries).join([
      innerJoin(_db.dictionaries, _db.dictionaries.id.equalsExp(_db.dictionaryTermEntries.dictionaryId)),
    ])
      ..where(_db.dictionaryTermEntries.readingNormalized.equals(reading))
      ..where(_db.dictionaries.enabled.equals(true));

    final headwordRows = await byHeadword.get();
    final readingRows = await byReading.get();
    final seen = <int>{};
    return [...headwordRows, ...readingRows]
        .map((r) => r.readTable(_db.dictionaryTermEntries))
        .where((t) => seen.add(t.id)); // de-dupe entries matched by both
  }

  List<DictionaryLookupHit> _sortByPriority(List<DictionaryTermEntry> terms, MatchTier tier) {
    // join back to Dictionaries for (priority, title); sort by
    // (dictionary.priority asc, term.score desc, term.importOrder asc).
    throw UnimplementedError('sketch only');
  }
}
```

Batching note (import performance, not lookup): a converted JMdict-based dictionary
is ~170k+ term entries. Insert via `_db.batch()` in chunks (a few thousand rows per
batch), not row-by-row — this matters enough to flag now since it's an easy thing to
get naively slow on first implementation, especially on lower-end Android devices.

---

## 4. `package:archive` suitability for unzipping

**Discrepancy from the task brief:** this repo's `pubspec.yaml`/`pubspec.lock` does
**not** currently list `package:archive` (confirmed via grep — no `archive:` entry in
either file, and no `.dart` file imports it). The brief said it was "already added for
other reasons"; that isn't true of this repo's current state. Per this task's
constraints I have not touched `pubspec.yaml` — flagging so whoever picks up L2 adds
`archive: ^4.0.9` (current stable, pub.dev) themselves rather than assuming it's there.

The package itself is suitable regardless. Confirmed from its README (`brendan-duncan/archive`):

- **In-memory** (fine for small-to-medium dictionaries — the sample fixture in §5 is
  ~78KB uncompressed):
  ```dart
  import 'package:archive/archive.dart';
  import 'dart:io';

  final bytes = await File(zipPath).readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);
  for (final file in archive.files) {
    if (file.isFile) {
      final name = file.name;          // e.g. 'term_bank_1.json'
      final data = file.readBytes();   // Uint8List? (bytes of that entry)
    }
  }
  ```
- **Streaming** (worth using by default rather than only for "big" dictionaries —
  JMdict-derived or monolingual dictionaries commonly run tens of MB, and this is a
  mobile app):
  ```dart
  import 'package:archive/archive_io.dart';
  import 'package:archive/archive.dart';

  final input = InputFileStream(zipPath);
  final archive = ZipDecoder().decodeStream(input);
  // per-entry: entry.writeContent(outputStream) decompresses straight to
  // disk without buffering the whole decompressed entry in memory.
  ```
  Given Yomitan zips are plain JSON text (not media), the practical approach is
  probably: stream-decode, but still materialize each individual `term_bank_N.json`'s
  bytes fully (they're one JSON array — no incremental JSON parser is in play here)
  before `jsonDecode`-ing and batch-inserting it, then discard and move to the next
  file. That avoids holding the *whole zip* in memory at once without requiring a
  streaming JSON parser, which is a reasonable middle ground.

No blockers found. Version note: pub.dev's current stable is **4.0.9**; the package
had a significant v3→v4 API reshape around file I/O (the `decodeStream`/`InputFileStream`
streaming path is the v4 idiom) — pin to `^4.0.9`, not an older major, if/when added.

---

## 5. Sample dictionary for later import-testing

Yomitan's own test suite fixture is a strong candidate — small, schema-valid (format
3), and exercises every bank type in one place:

**`test/data/dictionaries/valid-dictionary1`** in `yomidevs/yomitan`
(https://github.com/yomidevs/yomitan/tree/master/test/data/dictionaries/valid-dictionary1)

Confirmed contents (fetched directly, not assumed):
`index.json` (99 B, `format: 3`, `sequenced: true`), `term_bank_1.json` (23.5 KB),
`term_bank_2.json` (45.7 KB), `term_meta_bank_1.json` (4.8 KB, exercises freq/pitch),
`tag_bank_{1,2,3}.json` (3 files, 280–339 B each), `kanji_bank_1.json` (1.0 KB),
`kanji_meta_bank_1.json` (207 B), `styles.css` (54 B), plus a handful of small
`.png`/`.gif` images referenced by structured-content image definitions — so it also
exercises the "image bundled in the zip" definition type. Verified a snippet of
`term_bank_1.json` live; entries are real 8-tuples like
`["打つ", "うつ", "vt", "v5", 10, ["utsu definition 1", "utsu definition 2"], 3, "P E1"]`,
i.e. directly schema-conformant.

It is **not pre-zipped** in the repo (it's loose files under that test directory) —
whoever uses it for import testing zips the folder contents at its root (not the
folder itself, per §1's "root of the zip" rule) with any standard zip tool. Total
size guarantees a trivial, fast test fixture rather than needing to download a
100k-entry real dictionary just to exercise the importer.

Also present, for later negative-path/error-handling test coverage:
`test/data/dictionaries/invalid-dictionary{1..6}` in the same repo — malformed
fixtures Yomitan's own importer test suite uses to verify rejection behavior. Not
inspected in detail this pass; noting they exist since they'd save time writing
"does the importer reject a bad zip gracefully" tests later.

---

## 6. Open questions for whoever builds L2 (not resolved here)

- Structured-content rendering (recursive tag tree → Flutter widgets) is nontrivial
  UI work and entirely unaddressed by this storage design on purpose — storage keeps
  it as opaque JSON; rendering is a separate spike-worthy problem.
- The deinflector itself (rule table + reason chains) isn't designed here — only the
  point where its output plugs into the lookup (`rules` field validation). Porting
  Yomitan's `deinflect.json` directly is the obvious starting point and should be
  checked against license compatibility (Yomitan is that GPL-3.0 lineage per this
  project's existing MajdataPlay integration precedent — worth a license check before
  porting data files verbatim, not just code).
- Migration/versioning story for re-importing an updated revision of an already-installed
  dictionary (replace all rows for that `dictionaryId`, or diff) isn't designed here.
