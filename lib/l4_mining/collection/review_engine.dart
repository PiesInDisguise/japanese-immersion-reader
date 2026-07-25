import 'package:japanese_immersion_reader/l5_srs/fsrs/fsrs_scheduler.dart';
import 'package:japanese_immersion_reader/l5_srs/fsrs/rating.dart';

import 'mining_engine.dart';
import 'srs_state.dart';

/// The shared state machine behind spec §12's review flow -- written once
/// here and driven identically by both `WordCollectionRepository` and
/// `GrammarCollectionRepository`'s own `review` methods, mirroring
/// `MiningEngine`'s role for mine/remove/undo (same file's `mine`'s own doc
/// comment explains why: one real state machine, two thin Drift-backed
/// adapters).
///
/// Reuses [MiningStore] (rather than defining a narrower interface) purely
/// because it already exposes exactly what's needed here
/// (`readSrsState`/`restoreSrsState`) and both repositories already have a
/// `MiningStore` adapter (`_WordMiningStore`/`_GrammarMiningStore`)
/// constructible from just an id via their `forId` factory -- `review`
/// never touches `insertFresh`/`insertSighting`, the mine-only members.
class ReviewEngine {
  const ReviewEngine([this._scheduler = const FsrsScheduler()]);

  final FsrsScheduler _scheduler;

  /// Applies [rating] to whatever entry [store] points at, via the real
  /// FSRS scheduler, and persists the result. Throws [StateError] if
  /// [store] has no entry yet -- a card only ever reaches the review deck
  /// because it's already collected, so this should never happen in
  /// practice; it's not a recoverable "reviewing nothing" state.
  Future<void> review(MiningStore store, Rating rating, {DateTime? now}) async {
    final current = await store.readSrsState();
    if (current == null) {
      throw StateError(
        'ReviewEngine.review: no entry exists for id "${store.id}".',
      );
    }

    final reviewedAt = now ?? DateTime.now().toUtc();
    final result = _scheduler.review(
      FsrsCardState(
        difficulty: current.difficulty,
        stability: current.stability,
        lastReviewedAt: current.lastReviewedAt,
        state: _fsrsStateOf(current.status),
        step: current.step ?? 0,
      ),
      rating,
      now: reviewedAt,
    );

    // A "lapse" (spec §11's `lapses` counter) means forgetting a
    // previously-learned card -- an Again rating on a never-yet-reviewed
    // (`newCard`) or still-Learning entry is just "didn't know it yet", not
    // a lapse. This checks `current.status` (the status *going into* this
    // review), not `result`'s: it's the same condition FsrsScheduler itself
    // uses to decide whether an Again on a Review card drops into
    // Relearning, just restated here since lapse-counting is an app-level
    // stat FsrsScheduler's own reference source doesn't track itself.
    final lapses = rating == Rating.again && current.status == SrsStatus.review
        ? current.lapses + 1
        : current.lapses;

    await store.restoreSrsState(
      SrsState(
        difficulty: result.difficulty,
        stability: result.stability,
        due: result.due,
        lapses: lapses,
        status: _srsStatusOf(result.state),
        lastReviewedAt: result.reviewedAt,
        step: result.step,
      ),
      reviewedAt,
    );
  }

  /// `newCard` (never reviewed) starts exactly where a fresh
  /// `FsrsCardState` does -- [FsrsState.learning] -- matching the reference
  /// `Card`'s own `__init__` default. `learning`/`review`/`relearning` map
  /// straight across; [SrsStatus] only has the one extra value
  /// [FsrsState] doesn't need, since "never reviewed" and "reviewed at
  /// least once, still in Learning" are the same `FsrsState` but distinct,
  /// spec-meaningful app states (a fresh entry is immediately due; a
  /// mid-learning-steps entry is due at whatever short interval its last
  /// rating produced).
  FsrsState _fsrsStateOf(SrsStatus status) => switch (status) {
    SrsStatus.newCard => FsrsState.learning,
    SrsStatus.learning => FsrsState.learning,
    SrsStatus.review => FsrsState.review,
    SrsStatus.relearning => FsrsState.relearning,
  };

  SrsStatus _srsStatusOf(FsrsState state) => switch (state) {
    FsrsState.learning => SrsStatus.learning,
    FsrsState.review => SrsStatus.review,
    FsrsState.relearning => SrsStatus.relearning,
  };
}
