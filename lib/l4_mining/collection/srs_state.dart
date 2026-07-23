/// FSRS-shaped SRS status (spec §12): `newCard` before any review, then
/// `learning`/`review`/`relearning` as FSRS's own scheduler transitions a
/// card between them (the standard FSRS/Anki four-state model). Named
/// `newCard` rather than `new` because the latter is a reserved word in
/// Dart.
///
/// This phase never produces anything but [newCard] -- the real FSRS
/// scheduler (interval growth, ease adjustment, state transitions on
/// review) is a later phase (`lib/l5_srs/fsrs/`, currently just a
/// `.gitkeep`). This enum exists now only so the collection schema has a
/// concrete, typed place to store `status` rather than a bare string.
enum SrsStatus { newCard, learning, review, relearning }

/// Spec §12's `srsState { interval, ease, due, lapses, status }`, stored as
/// flat Drift columns rather than a nested struct (see `CollectedWords`/
/// `CollectedGrammars` in `lib/core/db/tables.dart`) since Drift columns are
/// scalar. This class is the in-memory shape
/// `lib/l4_mining/collection/mining_engine.dart` and its two repositories
/// read and write those columns through.
class SrsState {
  const SrsState({
    required this.interval,
    required this.ease,
    required this.due,
    required this.lapses,
    required this.status,
  });

  /// The placeholder initial state for a brand-new entry, and what a
  /// "reset" tap (spec §6: re-tapping an already-collected word/grammar
  /// point sets it back to "new", i.e. "you forgot it") puts it back to.
  ///
  /// These are deliberately simple, clearly-a-placeholder defaults -- real
  /// FSRS parameter semantics are a later phase's concern, not this
  /// schema stub's:
  ///  - `interval`/`lapses` are zero: no reviews have happened yet.
  ///  - `due` is `now`: immediately reviewable.
  ///  - `ease` starts at 2.5, SM-2/Anki's conventional default initial ease
  ///    factor, since FSRS's own default-parameter equivalent is the real
  ///    FSRS phase's call to make.
  factory SrsState.fresh(DateTime now) => SrsState(
    interval: 0,
    ease: 2.5,
    due: now,
    lapses: 0,
    status: SrsStatus.newCard,
  );

  final int interval;
  final double ease;
  final DateTime due;
  final int lapses;
  final SrsStatus status;
}
