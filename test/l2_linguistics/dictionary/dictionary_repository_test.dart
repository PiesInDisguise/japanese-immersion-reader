import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_repository.dart';

final _epoch = DateTime.utc(2026, 1, 1);

Future<void> _insertDictionary(
  AppDatabase db, {
  required String id,
  required int priority,
  bool enabled = true,
  String title = 'Test Dictionary',
}) {
  return db
      .into(db.dictionaries)
      .insert(
        DictionariesCompanion.insert(
          id: id,
          title: title,
          revision: '1',
          formatVersion: 3,
          priority: priority,
          enabled: Value(enabled),
          addedAt: _epoch,
          updatedAt: _epoch,
        ),
      );
}

Future<void> _insertTerm(
  AppDatabase db, {
  required String dictionaryId,
  required String headword,
  String? reading,
  String rules = '',
  double score = 0,
  int sequence = 0,
  int importOrder = 0,
}) {
  return db
      .into(db.dictionaryTermEntries)
      .insert(
        DictionaryTermEntriesCompanion.insert(
          dictionaryId: dictionaryId,
          headword: headword,
          reading: reading ?? '',
          readingNormalized: (reading == null || reading.isEmpty)
              ? headword
              : reading,
          rules: rules,
          score: score,
          definitionsJson: '["def"]',
          sequence: sequence,
          termTags: '',
          importOrder: importOrder,
        ),
      );
}

void main() {
  late AppDatabase db;
  late DictionaryRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DictionaryRepository(db);
  });

  tearDown(() => db.close());

  group('tier 1: dictionary form', () {
    test('a dictForm hit merges matches across all enabled dictionaries, '
        'ordered by dictionary priority', () async {
      await _insertDictionary(db, id: 'dictA', priority: 0);
      await _insertDictionary(db, id: 'dictB', priority: 1);
      await _insertTerm(db, dictionaryId: 'dictA', headword: '食べる');
      await _insertTerm(db, dictionaryId: 'dictB', headword: '食べる');

      final hits = await repo.lookup(dictForm: '食べる', surfaceForm: '食べた');

      expect(hits, hasLength(2));
      expect(
        hits.every((h) => h.matchedVia == MatchTier.dictionaryForm),
        isTrue,
      );
      expect(hits[0].dictionaryId, 'dictA');
      expect(hits[1].dictionaryId, 'dictB');
    });

    test('a disabled dictionary never contributes a hit', () async {
      await _insertDictionary(db, id: 'dictA', priority: 0, enabled: false);
      await _insertTerm(db, dictionaryId: 'dictA', headword: '食べる');

      final hits = await repo.lookup(dictForm: '食べる', surfaceForm: '食べる');
      expect(hits, isEmpty);
    });

    test(
      'a term matched by both headword and reading appears only once',
      () async {
        await _insertDictionary(db, id: 'dictA', priority: 0);
        await _insertTerm(
          db,
          dictionaryId: 'dictA',
          headword: '打つ',
          reading: 'うつ',
        );

        final hits = await repo.lookup(
          dictForm: '打つ',
          surfaceForm: '打つ',
          reading: 'うつ',
        );
        expect(hits, hasLength(1));
      },
    );

    test('reading alone (no headword match) still finds a hit', () async {
      await _insertDictionary(db, id: 'dictA', priority: 0);
      await _insertTerm(
        db,
        dictionaryId: 'dictA',
        headword: '打つ',
        reading: 'うつ',
      );

      final hits = await repo.lookup(
        dictForm: 'NO_HEADWORD_MATCH',
        surfaceForm: 'NO_HEADWORD_MATCH',
        reading: 'うつ',
      );
      expect(hits, hasLength(1));
      expect(hits.single.term.headword, '打つ');
    });

    test(
      'a katakana reading (Sudachi\'s own convention) still matches a '
      'hiragana-only headword-less lookup, converted before comparison',
      () async {
        await _insertDictionary(db, id: 'dictA', priority: 0);
        await _insertTerm(
          db,
          dictionaryId: 'dictA',
          headword: '打つ',
          reading: 'うつ',
        );

        final hits = await repo.lookup(
          dictForm: 'NO_HEADWORD_MATCH',
          surfaceForm: 'NO_HEADWORD_MATCH',
          reading: 'ウツ', // katakana, as a real Sudachi token would supply
        );
        expect(hits, hasLength(1));
        expect(hits.single.term.headword, '打つ');
      },
    );

    test('within one dictionary, higher score sorts first; ties break on '
        'importOrder ascending', () async {
      await _insertDictionary(db, id: 'dictA', priority: 0);
      await _insertTerm(
        db,
        dictionaryId: 'dictA',
        headword: 'X',
        score: 5,
        importOrder: 5,
      );
      await _insertTerm(
        db,
        dictionaryId: 'dictA',
        headword: 'X',
        score: 10,
        importOrder: 2,
      );
      await _insertTerm(
        db,
        dictionaryId: 'dictA',
        headword: 'X',
        score: 10,
        importOrder: 1,
      );

      final hits = await repo.lookup(dictForm: 'X', surfaceForm: 'X');
      expect(hits, hasLength(3));
      expect(hits[0].term.score, 10.0);
      expect(hits[0].term.importOrder, 1); // tie broken by importOrder
      expect(hits[1].term.score, 10.0);
      expect(hits[1].term.importOrder, 2);
      expect(hits[2].term.score, 5.0);
    });
  });

  group('tier 2: surface form fallback', () {
    test('falls back to the surface form when dictForm has no match', () async {
      await _insertDictionary(db, id: 'dictA', priority: 0);
      await _insertTerm(db, dictionaryId: 'dictA', headword: '食べた');

      final hits = await repo.lookup(
        dictForm: 'NOT_A_REAL_DICT_FORM',
        surfaceForm: '食べた',
      );
      expect(hits, hasLength(1));
      expect(hits.single.matchedVia, MatchTier.surfaceForm);
    });

    test('does not run when dictForm already matched', () async {
      await _insertDictionary(db, id: 'dictA', priority: 0);
      await _insertTerm(db, dictionaryId: 'dictA', headword: '食べる');
      await _insertTerm(db, dictionaryId: 'dictA', headword: '食べた');

      final hits = await repo.lookup(dictForm: '食べる', surfaceForm: '食べた');
      expect(hits, hasLength(1));
      expect(hits.single.matchedVia, MatchTier.dictionaryForm);
      expect(hits.single.term.headword, '食べる');
    });
  });

  group('tier 3: deconjugation retry', () {
    test('deinflects the surface form and validates the candidate against '
        "the matched entry's rules field", () async {
      await _insertDictionary(db, id: 'dictA', priority: 0);
      await _insertTerm(
        db,
        dictionaryId: 'dictA',
        headword: '食べる',
        rules: 'v1',
      );

      final hits = await repo.lookup(
        dictForm: 'NOT_A_REAL_DICT_FORM',
        surfaceForm: '食べた',
      );
      expect(hits, hasLength(1));
      expect(hits.single.matchedVia, MatchTier.deconjugation);
      expect(hits.single.term.headword, '食べる');
    });

    test('rejects a deinflection candidate whose entry does not carry the '
        "expected rule -- validation is not a no-op", () async {
      await _insertDictionary(db, id: 'dictA', priority: 0);
      // Same headword the deinflector would produce for 食べた, but tagged
      // with an unrelated rule (as if miscategorized) -- must not be
      // accepted as a match.
      await _insertTerm(db, dictionaryId: 'dictA', headword: '食べる', rules: 'n');

      final hits = await repo.lookup(
        dictForm: 'NOT_A_REAL_DICT_FORM',
        surfaceForm: '食べた',
      );
      expect(hits, isEmpty);
    });

    test('godan verb deconjugation (買った -> 買う, v5)', () async {
      await _insertDictionary(db, id: 'dictA', priority: 0);
      await _insertTerm(db, dictionaryId: 'dictA', headword: '買う', rules: 'v5');

      final hits = await repo.lookup(
        dictForm: 'NOT_A_REAL_DICT_FORM',
        surfaceForm: '買った',
      );
      expect(hits, hasLength(1));
      expect(hits.single.term.headword, '買う');
      expect(hits.single.matchedVia, MatchTier.deconjugation);
    });

    test('merges deconjugation hits across enabled dictionaries too', () async {
      await _insertDictionary(db, id: 'dictA', priority: 0);
      await _insertDictionary(db, id: 'dictB', priority: 1);
      await _insertTerm(
        db,
        dictionaryId: 'dictA',
        headword: '食べる',
        rules: 'v1',
      );
      await _insertTerm(
        db,
        dictionaryId: 'dictB',
        headword: '食べる',
        rules: 'v1',
      );

      final hits = await repo.lookup(
        dictForm: 'NOT_A_REAL_DICT_FORM',
        surfaceForm: '食べた',
      );
      expect(hits, hasLength(2));
      expect(hits[0].dictionaryId, 'dictA');
      expect(hits[1].dictionaryId, 'dictB');
    });
  });

  group('no match anywhere', () {
    test('returns an empty list when nothing matches at any tier', () async {
      await _insertDictionary(db, id: 'dictA', priority: 0);
      await _insertTerm(db, dictionaryId: 'dictA', headword: '猫');

      final hits = await repo.lookup(
        dictForm: 'totally_unrelated',
        surfaceForm: 'totally_unrelated',
      );
      expect(hits, isEmpty);
    });

    test('an empty database returns an empty list without throwing', () async {
      final hits = await repo.lookup(dictForm: '猫', surfaceForm: '猫');
      expect(hits, isEmpty);
    });
  });
}
