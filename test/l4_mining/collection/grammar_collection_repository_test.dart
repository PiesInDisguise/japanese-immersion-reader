// `isNull`/`isNotNull` hidden: drift's query-builder functions of the same
// name would otherwise collide with flutter_test's matchers below.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/grammar_collection_repository.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/source_ref.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/srs_state.dart';

// Mirrors test/l4_mining/collection/word_collection_repository_test.dart --
// spec §6: "the grammar side behaves identically" against the grammar
// dictionary, so this suite exercises the same scenarios against
// GrammarCollectionRepository instead of WordCollectionRepository.

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

Future<void> _forceSrsState(
  AppDatabase db,
  String id, {
  required int interval,
  required double ease,
  required DateTime due,
  required int lapses,
  required SrsStatus status,
}) {
  return (db.update(db.collectedGrammars)..where((g) => g.id.equals(id))).write(
    CollectedGrammarsCompanion(
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
  late GrammarCollectionRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = GrammarCollectionRepository(db);
  });

  tearDown(() => db.close());

  group('mine: fresh add', () {
    test('creates a new entry with placeholder-fresh SRS state and one '
        'sighting', () async {
      final result = await repo.mine(
        grammarPointId: 'te-form-request',
        source: _source,
      );

      expect(result.wasFreshAdd, isTrue);
      expect(result.previousSrsState, isNull);

      final rows = await db.select(db.collectedGrammars).get();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.id, result.entryId);
      expect(row.grammarPointId, 'te-form-request');
      expect(row.srsStatus, SrsStatus.newCard.name);
      expect(row.srsInterval, 0);
      expect(row.srsLapses, 0);
      expect(row.srsEase, 2.5);

      final sightings = await db.select(db.collectedGrammarSources).get();
      expect(sightings, hasLength(1));
      expect(sightings.single.id, result.sightingId);
      expect(sightings.single.collectedGrammarId, row.id);
      expect(sightings.single.workId, 'work-1');
      expect(sightings.single.sentenceId, 'sentence-1');
      expect(sightings.single.mediaType, CollectionMediaType.lightNovel.name);
    });

    test('the entry id is content-derived: mining the same grammarPointId '
        'again resolves to the same id', () async {
      final first = await repo.mine(
        grammarPointId: 'te-form-request',
        source: _source,
      );
      final second = await repo.mine(
        grammarPointId: 'te-form-request',
        source: _otherSource,
      );
      expect(second.entryId, first.entryId);
    });

    test('different grammarPointIds are different entries', () async {
      await repo.mine(grammarPointId: 'point-a', source: _source);
      await repo.mine(grammarPointId: 'point-b', source: _source);

      final rows = await db.select(db.collectedGrammars).get();
      expect(rows, hasLength(2));
    });
  });

  group('mine: re-tap resets an already-collected entry', () {
    test('appends a new source sighting AND resets SRS state to new', () async {
      final first = await repo.mine(
        grammarPointId: 'te-form-request',
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
        grammarPointId: 'te-form-request',
        source: _otherSource,
      );

      expect(second.wasFreshAdd, isFalse);
      expect(second.entryId, first.entryId);
      expect(second.previousSrsState, isNotNull);
      expect(second.previousSrsState!.interval, 10);
      expect(second.previousSrsState!.ease, 2.8);
      expect(second.previousSrsState!.lapses, 3);
      expect(second.previousSrsState!.status, SrsStatus.review);

      // Still exactly one CollectedGrammars row -- a reset, not a duplicate.
      final rows = await db.select(db.collectedGrammars).get();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.srsStatus, SrsStatus.newCard.name);
      expect(row.srsInterval, 0);
      expect(row.srsLapses, 0);
      expect(row.srsEase, 2.5);

      // Two sightings now: the original plus the one this reset added.
      final sightings = await db.select(db.collectedGrammarSources).get();
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
      await repo.mine(grammarPointId: 'point-a', source: _source);

      await repo.remove(grammarPointId: 'point-a');

      expect(await db.select(db.collectedGrammars).get(), isEmpty);
      expect(await db.select(db.collectedGrammarSources).get(), isEmpty);
    });

    test('removing something never collected is a harmless no-op', () async {
      await repo.remove(grammarPointId: 'nope');
      expect(await db.select(db.collectedGrammars).get(), isEmpty);
    });
  });

  group('undo', () {
    test('after a fresh add, fully deletes the entry', () async {
      final result = await repo.mine(
        grammarPointId: 'point-a',
        source: _source,
      );

      await repo.undo(result);

      expect(await db.select(db.collectedGrammars).get(), isEmpty);
      expect(await db.select(db.collectedGrammarSources).get(), isEmpty);
    });

    test(
      'after a reset, restores the prior SRS state and removes only the '
      "sighting that reset added -- the original sighting survives",
      () async {
        final first = await repo.mine(
          grammarPointId: 'point-a',
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
          grammarPointId: 'point-a',
          source: _otherSource,
        );

        await repo.undo(second);

        final rows = await db.select(db.collectedGrammars).get();
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

        final sightings = await db.select(db.collectedGrammarSources).get();
        expect(sightings, hasLength(1));
        expect(sightings.single.id, first.sightingId);
        expect(sightings.single.workId, 'work-1');
      },
    );
  });
}
