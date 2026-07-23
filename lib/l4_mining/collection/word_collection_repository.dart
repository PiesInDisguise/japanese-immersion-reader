import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/core/ids/stable_id.dart';

import 'mining_engine.dart';
import 'source_ref.dart';
import 'srs_state.dart';

/// Spec §11's `CollectedWord`: mine/remove/undo for the word side of the
/// collection layer. This class only supplies the Drift-specific glue
/// (`_WordMiningStore`) and the word-specific content-derived id --
/// [MiningEngine] (see `mining_engine.dart`) owns the actual "add fresh, or
/// reset-if-already-collected" state machine, shared verbatim with
/// `GrammarCollectionRepository`.
class WordCollectionRepository {
  WordCollectionRepository(this._db);

  final AppDatabase _db;
  static const _engine = MiningEngine();

  /// Spec §6's tap semantics: fresh add if `dictForm`+`reading` isn't
  /// collected yet, or a "you forgot it" reset (new sighting appended, SRS
  /// state put back to new) if it already is.
  ///
  /// [senseIds] are the tapped popup's matched `DictionaryTermEntry.id`s
  /// (`lib/l2_linguistics/dictionary`) and are recorded on a fresh add;
  /// left untouched on a reset, since spec §6's re-tap behavior only calls
  /// out appending a sighting and resetting SRS state, not updating which
  /// senses this entry came from.
  ///
  /// Returns a [MineResult] carrying whatever [undo] needs to reverse this
  /// exact call.
  Future<MineResult> mine({
    required String dictForm,
    required String reading,
    required List<int> senseIds,
    required SourceRef source,
  }) {
    final id = contentDerivedWordId(dictForm: dictForm, reading: reading);
    final store = _WordMiningStore.forMine(
      _db,
      id: id,
      dictForm: dictForm,
      reading: reading,
      senseIds: senseIds,
    );
    return _db.transaction(() => _engine.mine(store, source: source));
  }

  /// Long-press remove (auto-add-ON), and auto-add-OFF's "-" button.
  Future<void> remove({required String dictForm, required String reading}) {
    final id = contentDerivedWordId(dictForm: dictForm, reading: reading);
    return _db.transaction(
      () => _engine.remove(_WordMiningStore.forId(_db, id)),
    );
  }

  /// Reverses whatever [result]'s originating [mine] call actually did.
  Future<void> undo(MineResult result) {
    return _db.transaction(
      () => _engine.undo(_WordMiningStore.forId(_db, result.entryId), result),
    );
  }
}

/// Drift-backed [MiningStore] for `CollectedWords`/`CollectedWordSources`.
///
/// [dictForm]/[reading]/[senseIds] are only ever read by [insertFresh] (the
/// fresh-add branch of [MiningEngine.mine]) -- `remove`/`undo` never reach
/// that branch, so [forId] leaves them null and only [forMine] (the
/// constructor `WordCollectionRepository.mine` actually uses) requires
/// real values for them.
class _WordMiningStore implements MiningStore {
  _WordMiningStore.forMine(
    this._db, {
    required this.id,
    required this.dictForm,
    required this.reading,
    required this.senseIds,
  });

  _WordMiningStore.forId(this._db, this.id)
    : dictForm = null,
      reading = null,
      senseIds = null;

  final AppDatabase _db;
  @override
  final String id;
  final String? dictForm;
  final String? reading;
  final List<int>? senseIds;

  @override
  Future<SrsState?> readSrsState() async {
    final row = await (_db.select(
      _db.collectedWords,
    )..where((w) => w.id.equals(id))).getSingleOrNull();
    return row == null ? null : _srsStateOf(row);
  }

  @override
  Future<void> insertFresh(SrsState state, DateTime timestamp) {
    return _db
        .into(_db.collectedWords)
        .insert(
          CollectedWordsCompanion.insert(
            id: id,
            dictForm: dictForm!,
            reading: reading!,
            senseIdsJson: jsonEncode(senseIds),
            addedAt: timestamp,
            updatedAt: timestamp,
            srsInterval: state.interval,
            srsEase: state.ease,
            srsDue: state.due,
            srsLapses: state.lapses,
            srsStatus: state.status.name,
          ),
        );
  }

  @override
  Future<void> restoreSrsState(SrsState state, DateTime timestamp) {
    return (_db.update(
      _db.collectedWords,
    )..where((w) => w.id.equals(id))).write(
      CollectedWordsCompanion(
        updatedAt: Value(timestamp),
        srsInterval: Value(state.interval),
        srsEase: Value(state.ease),
        srsDue: Value(state.due),
        srsLapses: Value(state.lapses),
        srsStatus: Value(state.status.name),
      ),
    );
  }

  @override
  Future<int> insertSighting(SourceRef source, DateTime timestamp) {
    return _db
        .into(_db.collectedWordSources)
        .insert(
          CollectedWordSourcesCompanion.insert(
            collectedWordId: id,
            workId: source.workId,
            sentenceId: source.sentenceId,
            mediaType: source.mediaType.name,
            minedAt: timestamp,
          ),
        );
  }

  @override
  Future<void> deleteSighting(int sightingId) async {
    await (_db.delete(
      _db.collectedWordSources,
    )..where((s) => s.id.equals(sightingId))).go();
  }

  @override
  Future<void> deleteEntry() async {
    // No SQLite FK-cascade in this codebase (see tables.dart's note on
    // CollectedWordSources) -- sightings must be deleted explicitly before
    // the parent row.
    await (_db.delete(
      _db.collectedWordSources,
    )..where((s) => s.collectedWordId.equals(id))).go();
    await (_db.delete(_db.collectedWords)..where((w) => w.id.equals(id))).go();
  }

  SrsState _srsStateOf(CollectedWord row) => SrsState(
    interval: row.srsInterval,
    ease: row.srsEase,
    due: row.srsDue,
    lapses: row.srsLapses,
    status: SrsStatus.values.byName(row.srsStatus),
  );
}
