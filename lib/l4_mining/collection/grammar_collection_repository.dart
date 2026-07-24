import 'package:drift/drift.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/core/ids/stable_id.dart';
import 'package:japanese_immersion_reader/l5_srs/fsrs/rating.dart';

import 'mining_engine.dart';
import 'review_engine.dart';
import 'source_ref.dart';
import 'srs_state.dart';

/// One [GrammarCollectionRepository.due] entry -- grammar-side mirror of
/// `DueWord` (`word_collection_repository.dart`).
class DueGrammar {
  const DueGrammar({
    required this.id,
    required this.grammarPointId,
    required this.due,
  });

  final String id;
  final String grammarPointId;
  final DateTime due;
}

/// Spec §11's `CollectedGrammar`: mine/remove/undo for the grammar side of
/// the collection layer -- the "grammar side behaves identically" (spec
/// §6) mirror of `WordCollectionRepository`. This class only supplies the
/// Drift-specific glue (`_GrammarMiningStore`) and the grammar-specific
/// content-derived id; [MiningEngine] owns the actual shared state machine
/// (see `mining_engine.dart`), not a re-implementation of it; [ReviewEngine]
/// does the same for [review].
class GrammarCollectionRepository {
  GrammarCollectionRepository(this._db);

  final AppDatabase _db;
  static const _engine = MiningEngine();
  static const _reviewEngine = ReviewEngine();

  /// Spec §6's tap semantics applied to a grammar point: fresh add if
  /// [grammarPointId] isn't collected yet, or a "you forgot it" reset (new
  /// sighting appended, SRS state put back to new) if it already is.
  ///
  /// Returns a [MineResult] carrying whatever [undo] needs to reverse this
  /// exact call.
  Future<MineResult> mine({
    required String grammarPointId,
    required SourceRef source,
  }) {
    final id = contentDerivedGrammarId(grammarPointId);
    final store = _GrammarMiningStore.forMine(
      _db,
      id: id,
      grammarPointId: grammarPointId,
    );
    return _db.transaction(() => _engine.mine(store, source: source));
  }

  /// Long-press remove (auto-add-ON), and auto-add-OFF's "-" button.
  Future<void> remove({required String grammarPointId}) {
    final id = contentDerivedGrammarId(grammarPointId);
    return _db.transaction(
      () => _engine.remove(_GrammarMiningStore.forId(_db, id)),
    );
  }

  /// Reverses whatever [result]'s originating [mine] call actually did.
  Future<void> undo(MineResult result) {
    return _db.transaction(
      () =>
          _engine.undo(_GrammarMiningStore.forId(_db, result.entryId), result),
    );
  }

  /// Spec §12's review deck: every grammar point due on or before [now]
  /// (defaults to the current UTC time), earliest-due first.
  Future<List<DueGrammar>> due({DateTime? now}) async {
    final cutoff = now ?? DateTime.now().toUtc();
    final query = _db.select(_db.collectedGrammars)
      ..where((g) => g.srsDue.isSmallerOrEqualValue(cutoff))
      ..orderBy([(g) => OrderingTerm.asc(g.srsDue)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        DueGrammar(
          id: row.id,
          grammarPointId: row.grammarPointId,
          due: row.srsDue,
        ),
    ];
  }

  /// Spec §12's rating buttons: scores [id] (a [DueGrammar.id]) via the real
  /// FSRS scheduler and reschedules it.
  Future<void> review(String id, Rating rating, {DateTime? now}) {
    return _db.transaction(
      () => _reviewEngine.review(
        _GrammarMiningStore.forId(_db, id),
        rating,
        now: now,
      ),
    );
  }

  /// The sentence id of [id]'s most recent sighting -- grammar-side mirror
  /// of `WordCollectionRepository.latestSightingSentenceId` (see that
  /// method's own doc comment for why ties are broken on `id` too).
  Future<String?> latestSightingSentenceId(String id) async {
    final query = _db.select(_db.collectedGrammarSources)
      ..where((s) => s.collectedGrammarId.equals(id))
      ..orderBy([
        (s) => OrderingTerm.desc(s.minedAt),
        (s) => OrderingTerm.desc(s.id),
      ])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.sentenceId;
  }
}

/// Drift-backed [MiningStore] for `CollectedGrammars`/
/// `CollectedGrammarSources`.
///
/// [grammarPointId] is only ever read by [insertFresh] (the fresh-add
/// branch of [MiningEngine.mine]) -- `remove`/`undo` never reach that
/// branch, so [forId] leaves it null and only [forMine] (the constructor
/// `GrammarCollectionRepository.mine` actually uses) requires a real value.
class _GrammarMiningStore implements MiningStore {
  _GrammarMiningStore.forMine(
    this._db, {
    required this.id,
    required this.grammarPointId,
  });

  _GrammarMiningStore.forId(this._db, this.id) : grammarPointId = null;

  final AppDatabase _db;
  @override
  final String id;
  final String? grammarPointId;

  @override
  Future<SrsState?> readSrsState() async {
    final row = await (_db.select(
      _db.collectedGrammars,
    )..where((g) => g.id.equals(id))).getSingleOrNull();
    return row == null ? null : _srsStateOf(row);
  }

  @override
  Future<void> insertFresh(SrsState state, DateTime timestamp) {
    return _db
        .into(_db.collectedGrammars)
        .insert(
          CollectedGrammarsCompanion.insert(
            id: id,
            grammarPointId: grammarPointId!,
            addedAt: timestamp,
            updatedAt: timestamp,
            fsrsDifficulty: Value(state.difficulty),
            fsrsStability: Value(state.stability),
            srsDue: state.due,
            srsLapses: state.lapses,
            srsStatus: state.status.name,
            lastReviewedAt: Value(state.lastReviewedAt),
          ),
        );
  }

  @override
  Future<void> restoreSrsState(SrsState state, DateTime timestamp) {
    return (_db.update(
      _db.collectedGrammars,
    )..where((g) => g.id.equals(id))).write(
      CollectedGrammarsCompanion(
        updatedAt: Value(timestamp),
        fsrsDifficulty: Value(state.difficulty),
        fsrsStability: Value(state.stability),
        srsDue: Value(state.due),
        srsLapses: Value(state.lapses),
        srsStatus: Value(state.status.name),
        lastReviewedAt: Value(state.lastReviewedAt),
      ),
    );
  }

  @override
  Future<int> insertSighting(SourceRef source, DateTime timestamp) {
    return _db
        .into(_db.collectedGrammarSources)
        .insert(
          CollectedGrammarSourcesCompanion.insert(
            collectedGrammarId: id,
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
      _db.collectedGrammarSources,
    )..where((s) => s.id.equals(sightingId))).go();
  }

  @override
  Future<void> deleteEntry() async {
    // No SQLite FK-cascade in this codebase (see tables.dart's note on
    // CollectedWordSources) -- sightings must be deleted explicitly before
    // the parent row.
    await (_db.delete(
      _db.collectedGrammarSources,
    )..where((s) => s.collectedGrammarId.equals(id))).go();
    await (_db.delete(
      _db.collectedGrammars,
    )..where((g) => g.id.equals(id))).go();
  }

  SrsState _srsStateOf(CollectedGrammar row) => SrsState(
    difficulty: row.fsrsDifficulty,
    stability: row.fsrsStability,
    due: row.srsDue,
    lapses: row.srsLapses,
    status: SrsStatus.values.byName(row.srsStatus),
    lastReviewedAt: row.lastReviewedAt,
  );
}
