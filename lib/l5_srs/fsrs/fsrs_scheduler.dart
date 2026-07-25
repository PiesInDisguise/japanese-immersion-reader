import 'dart:math' as math;

import 'rating.dart';

/// A card's place in the FSRS state machine (spec §12; matches the
/// reference `open-spaced-repetition/py-fsrs`'s `State` `IntEnum` exactly:
/// `Learning=1, Review=2, Relearning=3`) -- [FsrsScheduler.review] branches
/// on this to decide whether a rating advances a short learning/relearning
/// step or goes through full day-scale FSRS scheduling.
enum FsrsState { learning, review, relearning }

/// A card's FSRS memory state going into a review -- `difficulty`/
/// `stability`/`lastReviewedAt` are `null` together exactly for a
/// never-reviewed card (mirrors the reference implementation's fresh
/// `Card`, which starts with `stability=None, difficulty=None,
/// last_review=None`). [state] defaults to [FsrsState.learning] and [step]
/// to `0` -- a brand-new card's starting point, per the reference `Card`'s
/// own `__init__` (`state=State.Learning`, `step=0` when unset).
class FsrsCardState {
  const FsrsCardState({
    this.difficulty,
    this.stability,
    this.lastReviewedAt,
    this.state = FsrsState.learning,
    this.step = 0,
  });

  final double? difficulty;
  final double? stability;
  final DateTime? lastReviewedAt;
  final FsrsState state;

  /// The current learning/relearning step index, or `null` when [state] is
  /// [FsrsState.review] (a graduated card isn't "on" any step).
  final int? step;
}

/// The result of [FsrsScheduler.review]: the card's new memory state, plus
/// when it's next due.
class FsrsReviewResult {
  const FsrsReviewResult({
    required this.difficulty,
    required this.stability,
    required this.due,
    required this.reviewedAt,
    required this.state,
    required this.step,
  });

  final double difficulty;
  final double stability;
  final DateTime due;
  final DateTime reviewedAt;
  final FsrsState state;
  final int? step;
}

/// A faithful Dart port of FSRS-6 (spec §12: "Algorithm: FSRS... reference
/// implementations exist to port"), ported directly from the official
/// `open-spaced-repetition/py-fsrs` reference implementation's
/// `Scheduler`/`Card` classes -- every constant and formula below
/// (`_initialStability`, `_initialDifficulty`, `_nextInterval`,
/// `_shortTermStability`, `_nextDifficulty`, `_nextForgetStability`,
/// `_nextRecallStability`, `retrievability`, and [review]'s
/// Learning/Review/Relearning branching) is a line-for-line translation of
/// that source (`fsrs/scheduler.py`'s `Scheduler.review_card`), not a
/// reimplementation from a paraphrased description.
///
/// **Learning/relearning steps are real here**, matching upstream's own
/// defaults (`learning_steps=(1m, 10m)`, `relearning_steps=(10m,)`) -- the
/// same Anki-style sub-day pacing real Anki (which also ships FSRS as its
/// default scheduler) uses: a new card is rated a few times in quick
/// succession before it "graduates" into the real day-scale FSRS interval
/// math, and a lapsed (`Again`-rated) Review card similarly gets a short
/// relearning pass before returning to Review. [learningSteps]/
/// [relearningSteps] are constructor-injectable (an empty list on either
/// disables that phase entirely, `review_card`'s own first-class-supported
/// `len(...) == 0` path) so callers that specifically want the old
/// immediate-day-scale-scheduling behavior still can.
///
/// Not ported: `enable_fuzzing` (upstream's small randomized jitter on
/// Review-state intervals) -- out of scope for this pass, since it's an
/// independent knob from learning/relearning steps and this port's
/// intervals stay exactly reproducible without it.
class FsrsScheduler {
  const FsrsScheduler({
    this.parameters = defaultParameters,
    this.desiredRetention = 0.9,
    this.maximumIntervalDays = 36500,
    this.learningSteps = defaultLearningSteps,
    this.relearningSteps = defaultRelearningSteps,
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

  /// `py-fsrs`'s own default `learning_steps=(timedelta(minutes=1),
  /// timedelta(minutes=10))` -- matches Anki's own default new-card steps.
  static const defaultLearningSteps = [
    Duration(minutes: 1),
    Duration(minutes: 10),
  ];

  /// `py-fsrs`'s own default `relearning_steps=(timedelta(minutes=10),)`.
  static const defaultRelearningSteps = [Duration(minutes: 10)];

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

  /// Small time intervals that schedule cards in [FsrsState.learning].
  /// Empty disables the learning phase entirely -- every rating on a
  /// Learning-state card graduates it straight to [FsrsState.review].
  final List<Duration> learningSteps;

  /// Small time intervals that schedule cards in [FsrsState.relearning].
  /// Empty disables the relearning phase -- an `Again` on a Review-state
  /// card goes straight back through day-scale FSRS scheduling instead of
  /// dropping into [FsrsState.relearning].
  final List<Duration> relearningSteps;

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
  /// time), returning the card's updated memory state, FSRS state/step, and
  /// next due date. A line-for-line port of `Scheduler.review_card`'s three
  /// `match card.state` branches (Learning/Review/Relearning) -- see the
  /// class doc comment.
  FsrsReviewResult review(
    FsrsCardState state,
    Rating rating, {
    DateTime? now,
  }) {
    final reviewedAt = now ?? DateTime.now().toUtc();
    final daysSinceLastReview = state.lastReviewedAt == null
        ? null
        : reviewedAt.difference(state.lastReviewedAt!).inDays;

    late final double difficulty;
    late final double stability;
    late final FsrsState resultState;
    late final int? resultStep;
    late final Duration nextInterval;

    switch (state.state) {
      case FsrsState.learning:
        final step = state.step ?? 0;
        (difficulty, stability) = _updateMemoryState(
          state: state,
          rating: rating,
          reviewedAt: reviewedAt,
          daysSinceLastReview: daysSinceLastReview,
        );

        // Handles the edge case where this card was previously scheduled
        // with a Scheduler that had more learningSteps than this one.
        if (learningSteps.isEmpty ||
            (step >= learningSteps.length && rating != Rating.again)) {
          resultState = FsrsState.review;
          resultStep = null;
          nextInterval = Duration(days: _nextInterval(stability));
        } else {
          switch (rating) {
            case Rating.again:
              resultState = FsrsState.learning;
              resultStep = 0;
              nextInterval = learningSteps[0];
            case Rating.hard:
              resultState = FsrsState.learning;
              resultStep = step;
              if (step == 0 && learningSteps.length == 1) {
                nextInterval = learningSteps[0] * 1.5;
              } else if (step == 0 && learningSteps.length >= 2) {
                nextInterval = _midpoint(learningSteps[0], learningSteps[1]);
              } else {
                nextInterval = learningSteps[step];
              }
            case Rating.good:
              if (step + 1 == learningSteps.length) {
                resultState = FsrsState.review;
                resultStep = null;
                nextInterval = Duration(days: _nextInterval(stability));
              } else {
                resultState = FsrsState.learning;
                resultStep = step + 1;
                nextInterval = learningSteps[resultStep];
              }
            case Rating.easy:
              resultState = FsrsState.review;
              resultStep = null;
              nextInterval = Duration(days: _nextInterval(stability));
          }
        }

      case FsrsState.review:
        difficulty = _nextDifficulty(state.difficulty!, rating);
        stability = _updateReviewStability(
          state: state,
          rating: rating,
          reviewedAt: reviewedAt,
          daysSinceLastReview: daysSinceLastReview,
        );

        switch (rating) {
          case Rating.again:
            if (relearningSteps.isEmpty) {
              resultState = FsrsState.review;
              resultStep = null;
              nextInterval = Duration(days: _nextInterval(stability));
            } else {
              resultState = FsrsState.relearning;
              resultStep = 0;
              nextInterval = relearningSteps[0];
            }
          case Rating.hard:
          case Rating.good:
          case Rating.easy:
            resultState = FsrsState.review;
            resultStep = null;
            nextInterval = Duration(days: _nextInterval(stability));
        }

      case FsrsState.relearning:
        final step = state.step ?? 0;
        difficulty = _nextDifficulty(state.difficulty!, rating);
        stability = _updateReviewStability(
          state: state,
          rating: rating,
          reviewedAt: reviewedAt,
          daysSinceLastReview: daysSinceLastReview,
        );

        // Handles the edge case where this card was previously scheduled
        // with a Scheduler that had more relearningSteps than this one.
        if (relearningSteps.isEmpty ||
            (step >= relearningSteps.length && rating != Rating.again)) {
          resultState = FsrsState.review;
          resultStep = null;
          nextInterval = Duration(days: _nextInterval(stability));
        } else {
          switch (rating) {
            case Rating.again:
              resultStep = 0;
              nextInterval = relearningSteps[0];
              resultState = FsrsState.relearning;
            case Rating.hard:
              resultStep = step;
              if (step == 0 && relearningSteps.length == 1) {
                nextInterval = relearningSteps[0] * 1.5;
              } else if (step == 0 && relearningSteps.length >= 2) {
                nextInterval = _midpoint(
                  relearningSteps[0],
                  relearningSteps[1],
                );
              } else {
                nextInterval = relearningSteps[step];
              }
              resultState = FsrsState.relearning;
            case Rating.good:
              if (step + 1 == relearningSteps.length) {
                resultState = FsrsState.review;
                resultStep = null;
                nextInterval = Duration(days: _nextInterval(stability));
              } else {
                resultStep = step + 1;
                nextInterval = relearningSteps[resultStep];
                resultState = FsrsState.relearning;
              }
            case Rating.easy:
              resultState = FsrsState.review;
              resultStep = null;
              nextInterval = Duration(days: _nextInterval(stability));
          }
        }
    }

    return FsrsReviewResult(
      difficulty: difficulty,
      stability: stability,
      due: reviewedAt.add(nextInterval),
      reviewedAt: reviewedAt,
      state: resultState,
      step: resultStep,
    );
  }

  /// Shared difficulty/stability update for a [FsrsState.learning] card --
  /// the same three-way branch (`stability is None` / `days_since < 1` /
  /// otherwise) `review_card`'s Learning arm and Relearning arm each
  /// duplicate in the reference; factored out here since it's identical.
  (double, double) _updateMemoryState({
    required FsrsCardState state,
    required Rating rating,
    required DateTime reviewedAt,
    required int? daysSinceLastReview,
  }) {
    if (state.stability == null || state.difficulty == null) {
      return (_initialDifficulty(rating), _initialStability(rating));
    }
    if (daysSinceLastReview != null && daysSinceLastReview < 1) {
      return (
        _nextDifficulty(state.difficulty!, rating),
        _shortTermStability(state.stability!, rating),
      );
    }
    final r = retrievability(state, reviewedAt);
    return (
      _nextDifficulty(state.difficulty!, rating),
      _nextStability(
        difficulty: state.difficulty!,
        stability: state.stability!,
        retrievability: r,
        rating: rating,
      ),
    );
  }

  /// Review/Relearning-state stability update (difficulty is always just
  /// `_nextDifficulty` in both, computed by the caller) -- the `days_since
  /// < 1` short-term-stability-only branch vs. the full retrievability-based
  /// `_nextStability` branch.
  double _updateReviewStability({
    required FsrsCardState state,
    required Rating rating,
    required DateTime reviewedAt,
    required int? daysSinceLastReview,
  }) {
    if (daysSinceLastReview != null && daysSinceLastReview < 1) {
      return _shortTermStability(state.stability!, rating);
    }
    final r = retrievability(state, reviewedAt);
    return _nextStability(
      difficulty: state.difficulty!,
      stability: state.stability!,
      retrievability: r,
      rating: rating,
    );
  }

  /// `(a + b) / 2.0` for [Duration]s -- Dart's [Duration] has no `/`
  /// operator, so this works in microseconds directly. Matches upstream's
  /// `(learning_steps[0] + learning_steps[1]) / 2.0` (the two-or-more-step
  /// Hard-on-first-step case).
  Duration _midpoint(Duration a, Duration b) =>
      Duration(microseconds: ((a.inMicroseconds + b.inMicroseconds) / 2).round());

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
