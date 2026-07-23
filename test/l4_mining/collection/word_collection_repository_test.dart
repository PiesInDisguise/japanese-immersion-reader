import 'dart:convert';

// `isNull`/`isNotNull` hidden: drift's query-builder functions of the same
// name would otherwise collide with flutter_test's matchers below.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/source_ref.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/srs_state.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/word_collection_repository.dart';

const _source = SourceRef(
  workId: 'work-1',
  sentenceId: 'sentence-1',
  mediaType: CollectionMediaType.lightNovel,
);

const _otherSource = SourceRef(
  workId: 'work-2',
  sentenceId: 'sentence-2',
  mediaType: CollectionMediaType.manga,
);

/// Simulates "this word has already been reviewed a few times" so a
/// reset-tap's before/after SRS values are distinguishable from a fresh
/// entry's placeholder defaults.
Future<void> _forceSrsState(
  AppDatabase db,
  String id, {
  required int interval,
  required double ease,
  required DateTime due,
  required int lapses,
  required SrsStatus status,
}) {
  return (db.update(db.collectedWords)..where((w) => w.id.equals(id))).write(
    CollectedWordsCompanion(
      srsInterval: Value(interval),
      srsEase: Value(ease),
      srsDue: Value(due),
      srsLapses: Value(lapses),
      srsStatus: Value(status.name),
    ),
  );
}

void main() {
  late AppDatabase db;
  late WordCollectionRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WordCollectionRepository(db);
  });

  tearDown(() => db.close());

  group('mine: fresh add', () {
    test('creates a new entry with placeholder-fresh SRS state and one '
        'sighting', () async {
      final result = await repo.mine(
        dictForm: '食べる',
        reading: 'たべる',
        senseIds: [1, 2],
        source: _source,
      );

      expect(result.wasFreshAdd, isTrue);
      expect(result.previousSrsState, isNull);

      final rows = await db.select(db.collectedWords).get();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.id, result.entryId);
      expect(row.dictForm, '食べる');
      expect(row.reading, 'たべる');
      expect(jsonDecode(row.senseIdsJson), [1, 2]);
      expect(row.srsStatus, SrsStatus.newCard.name);
      expect(row.srsInterval, 0);
      expect(row.srsLapses, 0);
      expect(row.srsEase, 2.5);

      final sightings = await db.select(db.collectedWordSources).get();
      expect(sightings, hasLength(1));
      expect(sightings.single.id, result.sightingId);
      expect(sightings.single.collectedWordId, row.id);
      expect(sightings.single.workId, 'work-1');
      expect(sightings.single.sentenceId, 'sentence-1');
      expect(sightings.single.mediaType, CollectionMediaType.lightNovel.name);
    });

    test('the entry id is content-derived: mining the same dictForm+reading '
        'pair again resolves to the same id', () async {
      final first = await repo.mine(
        dictForm: 'X',
        reading: 'Y',
        senseIds: const [],
        source: _source,
      );
      final second = await repo.mine(
        dictForm: 'X',
        reading: 'Y',
        senseIds: const [],
        source: _otherSource,
      );
      expect(second.entryId, first.entryId);
    });

    test('different dictForm/reading pairs are different entries', () async {
      await repo.mine(
        dictForm: 'X',
        reading: 'Y',
        senseIds: const [],
        source: _source,
      );
      await repo.mine(
        dictForm: 'X',
        reading: 'Z',
        senseIds: const [],
        source: _source,
      );

      final rows = await db.select(db.collectedWords).get();
      expect(rows, hasLength(2));
    });
  });

  group('mine: re-tap resets an already-collected entry', () {
    test('appends a new source sighting AND resets SRS state to new, without '
        'touching senseIds', () async {
      final first = await repo.mine(
        dictForm: '食べる',
        reading: 'たべる',
        senseIds: [1],
        source: _source,
      );
      await _forceSrsState(
        db,
        first.entryId,
        interval: 10,
        ease: 2.8,
        due: DateTime.utc(2030, 1, 1),
        lapses: 3,
        status: SrsStatus.review,
      );

      final second = await repo.mine(
        dictForm: '食べる',
        reading: 'たべる',
        senseIds: [99],
        source: _otherSource,
      );

      expect(second.wasFreshAdd, isFalse);
      expect(second.entryId, first.entryId);
      expect(second.previousSrsState, isNotNull);
      expect(second.previousSrsState!.interval, 10);
      expect(second.previousSrsState!.ease, 2.8);
      expect(second.previousSrsState!.lapses, 3);
      expect(second.previousSrsState!.status, SrsStatus.review);

      // Still exactly one CollectedWords row -- a reset, not a duplicate.
      final rows = await db.select(db.collectedWords).get();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.srsStatus, SrsStatus.newCard.name);
      expect(row.srsInterval, 0);
      expect(row.srsLapses, 0);
      expect(row.srsEase, 2.5);

      // senseIds is a fresh-add-only field; a reset must not touch it.
      expect(jsonDecode(row.senseIdsJson), [1]);

      // Two sightings now: the original plus the one this reset added.
      final sightings = await db.select(db.collectedWordSources).get();
      expect(sightings, hasLength(2));
      expect(sightings.map((s) => s.workId), containsAll(['work-1', 'work-2']));
      expect(
        sightings.firstWhere((s) => s.workId == 'work-2').id,
        second.sightingId,
      );
    });
  });

  group('remove', () {
    test('deletes the entry and all of its sightings', () async {
      await repo.mine(
        dictForm: 'X',
        reading: 'Y',
        senseIds: const [],
        source: _source,
      );

      await repo.remove(dictForm: 'X', reading: 'Y');

      expect(await db.select(db.collectedWords).get(), isEmpty);
      expect(await db.select(db.collectedWordSources).get(), isEmpty);
    });

    test('removing something never collected is a harmless no-op', () async {
      await repo.remove(dictForm: 'nope', reading: 'nope');
      expect(await db.select(db.collectedWords).get(), isEmpty);
    });
  });

  group('undo', () {
    test('after a fresh add, fully deletes the entry', () async {
      final result = await repo.mine(
        dictForm: 'X',
        reading: 'Y',
        senseIds: [1],
        source: _source,
      );

      await repo.undo(result);

      expect(await db.select(db.collectedWords).get(), isEmpty);
      expect(await db.select(db.collectedWordSources).get(), isEmpty);
    });

    test(
      'after a reset, restores the prior SRS state and removes only the '
      "sighting that reset added -- the original sighting survives",
      () async {
        final first = await repo.mine(
          dictForm: 'X',
          reading: 'Y',
          senseIds: [1],
          source: _source,
        );
        await _forceSrsState(
          db,
          first.entryId,
          interval: 10,
          ease: 2.8,
          due: DateTime.utc(2030, 1, 1),
          lapses: 3,
          status: SrsStatus.review,
        );

        final second = await repo.mine(
          dictForm: 'X',
          reading: 'Y',
          senseIds: [2],
          source: _otherSource,
        );

        await repo.undo(second);

        final rows = await db.select(db.collectedWords).get();
        expect(rows, hasLength(1));
        final row = rows.single;
        expect(row.srsInterval, 10);
        expect(row.srsEase, 2.8);
        // isAtSameMomentAs, not `==`: Drift reads DateTimeColumn values back
        // as local time, and DateTime's `==` (unlike isAtSameMomentAs) treats
        // a UTC instant and the same instant in local time as unequal.
        expect(row.srsDue.isAtSameMomentAs(DateTime.utc(2030, 1, 1)), isTrue);
        expect(row.srsLapses, 3);
        expect(row.srsStatus, SrsStatus.review.name);

        final sightings = await db.select(db.collectedWordSources).get();
        expect(sightings, hasLength(1));
        expect(sightings.single.id, first.sightingId);
        expect(sightings.single.workId, 'work-1');
      },
    );
  });
}
