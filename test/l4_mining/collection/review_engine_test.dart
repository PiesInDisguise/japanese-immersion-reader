import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/mining_engine.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/review_engine.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/source_ref.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/srs_state.dart';
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
  const engine = ReviewEngine();
  final now = DateTime.utc(2026, 1, 1);

  test('reviewing a brand-new card sets its status to review and clears '
      'the newCard state', () async {
    final store = _FakeStore('id-1', SrsState.fresh(now));

    await engine.review(store, Rating.good, now: now);

    expect(store.state!.status, SrsStatus.review);
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
}
