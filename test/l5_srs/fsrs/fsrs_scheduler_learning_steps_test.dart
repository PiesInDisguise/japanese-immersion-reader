// Ground-truth values below were generated directly from the real
// `open-spaced-repetition/py-fsrs` reference package (`pip install fsrs`),
// the same rigor `fsrs_scheduler_test.dart`'s own header describes --
// `Scheduler(enable_fuzzing=False)` (real *default* learning_steps=(1m,10m)/
// relearning_steps=(10m,)) reviewing a fresh `Card` through each sequence,
// dumping `card.state`/`card.step`/`card.difficulty`/`card.stability`/
// `(card.due - review_datetime).total_seconds()` after every review.

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l5_srs/fsrs/fsrs_scheduler.dart';
import 'package:japanese_immersion_reader/l5_srs/fsrs/rating.dart';

void main() {
  // Real default learning/relearning steps -- FsrsScheduler's own
  // constructor defaults, exercised explicitly here (not implicitly) so
  // this file's intent reads clearly even if the defaults ever change.
  final scheduler = const FsrsScheduler();
  final start = DateTime.utc(2026, 1, 1);

  group('learning steps (fresh card)', () {
    test('Again keeps it in Learning at step 0, due in learningSteps[0] (1m)', () {
      final result = scheduler.review(
        const FsrsCardState(),
        Rating.again,
        now: start,
      );
      expect(result.state, FsrsState.learning);
      expect(result.step, 0);
      expect(result.difficulty, closeTo(6.4133, 1e-6));
      expect(result.stability, closeTo(0.212, 1e-6));
      expect(result.due.difference(start), const Duration(minutes: 1));
    });

    test(
      'Hard keeps it in Learning at step 0, due at the midpoint of the '
      'first two steps (5.5m)',
      () {
        final result = scheduler.review(
          const FsrsCardState(),
          Rating.hard,
          now: start,
        );
        expect(result.state, FsrsState.learning);
        expect(result.step, 0);
        expect(result.difficulty, closeTo(5.112170705601056, 1e-6));
        expect(result.stability, closeTo(1.2931, 1e-6));
        expect(result.due.difference(start), const Duration(seconds: 330));
      },
    );

    test(
      'Good advances it to step 1, due in learningSteps[1] (10m) -- not '
      'graduated yet',
      () {
        final result = scheduler.review(
          const FsrsCardState(),
          Rating.good,
          now: start,
        );
        expect(result.state, FsrsState.learning);
        expect(result.step, 1);
        expect(result.difficulty, closeTo(2.118103970459016, 1e-6));
        expect(result.stability, closeTo(2.3065, 1e-6));
        expect(result.due.difference(start), const Duration(minutes: 10));
      },
    );

    test('Easy graduates it straight to Review', () {
      final result = scheduler.review(
        const FsrsCardState(),
        Rating.easy,
        now: start,
      );
      expect(result.state, FsrsState.review);
      expect(result.step, isNull);
      expect(result.difficulty, closeTo(1.0, 1e-6));
      expect(result.stability, closeTo(8.2956, 1e-6));
      expect(result.due.difference(start).inDays, 8);
    });

    test('Good then Good (the last step) graduates it to Review', () {
      final first = scheduler.review(
        const FsrsCardState(),
        Rating.good,
        now: start,
      );
      expect(first.state, FsrsState.learning);
      expect(first.step, 1);

      final secondReviewedAt = start.add(const Duration(minutes: 10));
      final second = scheduler.review(
        FsrsCardState(
          difficulty: first.difficulty,
          stability: first.stability,
          lastReviewedAt: first.reviewedAt,
          state: first.state,
          step: first.step,
        ),
        Rating.good,
        now: secondReviewedAt,
      );
      expect(second.state, FsrsState.review);
      expect(second.step, isNull);
      expect(second.difficulty, closeTo(2.111214235785395, 1e-6));
      expect(second.stability, closeTo(2.3065, 1e-6));
      expect(second.due.difference(secondReviewedAt).inDays, 2);
    });
  });

  group('relearning steps (a graduated Review card lapses)', () {
    test(
      'Again on a Review card drops it into Relearning at step 0, due in '
      'relearningSteps[0] (10m)',
      () {
        final first = scheduler.review(
          const FsrsCardState(),
          Rating.good,
          now: start,
        );
        final secondReviewedAt = start.add(const Duration(minutes: 10));
        final second = scheduler.review(
          FsrsCardState(
            difficulty: first.difficulty,
            stability: first.stability,
            lastReviewedAt: first.reviewedAt,
            state: first.state,
            step: first.step,
          ),
          Rating.good,
          now: secondReviewedAt,
        );
        expect(second.state, FsrsState.review);

        final thirdReviewedAt = secondReviewedAt.add(const Duration(days: 5));
        final third = scheduler.review(
          FsrsCardState(
            difficulty: second.difficulty,
            stability: second.stability,
            lastReviewedAt: second.reviewedAt,
            state: second.state,
            step: second.step,
          ),
          Rating.again,
          now: thirdReviewedAt,
        );
        expect(third.state, FsrsState.relearning);
        expect(third.step, 0);
        expect(third.difficulty, closeTo(7.392238132342694, 1e-6));
        expect(third.stability, closeTo(0.6827348149809292, 1e-6));
        expect(
          third.due.difference(thirdReviewedAt),
          const Duration(minutes: 10),
        );

        // Good on Relearning's only step re-graduates back to Review.
        final fourthReviewedAt = thirdReviewedAt.add(
          const Duration(minutes: 10),
        );
        final fourth = scheduler.review(
          FsrsCardState(
            difficulty: third.difficulty,
            stability: third.stability,
            lastReviewedAt: third.reviewedAt,
            state: third.state,
            step: third.step,
          ),
          Rating.good,
          now: fourthReviewedAt,
        );
        expect(fourth.state, FsrsState.review);
        expect(fourth.step, isNull);
        expect(fourth.difficulty, closeTo(7.38007426350719, 1e-6));
        expect(fourth.stability, closeTo(0.7356062635198228, 1e-6));
        expect(fourth.due.difference(fourthReviewedAt).inDays, 1);
      },
    );
  });

  group('disabling steps preserves the old immediate-graduate behavior', () {
    test('an empty learningSteps list graduates every rating immediately', () {
      final noSteps = const FsrsScheduler(
        learningSteps: [],
        relearningSteps: [],
      );
      final result = noSteps.review(
        const FsrsCardState(),
        Rating.again,
        now: start,
      );
      expect(result.state, FsrsState.review);
      expect(result.step, isNull);
    });
  });
}
