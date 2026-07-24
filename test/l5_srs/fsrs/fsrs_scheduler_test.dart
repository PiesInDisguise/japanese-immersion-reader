// Ground-truth values below were generated directly from the real
// `open-spaced-repetition/py-fsrs` reference package (`pip install fsrs`),
// not hand-computed -- `Scheduler(learning_steps=(), relearning_steps=(),
// enable_fuzzing=False)` reviewing a fresh `Card` through each sequence,
// dumping `card.difficulty`/`card.stability`/`(card.due - now).days` after
// every review. This is the actual cross-check for `FsrsScheduler` being a
// faithful port, not just "the analyzer is happy with the arithmetic".

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l5_srs/fsrs/fsrs_scheduler.dart';
import 'package:japanese_immersion_reader/l5_srs/fsrs/rating.dart';

void main() {
  final scheduler = const FsrsScheduler();
  final start = DateTime.utc(2026, 1, 1);

  group('FsrsScheduler against real py-fsrs reference output', () {
    test('single Again on a new card', () {
      final result = scheduler.review(
        const FsrsCardState(),
        Rating.again,
        now: start,
      );
      expect(result.difficulty, closeTo(6.4133, 1e-6));
      expect(result.stability, closeTo(0.212, 1e-6));
      expect(result.due.difference(start).inDays, 1);
    });

    test('single Hard on a new card', () {
      final result = scheduler.review(
        const FsrsCardState(),
        Rating.hard,
        now: start,
      );
      expect(result.difficulty, closeTo(5.112170705601056, 1e-6));
      expect(result.stability, closeTo(1.2931, 1e-6));
      expect(result.due.difference(start).inDays, 1);
    });

    test('single Good on a new card', () {
      final result = scheduler.review(
        const FsrsCardState(),
        Rating.good,
        now: start,
      );
      expect(result.difficulty, closeTo(2.118103970459016, 1e-6));
      expect(result.stability, closeTo(2.3065, 1e-6));
      expect(result.due.difference(start).inDays, 2);
    });

    test('single Easy on a new card', () {
      final result = scheduler.review(
        const FsrsCardState(),
        Rating.easy,
        now: start,
      );
      expect(result.difficulty, closeTo(1.0, 1e-6));
      expect(result.stability, closeTo(8.2956, 1e-6));
      expect(result.due.difference(start).inDays, 8);
    });

    test('Good then Good five days later', () {
      final first = scheduler.review(
        const FsrsCardState(),
        Rating.good,
        now: start,
      );
      expect(first.difficulty, closeTo(2.118103970459016, 1e-6));
      expect(first.stability, closeTo(2.3065, 1e-6));
      expect(first.due.difference(start).inDays, 2);

      final secondReviewedAt = start.add(const Duration(days: 5));
      final second = scheduler.review(
        FsrsCardState(
          difficulty: first.difficulty,
          stability: first.stability,
          lastReviewedAt: first.reviewedAt,
        ),
        Rating.good,
        now: secondReviewedAt,
      );
      expect(second.difficulty, closeTo(2.111214235785395, 1e-6));
      expect(second.stability, closeTo(18.167850235070937, 1e-4));
      expect(second.due.difference(secondReviewedAt).inDays, 18);
    });

    test('Good then a lapse (Again) five days later', () {
      final first = scheduler.review(
        const FsrsCardState(),
        Rating.good,
        now: start,
      );
      final secondReviewedAt = start.add(const Duration(days: 5));
      final second = scheduler.review(
        FsrsCardState(
          difficulty: first.difficulty,
          stability: first.stability,
          lastReviewedAt: first.reviewedAt,
        ),
        Rating.again,
        now: secondReviewedAt,
      );
      expect(second.difficulty, closeTo(7.394502741279718, 1e-6));
      expect(second.stability, closeTo(0.6825982499532058, 1e-6));
      expect(second.due.difference(secondReviewedAt).inDays, 1);
    });

    test('three Goods in a row grows the interval each time', () {
      var state = const FsrsCardState();
      var reviewedAt = start;

      var result = scheduler.review(state, Rating.good, now: reviewedAt);
      expect(result.stability, closeTo(2.3065, 1e-6));
      expect(result.due.difference(reviewedAt).inDays, 2);

      state = FsrsCardState(
        difficulty: result.difficulty,
        stability: result.stability,
        lastReviewedAt: result.reviewedAt,
      );
      reviewedAt = reviewedAt.add(const Duration(days: 3));
      result = scheduler.review(state, Rating.good, now: reviewedAt);
      expect(result.difficulty, closeTo(2.111214235785395, 1e-6));
      expect(result.stability, closeTo(13.826903694354568, 1e-4));
      expect(result.due.difference(reviewedAt).inDays, 14);

      state = FsrsCardState(
        difficulty: result.difficulty,
        stability: result.stability,
        lastReviewedAt: result.reviewedAt,
      );
      reviewedAt = reviewedAt.add(const Duration(days: 10));
      result = scheduler.review(state, Rating.good, now: reviewedAt);
      expect(result.difficulty, closeTo(2.1043313908464483, 1e-6));
      expect(result.stability, closeTo(47.45203372847688, 1e-3));
      expect(result.due.difference(reviewedAt).inDays, 47);
    });

    test('Easy then Hard twenty days later', () {
      final first = scheduler.review(
        const FsrsCardState(),
        Rating.easy,
        now: start,
      );
      expect(first.stability, closeTo(8.2956, 1e-6));
      expect(first.due.difference(start).inDays, 8);

      final secondReviewedAt = start.add(const Duration(days: 20));
      final second = scheduler.review(
        FsrsCardState(
          difficulty: first.difficulty,
          stability: first.stability,
          lastReviewedAt: first.reviewedAt,
        ),
        Rating.hard,
        now: secondReviewedAt,
      );
      expect(second.difficulty, closeTo(4.010608969296839, 1e-6));
      expect(second.stability, closeTo(41.46289254771566, 1e-3));
      expect(second.due.difference(secondReviewedAt).inDays, 41);
    });
  });

  group('FsrsScheduler general properties', () {
    test('retrievability is 0 for a never-reviewed card', () {
      expect(scheduler.retrievability(const FsrsCardState(), start), 0);
    });

    test('retrievability decays as elapsed time grows', () {
      final state = FsrsCardState(
        difficulty: 5.0,
        stability: 10.0,
        lastReviewedAt: start,
      );
      final soon = scheduler.retrievability(
        state,
        start.add(const Duration(days: 1)),
      );
      final later = scheduler.retrievability(
        state,
        start.add(const Duration(days: 30)),
      );
      expect(soon, greaterThan(later));
      expect(soon, lessThanOrEqualTo(1.0));
      expect(later, greaterThanOrEqualTo(0.0));
    });

    test('a higher rating never produces a shorter interval than a lower one', () {
      final again = scheduler.review(
        const FsrsCardState(),
        Rating.again,
        now: start,
      );
      final hard = scheduler.review(
        const FsrsCardState(),
        Rating.hard,
        now: start,
      );
      final good = scheduler.review(
        const FsrsCardState(),
        Rating.good,
        now: start,
      );
      final easy = scheduler.review(
        const FsrsCardState(),
        Rating.easy,
        now: start,
      );

      expect(again.stability, lessThanOrEqualTo(hard.stability));
      expect(hard.stability, lessThanOrEqualTo(good.stability));
      expect(good.stability, lessThanOrEqualTo(easy.stability));
    });
  });
}
