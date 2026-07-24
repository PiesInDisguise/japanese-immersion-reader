import 'dart:math' as math;

import 'rating.dart';

/// A card's FSRS memory state going into a review -- `null`
/// [difficulty]/[stability]/[lastReviewedAt] together mean "never reviewed
/// yet" (mirrors the reference implementation's fresh `Card`, which starts
/// with `stability=None, difficulty=None, last_review=None`).
class FsrsCardState {
  const FsrsCardState({this.difficulty, this.stability, this.lastReviewedAt});

  final double? difficulty;
  final double? stability;
  final DateTime? lastReviewedAt;
}

/// The result of [FsrsScheduler.review]: the card's new memory state, plus
/// when it's next due.
class FsrsReviewResult {
  const FsrsReviewResult({
    required this.difficulty,
    required this.stability,
    required this.due,
    required this.reviewedAt,
  });

  final double difficulty;
  final double stability;
  final DateTime due;
  final DateTime reviewedAt;
}

/// A faithful Dart port of FSRS-6 (spec §12: "Algorithm: FSRS... reference
/// implementations exist to port"), ported directly from the official
/// `open-spaced-repetition/py-fsrs` reference implementation's
/// `Scheduler`/`Card` classes -- every constant and formula below
/// (`_initialStability`, `_initialDifficulty`, `_nextInterval`,
/// `_shortTermStability`, `_nextDifficulty`, `_nextForgetStability`,
/// `_nextRecallStability`, `retrievability`) is a line-for-line translation
/// of that source, not a reimplementation from a paraphrased description.
///
/// **Deliberately configured with zero learning/relearning steps** (the
/// reference implementation's own `learning_steps=()`/`relearning_steps=()`
/// configuration, not an approximation of it -- see the reference
/// `Scheduler.review_card`'s own `len(self.learning_steps) == 0`/
/// `len(self.relearning_steps) == 0` branches, which are first-class
/// supported paths, not error cases). That mechanic is Anki-style
/// sub-day session pacing layered on top of FSRS, not part of the
/// retention-optimizing algorithm itself (the stability/difficulty math
/// below); skipping it means every rating -- including a lapse -- goes
/// straight through the real day-scale FSRS math and produces a new
/// day-granularity due date, which is what actually matters for a reading
/// app's review deck rather than Anki's minute-by-minute drilling. This is
/// why [review] only ever needs a card's current memory state (not a
/// separate "which learning step is it on" field).
class FsrsScheduler {
  const FsrsScheduler({
    this.parameters = defaultParameters,
    this.desiredRetention = 0.9,
    this.maximumIntervalDays = 36500,
  });

  /// FSRS-6's own published default weights (`w[0]`..`w[20]`), verbatim from
  /// `py-fsrs`'s `DEFAULT_PARAMETERS` (`w[20]` is `FSRS_DEFAULT_DECAY`).
  static const defaultParameters = [
    0.212,
    1.2931,
    2.3065,
    8.2956,
    6.4133,
    0.8334,
    3.0194,
    0.001,
    1.8722,
    0.1666,
    0.796,
    1.4835,
    0.0614,
    0.2629,
    1.6483,
    0.6014,
    1.8729,
    0.5425,
    0.0912,
    0.0658,
    0.1542,
  ];

  static const _stabilityMin = 0.001;
  static const _minDifficulty = 1.0;
  static const _maxDifficulty = 10.0;

  final List<double> parameters;

  /// Target probability of successful recall at the moment a card comes
  /// due -- `py-fsrs`'s own default (`desired_retention=0.9`). A future
  /// settings screen could expose this per spec §14's "FSRS parameters",
  /// but isn't wired to one yet.
  final double desiredRetention;

  /// `py-fsrs`'s own default (`maximum_interval=36500`, i.e. ~100 years) --
  /// a practical ceiling so a very stable card doesn't get scheduled
  /// centuries out.
  final int maximumIntervalDays;

  double get _decay => -parameters[20];
  double get _factor => math.pow(0.9, 1 / _decay) - 1;

  /// The predicted probability [state] is still correctly recalled at
  /// [now] -- 0 for a never-reviewed card (there's nothing to retain yet).
  double retrievability(FsrsCardState state, DateTime now) {
    final stability = state.stability;
    final lastReviewedAt = state.lastReviewedAt;
    if (stability == null || lastReviewedAt == null) return 0;
    final elapsedDays = math.max(0, now.difference(lastReviewedAt).inDays);
    return math.pow(1 + _factor * elapsedDays / stability, _decay).toDouble();
  }

  /// Applies [rating] to [state] as of [now] (defaults to the current UTC
  /// time), returning the card's updated memory state and next due date.
  FsrsReviewResult review(
    FsrsCardState state,
    Rating rating, {
    DateTime? now,
  }) {
    final reviewedAt = now ?? DateTime.now().toUtc();
    final daysSinceLastReview = state.lastReviewedAt == null
        ? null
        : reviewedAt.difference(state.lastReviewedAt!).inDays;

    double difficulty;
    double stability;

    if (state.stability == null || state.difficulty == null) {
      stability = _initialStability(rating);
      difficulty = _initialDifficulty(rating);
    } else if (daysSinceLastReview != null && daysSinceLastReview < 1) {
      stability = _shortTermStability(state.stability!, rating);
      difficulty = _nextDifficulty(state.difficulty!, rating);
    } else {
      final r = retrievability(state, reviewedAt);
      stability = _nextStability(
        difficulty: state.difficulty!,
        stability: state.stability!,
        retrievability: r,
        rating: rating,
      );
      difficulty = _nextDifficulty(state.difficulty!, rating);
    }

    final intervalDays = _nextInterval(stability);
    final due = reviewedAt.add(Duration(days: intervalDays));

    return FsrsReviewResult(
      difficulty: difficulty,
      stability: stability,
      due: due,
      reviewedAt: reviewedAt,
    );
  }

  double _clampDifficulty(double difficulty) =>
      difficulty.clamp(_minDifficulty, _maxDifficulty);

  double _clampStability(double stability) =>
      stability < _stabilityMin ? _stabilityMin : stability;

  double _initialStability(Rating rating) =>
      _clampStability(parameters[rating.value - 1]);

  double _initialDifficulty(Rating rating, {bool clamp = true}) {
    final difficulty =
        parameters[4] - (math.exp(parameters[5] * (rating.value - 1))) + 1;
    return clamp ? _clampDifficulty(difficulty) : difficulty;
  }

  int _nextInterval(double stability) {
    final rawInterval =
        (stability / _factor) *
        (math.pow(desiredRetention, 1 / _decay) - 1);
    var intervalDays = rawInterval.round();
    intervalDays = math.max(intervalDays, 1);
    intervalDays = math.min(intervalDays, maximumIntervalDays);
    return intervalDays;
  }

  double _shortTermStability(double stability, Rating rating) {
    var increase =
        math.exp(parameters[17] * (rating.value - 3 + parameters[18])) *
        math.pow(stability, -parameters[19]);
    if (rating == Rating.good || rating == Rating.easy) {
      increase = math.max(increase, 1.0);
    }
    return _clampStability(stability * increase);
  }

  double _linearDamping(double deltaDifficulty, double difficulty) =>
      (10.0 - difficulty) * deltaDifficulty / 9.0;

  double _meanReversion(double arg1, double arg2) =>
      parameters[7] * arg1 + (1 - parameters[7]) * arg2;

  double _nextDifficulty(double difficulty, Rating rating) {
    final arg1 = _initialDifficulty(Rating.easy, clamp: false);
    final deltaDifficulty = -(parameters[6] * (rating.value - 3));
    final arg2 =
        difficulty + _linearDamping(deltaDifficulty, difficulty);
    return _clampDifficulty(_meanReversion(arg1, arg2));
  }

  double _nextStability({
    required double difficulty,
    required double stability,
    required double retrievability,
    required Rating rating,
  }) {
    final next = rating == Rating.again
        ? _nextForgetStability(
            difficulty: difficulty,
            stability: stability,
            retrievability: retrievability,
          )
        : _nextRecallStability(
            difficulty: difficulty,
            stability: stability,
            retrievability: retrievability,
            rating: rating,
          );
    return _clampStability(next);
  }

  double _nextForgetStability({
    required double difficulty,
    required double stability,
    required double retrievability,
  }) {
    final longTerm =
        parameters[11] *
        math.pow(difficulty, -parameters[12]) *
        (math.pow(stability + 1, parameters[13]) - 1) *
        math.exp((1 - retrievability) * parameters[14]);
    final shortTerm =
        stability / math.exp(parameters[17] * parameters[18]);
    return math.min(longTerm, shortTerm).toDouble();
  }

  double _nextRecallStability({
    required double difficulty,
    required double stability,
    required double retrievability,
    required Rating rating,
  }) {
    final hardPenalty = rating == Rating.hard ? parameters[15] : 1.0;
    final easyBonus = rating == Rating.easy ? parameters[16] : 1.0;
    return stability *
        (1 +
            math.exp(parameters[8]) *
                (11 - difficulty) *
                math.pow(stability, -parameters[9]) *
                (math.exp((1 - retrievability) * parameters[10]) - 1) *
                hardPenalty *
                easyBonus);
  }
}
