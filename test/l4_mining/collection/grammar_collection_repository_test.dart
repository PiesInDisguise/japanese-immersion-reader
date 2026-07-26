// `isNull`/`isNotNull` hidden: drift's query-builder functions of the same
// name would otherwise collide with flutter_test's matchers below.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/grammar_collection_repository.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/source_ref.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/srs_state.dart';
import 'package:japanese_immersion_reader/l5_srs/fsrs/rating.dart';

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
  required double difficulty,
  required double stability,
  required DateTime due,
  required int lapses,
  required SrsStatus status,
}) {
  return (db.update(db.collectedGrammars)..where((g) => g.id.equals(id))).write(
    CollectedGrammarsCompanion(
      fsrsDifficulty: Value(difficulty),
      fsrsStability: Value(stability),
      srsDue: Value(due),
      srsLapses: Value(lapses),
      srsStatus: Value(status.name),
      lastReviewedAt: Value(due.subtract(const Duration(days: 1))),
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
      expect(row.fsrsDifficulty, isNull);
      expect(row.fsrsStability, isNull);
      expect(row.srsLapses, 0);

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
        difficulty: 6.0,
        stability: 10.0,
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
      expect(second.previousSrsState!.stability, 10.0);
      expect(second.previousSrsState!.difficulty, 6.0);
      expect(second.previousSrsState!.lapses, 3);
      expect(second.previousSrsState!.status, SrsStatus.review);

      // Still exactly one CollectedGrammars row -- a reset, not a duplicate.
      final rows = await db.select(db.collectedGrammars).get();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.srsStatus, SrsStatus.newCard.name);
      expect(row.fsrsDifficulty, isNull);
      expect(row.fsrsStability, isNull);
      expect(row.srsLapses, 0);

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
          difficulty: 6.0,
          stability: 10.0,
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
        expect(row.fsrsStability, 10.0);
        expect(row.fsrsDifficulty, 6.0);
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

  group('due', () {
    test('returns only entries due on or before now, earliest first', () async {
      final overdue = await repo.mine(
        grammarPointId: 'point-overdue',
        source: _source,
      );
      final dueNow = await repo.mine(
        grammarPointId: 'point-due-now',
        source: _source,
      );
      final notYetDue = await repo.mine(
        grammarPointId: 'point-not-yet',
        source: _source,
      );

      final now = DateTime.utc(2026, 1, 10);
      await _forceSrsState(
        db,
        overdue.entryId,
        difficulty: 5,
        stability: 5,
        due: DateTime.utc(2026, 1, 1),
        lapses: 0,
        status: SrsStatus.review,
      );
      await _forceSrsState(
        db,
        dueNow.entryId,
        difficulty: 5,
        stability: 5,
        due: now,
        lapses: 0,
        status: SrsStatus.review,
      );
      await _forceSrsState(
        db,
        notYetDue.entryId,
        difficulty: 5,
        stability: 5,
        due: DateTime.utc(2026, 2, 1),
        lapses: 0,
        status: SrsStatus.review,
      );

      final due = await repo.due(now: now);

      expect(due.map((d) => d.id), [overdue.entryId, dueNow.entryId]);
    });
  });

  group('dueForWork', () {
    test('only returns due grammar points sighted in the given book, earliest '
        'first', () async {
      final inWorkOne = await repo.mine(
        grammarPointId: 'point-a',
        source: _source, // workId: 'work-1'
      );
      final inWorkTwo = await repo.mine(
        grammarPointId: 'point-b',
        source: _otherSource, // workId: 'work-2'
      );
      final now = DateTime.utc(2026, 1, 10);
      await _forceSrsState(
        db,
        inWorkOne.entryId,
        difficulty: 5,
        stability: 5,
        due: DateTime.utc(2026, 1, 1),
        lapses: 0,
        status: SrsStatus.review,
      );
      await _forceSrsState(
        db,
        inWorkTwo.entryId,
        difficulty: 5,
        stability: 5,
        due: DateTime.utc(2026, 1, 1),
        lapses: 0,
        status: SrsStatus.review,
      );

      final dueInWorkOne = await repo.dueForWork('work-1', now: now);
      expect(dueInWorkOne.map((d) => d.id), [inWorkOne.entryId]);

      final dueInWorkTwo = await repo.dueForWork('work-2', now: now);
      expect(dueInWorkTwo.map((d) => d.id), [inWorkTwo.entryId]);
    });

    test('excludes grammar points not yet due', () async {
      final result = await repo.mine(
        grammarPointId: 'point-a',
        source: _source,
      );
      await _forceSrsState(
        db,
        result.entryId,
        difficulty: 5,
        stability: 5,
        due: DateTime.utc(2030, 1, 1),
        lapses: 0,
        status: SrsStatus.review,
      );

      final due = await repo.dueForWork(
        'work-1',
        now: DateTime.utc(2026, 1, 10),
      );

      expect(due, isEmpty);
    });
  });

  group('review', () {
    test(
      'scores a due grammar point via the real FSRS scheduler and reschedules '
      'it',
      () async {
        final result = await repo.mine(
          grammarPointId: 'point-a',
          source: _source,
        );
        final reviewedAt = DateTime.utc(2026, 1, 1);

        await repo.review(result.entryId, Rating.good, now: reviewedAt);

        final row = await (db.select(
          db.collectedGrammars,
        )..where((g) => g.id.equals(result.entryId))).getSingle();
        // A single Good rating on a brand-new card advances it one real
        // Anki-style learning step -- it does not graduate straight to
        // `review` (that needs an Easy, or a Good on the last step; see
        // `fsrs_scheduler_learning_steps_test.dart` for the
        // scheduler-level coverage of that).
        expect(row.srsStatus, SrsStatus.learning.name);
        expect(row.srsStep, isNotNull);
        expect(row.fsrsDifficulty, isNotNull);
        expect(row.fsrsStability, isNotNull);
        expect(row.srsDue.isAfter(reviewedAt), isTrue);
        expect(row.lastReviewedAt!.isAtSameMomentAs(reviewedAt), isTrue);
      },
    );
  });

  group('latestSightingSentenceId', () {
    test('returns the most recently mined sighting\'s sentence id', () async {
      final result = await repo.mine(
        grammarPointId: 'point-a',
        source: _source,
      );
      await _forceSrsState(
        db,
        result.entryId,
        difficulty: 5,
        stability: 5,
        due: DateTime.utc(2026, 1, 1),
        lapses: 0,
        status: SrsStatus.review,
      );
      await repo.mine(grammarPointId: 'point-a', source: _otherSource);

      expect(await repo.latestSightingSentenceId(result.entryId), 'sentence-2');
    });

    test('returns null for an id with no sightings', () async {
      expect(await repo.latestSightingSentenceId('no-such-id'), isNull);
    });
  });
}
