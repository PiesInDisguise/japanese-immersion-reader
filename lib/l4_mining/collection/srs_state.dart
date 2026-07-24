/// FSRS-shaped SRS status (spec §12): `newCard` before any review, then
/// `review` once the real `FsrsScheduler` (`lib/l5_srs/fsrs/`) has scored at
/// least one rating. Named `newCard` rather than `new` because the latter is
/// a reserved word in Dart.
///
/// `learning`/`relearning` stay in this enum for schema/API
/// forward-compatibility (a future pass could add real Anki-style sub-day
/// learning steps), but `ReviewEngine`'s current review flow never produces
/// them -- see `FsrsScheduler`'s own doc comment for why this app runs FSRS
/// with zero learning/relearning steps, a first-class supported
/// configuration in the reference implementation rather than an
/// approximation of one.
enum SrsStatus { newCard, learning, review, relearning }

/// Spec §12's `srsState`, stored as flat Drift columns rather than a nested
/// struct (see `CollectedWords`/`CollectedGrammars` in `lib/core/db/
/// tables.dart`) since Drift columns are scalar. This class is the
/// in-memory shape `lib/l4_mining/collection/mining_engine.dart` and
/// `review_engine.dart`, and their repositories, read and write those
/// columns through.
///
/// [difficulty]/[stability]/[lastReviewedAt] are `null` together exactly
/// when [status] is [SrsStatus.newCard] -- no rating has ever been given yet,
/// so `FsrsScheduler` has nothing to update (mirrors the reference FSRS
/// implementation's own fresh-card representation, `stability=None,
/// difficulty=None, last_review=None`).
class SrsState {
  const SrsState({
    required this.difficulty,
    required this.stability,
    required this.due,
    required this.lapses,
    required this.status,
    required this.lastReviewedAt,
  });

  /// The placeholder state for a brand-new entry, and what a "reset" tap
  /// (spec §6: re-tapping an already-collected word/grammar point sets it
  /// back to "new", i.e. "you forgot it") puts it back to: nothing has been
  /// reviewed yet, so it's immediately due and carries no FSRS memory state.
  factory SrsState.fresh(DateTime now) => SrsState(
    difficulty: null,
    stability: null,
    due: now,
    lapses: 0,
    status: SrsStatus.newCard,
    lastReviewedAt: null,
  );

  final double? difficulty;
  final double? stability;
  final DateTime due;
  final int lapses;
  final SrsStatus status;
  final DateTime? lastReviewedAt;
}
