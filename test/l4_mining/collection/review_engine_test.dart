import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/mining_engine.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/review_engine.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/source_ref.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/srs_state.dart';
import 'package:japanese_immersion_reader/l5_srs/fsrs/fsrs_scheduler.dart';
import 'package:japanese_immersion_reader/l5_srs/fsrs/rating.dart';

/// A bare in-memory [MiningStore] -- same reasoning as
/// `mining_engine_test.dart`'s own `_FakeStore`: [ReviewEngine] needs
/// nothing but the abstract interface, so this suite never touches Drift.
class _FakeStore implements MiningStore {
  _FakeStore(this.id, [this.state]);

  @override
  final String id;

  SrsState? state;

  @override
  Future<SrsState?> readSrsState() async => state;

  @override
  Future<void> restoreSrsState(SrsState newState, DateTime timestamp) async {
    state = newState;
  }

  @override
  Future<void> insertFresh(SrsState newState, DateTime timestamp) async {
    state = newState;
  }

  @override
  Future<int> insertSighting(SourceRef source, DateTime timestamp) async => 1;

  @override
  Future<void> deleteSighting(int sightingId) async {}

  @override
  Future<void> deleteEntry() async {
    state = null;
  }
}

void main() {
  // Every rating graduates immediately -- isolates ReviewEngine's own
  // newCard/learning/review/relearning <-> FsrsState mapping and
  // lapse-counting logic from FsrsScheduler's own step-advancement
  // behavior, which `fsrs_scheduler_learning_steps_test.dart` already
  // covers directly and thoroughly.
  const engine = ReviewEngine(
    FsrsScheduler(learningSteps: [], relearningSteps: []),
  );
  final now = DateTime.utc(2026, 1, 1);

  test('reviewing a brand-new card sets its status to review and clears '
      'the newCard state', () async {
    final store = _FakeStore('id-1', SrsState.fresh(now));

    await engine.review(store, Rating.good, now: now);

    expect(store.state!.status, SrsStatus.review);
    expect(store.state!.step, isNull);
    expect(store.state!.difficulty, isNotNull);
    expect(store.state!.stability, isNotNull);
    expect(store.state!.lastReviewedAt, now);
    expect(store.state!.due.isAfter(now), isTrue);
  });

  test('reviewing throws if the store has no entry yet', () async {
    final store = _FakeStore('id-1');
    await expectLater(
      engine.review(store, Rating.good, now: now),
      throwsStateError,
    );
  });

  test('an Again rating on an already-reviewed card increments lapses', () async {
    final store = _FakeStore('id-1', SrsState.fresh(now));
    await engine.review(store, Rating.good, now: now);
    expect(store.state!.lapses, 0);

    final secondReviewAt = now.add(const Duration(days: 5));
    await engine.review(store, Rating.again, now: secondReviewAt);

    expect(store.state!.lapses, 1);
    expect(store.state!.status, SrsStatus.review);
  });

  test(
    'an Again rating on a brand-new (never-reviewed) card does not count as '
    'a lapse',
    () async {
      final store = _FakeStore('id-1', SrsState.fresh(now));

      await engine.review(store, Rating.again, now: now);

      expect(store.state!.lapses, 0);
    },
  );

  test('successive Good ratings grow the due date further out each time', () async {
    final store = _FakeStore('id-1', SrsState.fresh(now));

    await engine.review(store, Rating.good, now: now);
    final firstDue = store.state!.due;
    final firstGap = firstDue.difference(now);

    final secondReviewAt = firstDue;
    await engine.review(store, Rating.good, now: secondReviewAt);
    final secondGap = store.state!.due.difference(secondReviewAt);

    expect(secondGap, greaterThan(firstGap));
  });

  group('real learning/relearning steps (the default scheduler)', () {
    // ReviewEngine's own default -- real Anki-style sub-day steps, per the
    // scheduler's own default learningSteps/relearningSteps.
    const stepsEngine = ReviewEngine();

    test(
      'a Good rating on a brand-new card stays in learning, at a non-null '
      'step, not graduated to review yet',
      () async {
        final store = _FakeStore('id-1', SrsState.fresh(now));

        await stepsEngine.review(store, Rating.good, now: now);

        expect(store.state!.status, SrsStatus.learning);
        expect(store.state!.step, isNotNull);
        expect(store.state!.due.isBefore(now.add(const Duration(hours: 1))), isTrue);
      },
    );

    test('the step persists across calls and the card graduates once it '
        'reaches the last learning step', () async {
      final store = _FakeStore('id-1', SrsState.fresh(now));

      await stepsEngine.review(store, Rating.good, now: now);
      final afterFirst = store.state!;
      expect(afterFirst.status, SrsStatus.learning);
      final firstStep = afterFirst.step!;

      final secondReviewAt = afterFirst.due;
      await stepsEngine.review(store, Rating.good, now: secondReviewAt);

      expect(store.state!.status, SrsStatus.review);
      expect(store.state!.step, isNull);
      expect(firstStep, 1);
    });

    test(
      'an Easy rating graduates a brand-new card straight to review',
      () async {
        final store = _FakeStore('id-1', SrsState.fresh(now));

        await stepsEngine.review(store, Rating.easy, now: now);

        expect(store.state!.status, SrsStatus.review);
        expect(store.state!.step, isNull);
      },
    );

    test(
      'an Again rating on a review card with real relearning steps drops it '
      'into relearning (not straight back to review) and still counts as a '
      'lapse',
      () async {
        final store = _FakeStore('id-1', SrsState.fresh(now));
        await stepsEngine.review(store, Rating.easy, now: now);
        expect(store.state!.status, SrsStatus.review);

        final secondReviewAt = store.state!.due;
        await stepsEngine.review(store, Rating.again, now: secondReviewAt);

        expect(store.state!.status, SrsStatus.relearning);
        expect(store.state!.step, 0);
        expect(store.state!.lapses, 1);
      },
    );
  });
}
