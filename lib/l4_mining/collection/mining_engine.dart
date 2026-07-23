import 'source_ref.dart';
import 'srs_state.dart';

/// What [MiningEngine.mine] actually did to a `CollectedWords`/
/// `CollectedGrammars` row -- returned so [MiningEngine.undo] can reverse
/// exactly that, without the caller (an undo toast, eventually) needing to
/// separately remember "what was there before".
class MineResult {
  const MineResult._({
    required this.entryId,
    required this.wasFreshAdd,
    required this.sightingId,
    this.previousSrsState,
  });

  /// The entry didn't exist before this `mine` call -- it was created from
  /// scratch. [MiningEngine.undo] deletes it entirely.
  const MineResult.freshAdd({required String entryId, required int sightingId})
    : this._(entryId: entryId, wasFreshAdd: true, sightingId: sightingId);

  /// The entry already existed -- `mine` appended [sightingId] as a new
  /// sighting and reset its SRS state to "new". [MiningEngine.undo] drops
  /// that sighting and restores [previousSrsState].
  const MineResult.reset({
    required String entryId,
    required int sightingId,
    required SrsState previousSrsState,
  }) : this._(
         entryId: entryId,
         wasFreshAdd: false,
         sightingId: sightingId,
         previousSrsState: previousSrsState,
       );

  /// The `CollectedWords`/`CollectedGrammars` primary key this result is
  /// about -- lets a later `undo` call reconstruct the right store without
  /// the caller separately tracking which id a [MineResult] belongs to.
  final String entryId;
  final bool wasFreshAdd;

  /// The row id of the sighting [MiningEngine.mine] just inserted (in
  /// either branch -- a fresh add always has exactly one).
  final int sightingId;

  /// Only set when [wasFreshAdd] is false: the SRS state the entry had
  /// immediately before this `mine` call reset it.
  final SrsState? previousSrsState;
}

/// Base operations on one collection entry (word or grammar) shared by
/// spec §6's `remove` (long-press, and auto-add-OFF's "-" button) and
/// `undo`: neither ever creates a fresh entry or appends a new sighting, so
/// this interface doesn't expose the fresh-add/read/insert-sighting
/// operations [MiningStore] adds on top of it for `mine`.
abstract class CollectionEntryStore {
  /// Deletes the entry and all of its sightings.
  Future<void> deleteEntry();

  /// Overwrites just the SRS columns (+ `updatedAt`) of an existing entry.
  /// Used both to restore a prior snapshot (`undo`) and, via [MiningStore],
  /// to write a fresh "reset" snapshot (`mine`) -- "restore" and "reset" are
  /// the same kind of write, just with a different [SrsState] input.
  Future<void> restoreSrsState(SrsState state, DateTime timestamp);

  /// Deletes exactly one sighting row (the one a prior
  /// [MiningStore.insertSighting] call created), not every sighting the
  /// entry has.
  Future<void> deleteSighting(int sightingId);
}

/// What [MiningEngine.mine] needs from a concrete word/grammar Drift-backed
/// adapter to run spec §6's "add fresh, or reset-if-already-collected" tap
/// semantics, on top of [CollectionEntryStore]. Scoped to a single entry id
/// per instance -- concrete repositories construct one of these per call
/// (see `word_collection_repository.dart`/`grammar_collection_repository.dart`).
abstract class MiningStore implements CollectionEntryStore {
  /// This store's entry id (a `contentDerivedWordId`/`contentDerivedGrammarId`
  /// from `lib/core/ids/stable_id.dart`) -- read by [MiningEngine.mine] to
  /// stamp [MineResult.entryId].
  String get id;

  /// The entry's current SRS state, or `null` if no entry exists yet for
  /// this store's id.
  Future<SrsState?> readSrsState();

  /// Creates a brand-new entry -- plus whatever entity-specific fields the
  /// concrete adapter captured at construction (dictForm/reading/senseIds
  /// for a word, grammarPointId for a grammar point) -- with [state] and
  /// `addedAt`/`updatedAt` set to [timestamp]. Only ever called when
  /// [readSrsState] just returned `null`.
  Future<void> insertFresh(SrsState state, DateTime timestamp);

  /// Records one sighting row for this entry and returns its row id, so a
  /// later [CollectionEntryStore.deleteSighting] can remove exactly this
  /// one.
  Future<int> insertSighting(SourceRef source, DateTime timestamp);
}

/// The shared state machine behind spec §6's mining behavior -- written
/// once here and driven identically by both `WordCollectionRepository` and
/// `GrammarCollectionRepository` (each supplying a thin Drift-backed
/// [MiningStore] adapter for its own table pair), matching the spec's "the
/// grammar side behaves identically" framing. Neither repository
/// re-implements this branching logic itself.
class MiningEngine {
  const MiningEngine();

  /// Auto-add-ON's core tap behavior (spec §6), and auto-add-OFF's `+`
  /// button when not yet collected: fresh add if [store] has no entry yet,
  /// or a "you forgot it" reset (new sighting appended, SRS state put back
  /// to [SrsState.fresh]) if it's already collected.
  ///
  /// The sighting is always inserted after the entry itself exists (created
  /// first on the fresh-add branch; already there on the reset branch) so
  /// the sighting's parent-id reference is always valid, matching
  /// `CollectedWordSources`/`CollectedGrammarSources`'s FK declarations even
  /// though this codebase doesn't turn on SQLite FK enforcement.
  Future<MineResult> mine(
    MiningStore store, {
    required SourceRef source,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = await store.readSrsState();

    if (existing == null) {
      await store.insertFresh(SrsState.fresh(now), now);
      final sightingId = await store.insertSighting(source, now);
      return MineResult.freshAdd(entryId: store.id, sightingId: sightingId);
    }

    final sightingId = await store.insertSighting(source, now);
    await store.restoreSrsState(SrsState.fresh(now), now);
    return MineResult.reset(
      entryId: store.id,
      sightingId: sightingId,
      previousSrsState: existing,
    );
  }

  /// Long-press remove (auto-add-ON) and the "-" button (auto-add-OFF).
  Future<void> remove(CollectionEntryStore store) => store.deleteEntry();

  /// Reverses whatever [result]'s originating [mine] call actually did: a
  /// full delete if it was a fresh add, or a restore of the prior SRS state
  /// plus dropping the just-appended sighting if it was a reset.
  Future<void> undo(CollectionEntryStore store, MineResult result) async {
    if (result.wasFreshAdd) {
      await store.deleteEntry();
      return;
    }
    await store.deleteSighting(result.sightingId);
    await store.restoreSrsState(
      result.previousSrsState!,
      DateTime.now().toUtc(),
    );
  }
}
