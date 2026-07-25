import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/mining_engine.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/source_ref.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/srs_state.dart';

/// A bare in-memory [MiningStore] with no Drift/SQLite involved at all --
/// used to unit-test [MiningEngine]'s mine/remove/undo decision logic in
/// total isolation. That this is even possible (the engine needs nothing
/// but the abstract interface) is itself the evidence that
/// `WordCollectionRepository` and `GrammarCollectionRepository` share one
/// state machine rather than each hand-rolling their own copy of it: both
/// just plug a Drift-backed version of this same interface into the one
/// [MiningEngine] exercised here.
class _FakeStore implements MiningStore {
  _FakeStore(this.id);

  @override
  final String id;

  SrsState? state;
  final List<_Sighting> sightings = [];
  int _nextSightingId = 1;
  bool deleted = false;

  @override
  Future<SrsState?> readSrsState() async => state;

  @override
  Future<void> insertFresh(SrsState newState, DateTime timestamp) async {
    state = newState;
    deleted = false;
  }

  @override
  Future<void> restoreSrsState(SrsState newState, DateTime timestamp) async {
    state = newState;
  }

  @override
  Future<int> insertSighting(SourceRef source, DateTime timestamp) async {
    final sightingId = _nextSightingId++;
    sightings.add(_Sighting(sightingId, source));
    return sightingId;
  }

  @override
  Future<void> deleteSighting(int sightingId) async {
    sightings.removeWhere((s) => s.id == sightingId);
  }

  @override
  Future<void> deleteEntry() async {
    state = null;
    sightings.clear();
    deleted = true;
  }
}

class _Sighting {
  _Sighting(this.id, this.source);
  final int id;
  final SourceRef source;
}

void main() {
  const engine = MiningEngine();
  const source = SourceRef(
    workId: 'w',
    sentenceId: 's',
    mediaType: CollectionMediaType.lightNovel,
  );

  test(
    'mine on an empty store creates a fresh entry with one sighting',
    () async {
      final store = _FakeStore('id-1');

      final result = await engine.mine(store, source: source);

      expect(result.wasFreshAdd, isTrue);
      expect(result.entryId, 'id-1');
      expect(result.previousSrsState, isNull);
      expect(store.state!.status, SrsStatus.newCard);
      expect(store.state!.stability, isNull);
      expect(store.state!.difficulty, isNull);
      expect(store.state!.lapses, 0);
      expect(store.sightings, hasLength(1));
      expect(result.sightingId, store.sightings.single.id);
    },
  );

  test('mine on an already-collected store appends a sighting and resets '
      'SRS state, returning the prior state for undo', () async {
    final store = _FakeStore('id-1');
    final originalDue = DateTime.utc(2020, 1, 1);
    store.state = SrsState(
      difficulty: 6.0,
      stability: 20.0,
      due: originalDue,
      lapses: 4,
      status: SrsStatus.review,
      lastReviewedAt: DateTime.utc(2019, 12, 20),
      step: null,
    );
    final firstSightingId = await store.insertSighting(
      source,
      DateTime.utc(2020, 1, 1),
    );

    final result = await engine.mine(store, source: source);

    expect(result.wasFreshAdd, isFalse);
    expect(result.previousSrsState, isNotNull);
    expect(result.previousSrsState!.stability, 20.0);
    expect(result.previousSrsState!.status, SrsStatus.review);
    expect(store.state!.status, SrsStatus.newCard);
    expect(store.state!.stability, isNull);
    expect(store.sightings, hasLength(2));
    expect(store.sightings.map((s) => s.id), contains(firstSightingId));
  });

  test('undo after a fresh add deletes the entry entirely', () async {
    final store = _FakeStore('id-1');
    final result = await engine.mine(store, source: source);

    await engine.undo(store, result);

    expect(store.deleted, isTrue);
    expect(store.state, isNull);
    expect(store.sightings, isEmpty);
  });

  test('undo after a reset restores the prior SRS state and drops only the '
      'sighting the reset added', () async {
    final store = _FakeStore('id-1');
    final originalDue = DateTime.utc(2020, 1, 1);
    store.state = SrsState(
      difficulty: 6.0,
      stability: 20.0,
      due: originalDue,
      lapses: 4,
      status: SrsStatus.review,
      lastReviewedAt: DateTime.utc(2019, 12, 20),
      step: null,
    );
    final firstSightingId = await store.insertSighting(
      source,
      DateTime.utc(2020, 1, 1),
    );

    final result = await engine.mine(store, source: source);
    await engine.undo(store, result);

    expect(store.deleted, isFalse);
    expect(store.state!.stability, 20.0);
    expect(store.state!.difficulty, 6.0);
    expect(store.state!.due, originalDue);
    expect(store.state!.lapses, 4);
    expect(store.state!.status, SrsStatus.review);
    expect(store.sightings, hasLength(1));
    expect(store.sightings.single.id, firstSightingId);
  });

  test('remove deletes the entry regardless of prior state', () async {
    final store = _FakeStore('id-1');
    await engine.mine(store, source: source);

    await engine.remove(store);

    expect(store.deleted, isTrue);
    expect(store.state, isNull);
  });
}
