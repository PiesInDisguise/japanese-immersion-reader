import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/core/ids/stable_id.dart';

import 'yomitan_schema.dart';

/// Progress phases for [DictionaryImporter.import]. Deliberately distinct
/// from L1's `ImportStage`/`ImportProgress`
/// (lib/l1_ingestion/importer.dart): those describe building a `Document`
/// (chapters, OCR, ...) and that interface's `import` returns a `Document`,
/// which has no meaning for a dictionary import -- this is a separate,
/// smaller vocabulary scoped to L2's own concern.
enum DictionaryImportStage { unzipping, parsing, writing, done }

class DictionaryImportProgress {
  const DictionaryImportProgress({required this.stage, required this.fraction});

  final DictionaryImportStage stage;

  /// 0.0-1.0.
  final double fraction;
}

void _noopProgress(DictionaryImportProgress progress) {}

/// Rows per `db.batch()` insert. See docs/research/r5-dictionary.md §3's
/// batching note: a JMdict-derived dictionary is ~170k+ term entries, and
/// inserting row-by-row is an easy, naive-first-implementation performance
/// trap worth heading off up front rather than discovering later.
const _insertBatchSize = 2000;

/// Imports a Yomitan v3 dictionary ZIP (spec §10) into the shared
/// `AppDatabase`: unzips in memory, parses `index.json` plus every
/// `term_bank_N.json` / `term_meta_bank_N.json` / `tag_bank_N.json` file
/// present, and batch-writes the result into `Dictionaries` +
/// `DictionaryTermEntries` + `DictionaryTermMetaEntries` +
/// `DictionaryTagEntries`.
///
/// **Format 3 only.** `index.json`'s `format`/`version` must be `3` --
/// format 1/2 dictionaries are rejected with a clear [FormatException]
/// rather than mis-parsed, since their bank shapes differ (see
/// docs/research/r5-dictionary.md §1: "we only need to support 3... older
/// format 1/2 dictionaries are rare... a later fallback").
///
/// **`kanji_bank`/`kanji_meta_bank`/`styles.css`/images are ignored.**
/// Kanji-dictionary support isn't designed yet (R5 §1), and
/// structured-content image references are stored as opaque JSON without
/// resolving the actual image bytes (rendering is separate, later UI work)
/// -- this importer only looks for `index.json` and the three bank types it
/// stores; anything else in the zip is silently skipped, which also keeps
/// this forward-compatible with dictionaries that ship files this importer
/// doesn't understand yet.
///
/// **Not currently streamed.** Mirrors `EpubImporter`'s existing precedent:
/// the whole zip is read into memory and decoded via
/// `ZipDecoder.decodeBytes` rather than `package:archive`'s streaming
/// `InputFileStream` path. Fine for small-to-medium dictionaries; a
/// multi-tens-of-MB monolingual dictionary would hold more in memory at
/// once than strictly necessary. Flagged as a known limitation rather than
/// solved here -- see docs/research/r5-dictionary.md §4 for the streaming
/// approach that would address it, left for whoever needs it.
///
/// **Re-importing the same dictionary.** [Dictionaries.id] is
/// content-derived from `index.json`'s title/revision/format
/// (`contentDerivedDictionaryId`), so re-importing the same release
/// replaces that dictionary's rows in place rather than creating a
/// duplicate -- see [_writeToDatabase]'s doc comment for exactly what
/// is/isn't preserved across a re-import.
///
/// **Single transaction.** The whole write (metadata + all rows) commits or
/// rolls back together, so a failure partway through never leaves a
/// half-imported dictionary visible to lookup.
///
/// **Runs on the calling isolate.** Unlike `ScannedPdfImporter` (which
/// isolates real OCR compute), this importer does its JSON parsing and DB
/// writes as plain awaited async calls on the caller's isolate/zone, same
/// as `EpubImporter`. JSON-decoding and batch-inserting 100k+ rows is real
/// work but far lighter than OCR; moving it to a worker isolate would also
/// need a way to hand a *second* connection to the same on-disk database
/// across isolates, which isn't attempted here.
class DictionaryImporter {
  DictionaryImporter(this._db);

  final AppDatabase _db;

  static const _unzipEnd = 0.05;
  static const _parseEnd = 0.4;
  static const _writeEnd = 0.95;

  /// Imports [zipFile], returning the resulting [Dictionaries.id].
  Future<String> import(
    File zipFile, {
    void Function(DictionaryImportProgress progress) onProgress = _noopProgress,
  }) async {
    onProgress(
      const DictionaryImportProgress(
        stage: DictionaryImportStage.unzipping,
        fraction: 0.0,
      ),
    );
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final filesByName = <String, ArchiveFile>{
      for (final file in archive.files)
        if (file.isFile) file.name: file,
    };
    onProgress(
      const DictionaryImportProgress(
        stage: DictionaryImportStage.unzipping,
        fraction: _unzipEnd,
      ),
    );

    final indexFile = filesByName['index.json'];
    if (indexFile == null) {
      throw const FormatException(
        'Yomitan dictionary zip is missing index.json at the zip root',
      );
    }
    final index = YomitanIndex.fromJson(_decodeJsonObject(indexFile));
    if (index.formatVersion != 3) {
      throw FormatException(
        'Unsupported Yomitan dictionary format ${index.formatVersion} '
        '(only format 3 is supported)',
      );
    }
    final dictionaryId = contentDerivedDictionaryId(
      title: index.title,
      revision: index.revision,
      formatVersion: index.formatVersion,
    );

    final termEntries = <YomitanTermEntry>[
      for (final name in _sortedBankFiles(filesByName.keys, 'term_bank'))
        ..._decodeTuples(filesByName[name]!).map(YomitanTermEntry.fromTuple),
    ];
    onProgress(
      DictionaryImportProgress(
        stage: DictionaryImportStage.parsing,
        fraction: _unzipEnd + (_parseEnd - _unzipEnd) / 3,
      ),
    );

    final termMetaEntries = <YomitanTermMetaEntry>[
      for (final name in _sortedBankFiles(filesByName.keys, 'term_meta_bank'))
        ..._decodeTuples(
          filesByName[name]!,
        ).map(YomitanTermMetaEntry.fromTuple),
    ];
    onProgress(
      DictionaryImportProgress(
        stage: DictionaryImportStage.parsing,
        fraction: _unzipEnd + (_parseEnd - _unzipEnd) * 2 / 3,
      ),
    );

    final tagEntries = <YomitanTagEntry>[
      for (final name in _sortedBankFiles(filesByName.keys, 'tag_bank'))
        ..._decodeTuples(filesByName[name]!).map(YomitanTagEntry.fromTuple),
    ];
    onProgress(
      const DictionaryImportProgress(
        stage: DictionaryImportStage.parsing,
        fraction: _parseEnd,
      ),
    );

    await _writeToDatabase(
      dictionaryId: dictionaryId,
      index: index,
      termEntries: termEntries,
      termMetaEntries: termMetaEntries,
      tagEntries: tagEntries,
      onProgress: onProgress,
    );

    onProgress(
      const DictionaryImportProgress(
        stage: DictionaryImportStage.done,
        fraction: 1.0,
      ),
    );
    return dictionaryId;
  }

  /// Writes (or replaces) one dictionary's rows inside a single transaction.
  ///
  /// **Re-import behavior.** If [dictionaryId] already has a `Dictionaries`
  /// row (this exact title+revision+format was imported before), its
  /// declared metadata (title/description/author/...) is refreshed and
  /// `updatedAt` bumped, but `priority` and `enabled` are deliberately left
  /// untouched -- re-importing must not silently reset a dictionary's
  /// position in the user's ordering or re-enable one they'd turned off.
  /// All of that dictionary's existing term/term-meta/tag rows are deleted
  /// and re-inserted from scratch (a full replace, not a diff) --
  /// docs/research/r5-dictionary.md §6 leaves diffing a re-imported
  /// revision as an open question; a full replace is the simple,
  /// correct-if-blunt behavior adopted here.
  ///
  /// A brand-new dictionary is inserted with `enabled: true` and the next
  /// free `priority` (existing max + 1, or 0 if this is the first
  /// dictionary installed), matching `Dictionaries.priority`'s "dense,
  /// 0..N-1" convention.
  Future<void> _writeToDatabase({
    required String dictionaryId,
    required YomitanIndex index,
    required List<YomitanTermEntry> termEntries,
    required List<YomitanTermMetaEntry> termMetaEntries,
    required List<YomitanTagEntry> tagEntries,
    required void Function(DictionaryImportProgress progress) onProgress,
  }) async {
    final now = DateTime.now().toUtc();

    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.dictionaries,
      )..where((d) => d.id.equals(dictionaryId))).getSingleOrNull();

      if (existing == null) {
        final nextPriority = await _nextPriority();
        await _db
            .into(_db.dictionaries)
            .insert(
              DictionariesCompanion.insert(
                id: dictionaryId,
                title: index.title,
                revision: index.revision,
                formatVersion: index.formatVersion,
                author: Value(index.author),
                url: Value(index.url),
                description: Value(index.description),
                attribution: Value(index.attribution),
                sourceLanguage: Value(index.sourceLanguage),
                targetLanguage: Value(index.targetLanguage),
                frequencyMode: Value(index.frequencyMode),
                sequenced: Value(index.sequenced),
                priority: nextPriority,
                enabled: const Value(true),
                addedAt: now,
                updatedAt: now,
              ),
            );
      } else {
        await (_db.update(
          _db.dictionaries,
        )..where((d) => d.id.equals(dictionaryId))).write(
          DictionariesCompanion(
            title: Value(index.title),
            revision: Value(index.revision),
            formatVersion: Value(index.formatVersion),
            author: Value(index.author),
            url: Value(index.url),
            description: Value(index.description),
            attribution: Value(index.attribution),
            sourceLanguage: Value(index.sourceLanguage),
            targetLanguage: Value(index.targetLanguage),
            frequencyMode: Value(index.frequencyMode),
            sequenced: Value(index.sequenced),
            updatedAt: Value(now),
          ),
        );
        await (_db.delete(
          _db.dictionaryTermEntries,
        )..where((t) => t.dictionaryId.equals(dictionaryId))).go();
        await (_db.delete(
          _db.dictionaryTermMetaEntries,
        )..where((t) => t.dictionaryId.equals(dictionaryId))).go();
        await (_db.delete(
          _db.dictionaryTagEntries,
        )..where((t) => t.dictionaryId.equals(dictionaryId))).go();
      }

      final totalRows =
          termEntries.length + termMetaEntries.length + tagEntries.length;
      var rowsWritten = 0;

      void reportWriteProgress() {
        final within = totalRows == 0 ? 1.0 : rowsWritten / totalRows;
        onProgress(
          DictionaryImportProgress(
            stage: DictionaryImportStage.writing,
            fraction: _parseEnd + (_writeEnd - _parseEnd) * within,
          ),
        );
      }

      for (final chunk in _chunksOf(termEntries, _insertBatchSize)) {
        await _db.batch((batch) {
          batch.insertAll(_db.dictionaryTermEntries, [
            for (var i = 0; i < chunk.rows.length; i++)
              _termEntryCompanion(
                dictionaryId,
                chunk.rows[i],
                chunk.startIndex + i,
              ),
          ]);
        });
        rowsWritten += chunk.rows.length;
        reportWriteProgress();
      }

      for (final chunk in _chunksOf(termMetaEntries, _insertBatchSize)) {
        await _db.batch((batch) {
          batch.insertAll(_db.dictionaryTermMetaEntries, [
            for (final entry in chunk.rows)
              _termMetaEntryCompanion(dictionaryId, entry),
          ]);
        });
        rowsWritten += chunk.rows.length;
        reportWriteProgress();
      }

      for (final chunk in _chunksOf(tagEntries, _insertBatchSize)) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.dictionaryTagEntries,
            [
              for (final entry in chunk.rows)
                _tagEntryCompanion(dictionaryId, entry),
            ],
            // A tag legitimately re-declared across multiple tag_bank_N.json
            // files (the same name+category shipped twice) must not abort
            // the whole import -- see DictionaryTagEntries' unique
            // (dictionaryId, name) key.
            mode: InsertMode.insertOrReplace,
          );
        });
        rowsWritten += chunk.rows.length;
        reportWriteProgress();
      }
    });
  }

  Future<int> _nextPriority() async {
    final rows = await _db.select(_db.dictionaries).get();
    if (rows.isEmpty) return 0;
    final maxPriority = rows
        .map((d) => d.priority)
        .reduce((a, b) => a > b ? a : b);
    return maxPriority + 1;
  }

  DictionaryTermEntriesCompanion _termEntryCompanion(
    String dictionaryId,
    YomitanTermEntry entry,
    int importOrder,
  ) {
    return DictionaryTermEntriesCompanion.insert(
      dictionaryId: dictionaryId,
      headword: entry.term,
      reading: entry.reading,
      readingNormalized: entry.readingNormalized,
      definitionTags: Value(entry.definitionTags),
      rules: entry.rules,
      score: entry.score,
      definitionsJson: jsonEncode(entry.definitions),
      sequence: entry.sequence,
      termTags: entry.termTags,
      importOrder: importOrder,
    );
  }

  DictionaryTermMetaEntriesCompanion _termMetaEntryCompanion(
    String dictionaryId,
    YomitanTermMetaEntry entry,
  ) {
    return DictionaryTermMetaEntriesCompanion.insert(
      dictionaryId: dictionaryId,
      headword: entry.term,
      mode: entry.mode.name,
      reading: Value(entry.readingForIndex),
      dataJson: jsonEncode(entry.data),
    );
  }

  DictionaryTagEntriesCompanion _tagEntryCompanion(
    String dictionaryId,
    YomitanTagEntry entry,
  ) {
    return DictionaryTagEntriesCompanion.insert(
      dictionaryId: dictionaryId,
      name: entry.name,
      category: entry.category,
      sortOrder: entry.order,
      notes: entry.notes,
      score: entry.score,
    );
  }
}

Map<String, dynamic> _decodeJsonObject(ArchiveFile file) {
  final bytes = file.readBytes();
  if (bytes == null) {
    throw FormatException('${file.name} has no content');
  }
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}

List<List<dynamic>> _decodeTuples(ArchiveFile file) {
  final bytes = file.readBytes();
  if (bytes == null) {
    throw FormatException('${file.name} has no content');
  }
  final decoded = jsonDecode(utf8.decode(bytes)) as List<dynamic>;
  return decoded.cast<List<dynamic>>();
}

/// Bank files are ordered by their numeric suffix, not by plain string sort
/// (which would put `term_bank_12.json` before `term_bank_2.json`) -- files
/// stay in the dictionary author's intended order regardless of digit
/// count, since that order feeds `DictionaryTermEntries.importOrder`'s
/// tiebreaker role.
List<String> _sortedBankFiles(Iterable<String> names, String bankPrefix) {
  final pattern = RegExp('^${RegExp.escape(bankPrefix)}_(\\d+)\\.json\$');
  final numbered = <MapEntry<int, String>>[];
  for (final name in names) {
    final match = pattern.firstMatch(name);
    if (match != null) {
      numbered.add(MapEntry(int.parse(match.group(1)!), name));
    }
  }
  numbered.sort((a, b) => a.key.compareTo(b.key));
  return [for (final entry in numbered) entry.value];
}

class _Chunk<T> {
  const _Chunk(this.rows, this.startIndex);

  final List<T> rows;
  final int startIndex;
}

/// Splits [items] into fixed-size, index-tracked chunks using `sublist`
/// (not `skip`/`take`, which re-walk the list from the start on every call
/// and would make chunking an O(n²) operation over a 100k+-row dictionary).
Iterable<_Chunk<T>> _chunksOf<T>(List<T> items, int size) sync* {
  for (var start = 0; start < items.length; start += size) {
    final end = start + size < items.length ? start + size : items.length;
    yield _Chunk(items.sublist(start, end), start);
  }
}
