import 'dart:convert';
import 'dart:io';

// `isNull` is also a drift query-builder helper (for SQL NULL checks); this
// file only wants flutter_test's matcher of the same name, so it's hidden
// here rather than needing an `as prefix` on every drift usage below.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_importer.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<String> importFixture(
    String fileName, {
    List<DictionaryImportProgress>? progressEvents,
  }) {
    final file = File('assets/fixtures/$fileName');
    return DictionaryImporter(
      db,
    ).import(file, onProgress: (p) => progressEvents?.add(p));
  }

  group('yomitan_sample_dictionary.zip', () {
    test('creates one Dictionaries row with index.json metadata', () async {
      final dictionaryId = await importFixture('yomitan_sample_dictionary.zip');

      final rows = await db.select(db.dictionaries).get();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.id, dictionaryId);
      expect(row.title, 'JIR Sample Dictionary');
      expect(row.revision, '2026.07.22');
      expect(row.formatVersion, 3);
      expect(row.author, 'Japanese Immersion Reader fixtures');
      expect(row.sourceLanguage, 'ja');
      expect(row.targetLanguage, 'en');
      expect(row.frequencyMode, 'rank-based');
      expect(row.sequenced, isTrue);
      expect(row.priority, 0);
      expect(row.enabled, isTrue);
    });

    test('populates all 10 term_bank entries across both files', () async {
      final dictionaryId = await importFixture('yomitan_sample_dictionary.zip');

      final terms = await (db.select(
        db.dictionaryTermEntries,
      )..where((t) => t.dictionaryId.equals(dictionaryId))).get();
      expect(terms, hasLength(10));
    });

    test(
      'normalizes an empty reading to the term, and preserves import order',
      () async {
        final dictionaryId = await importFixture(
          'yomitan_sample_dictionary.zip',
        );
        final terms = await (db.select(
          db.dictionaryTermEntries,
        )..where((t) => t.dictionaryId.equals(dictionaryId))).get();

        final sou = terms.firstWhere((t) => t.headword == 'そう');
        expect(sou.reading, ''); // raw, unmodified
        expect(sou.readingNormalized, 'そう'); // normalized
        expect(sou.importOrder, 1); // 2nd entry in term_bank_1.json
      },
    );

    test(
      'preserves all 8 term_bank fields for a fully-populated entry',
      () async {
        final dictionaryId = await importFixture(
          'yomitan_sample_dictionary.zip',
        );
        final terms = await (db.select(
          db.dictionaryTermEntries,
        )..where((t) => t.dictionaryId.equals(dictionaryId))).get();

        final utsu = terms.firstWhere((t) => t.headword == '打つ');
        expect(utsu.reading, 'うつ');
        expect(utsu.readingNormalized, 'うつ');
        expect(utsu.definitionTags, 'vt');
        expect(utsu.rules, 'v5');
        expect(utsu.score, 12.0);
        expect(jsonDecode(utsu.definitionsJson), [
          'to hit; to strike',
          'to knock',
        ]);
        expect(utsu.sequence, 101);
        expect(utsu.termTags, 'P');
        expect(utsu.importOrder, 0); // 1st entry in term_bank_1.json
      },
    );

    test(
      'assigns import order across term_bank_1 then term_bank_2, in file order',
      () async {
        final dictionaryId = await importFixture(
          'yomitan_sample_dictionary.zip',
        );
        final terms = await (db.select(
          db.dictionaryTermEntries,
        )..where((t) => t.dictionaryId.equals(dictionaryId))).get();

        final neko = terms.firstWhere((t) => t.headword == '猫');
        final e = terms.firstWhere((t) => t.headword == '絵');
        final itta = terms.firstWhere((t) => t.headword == '行った');
        expect(neko.importOrder, 7); // 1st entry in term_bank_2.json
        expect(e.importOrder, 8);
        expect(itta.importOrder, 9); // last entry overall
      },
    );

    test(
      'stores structured-content and image definitions as opaque JSON',
      () async {
        final dictionaryId = await importFixture(
          'yomitan_sample_dictionary.zip',
        );
        final terms = await (db.select(
          db.dictionaryTermEntries,
        )..where((t) => t.dictionaryId.equals(dictionaryId))).get();

        final neko = terms.firstWhere((t) => t.headword == '猫');
        final decoded = jsonDecode(neko.definitionsJson) as List;
        expect(decoded.single['type'], 'structured-content');
        expect(decoded.single['content']['tag'], 'div');

        final e = terms.firstWhere((t) => t.headword == '絵');
        final eDecoded = jsonDecode(e.definitionsJson) as List;
        expect(eDecoded.single['type'], 'image');
        expect(eDecoded.single['path'], 'images/e_example.png');
      },
    );

    test(
      'stores the 2-tuple cross-reference definition shape untouched',
      () async {
        final dictionaryId = await importFixture(
          'yomitan_sample_dictionary.zip',
        );
        final terms = await (db.select(
          db.dictionaryTermEntries,
        )..where((t) => t.dictionaryId.equals(dictionaryId))).get();

        final itta = terms.firstWhere((t) => t.headword == '行った');
        expect(jsonDecode(itta.definitionsJson), [
          [
            '行く',
            ['v5'],
          ],
        ]);
      },
    );

    test(
      'populates all 5 term_meta_bank entries with mode breakdown',
      () async {
        final dictionaryId = await importFixture(
          'yomitan_sample_dictionary.zip',
        );
        final metas = await (db.select(
          db.dictionaryTermMetaEntries,
        )..where((t) => t.dictionaryId.equals(dictionaryId))).get();

        expect(metas, hasLength(5));
        expect(metas.where((m) => m.mode == 'freq'), hasLength(2));
        expect(metas.where((m) => m.mode == 'pitch'), hasLength(2));
        expect(metas.where((m) => m.mode == 'ipa'), hasLength(1));
      },
    );

    test('pulls the reading out of term_meta payloads that carry one, and '
        'leaves it null for a bare freq number', () async {
      final dictionaryId = await importFixture('yomitan_sample_dictionary.zip');
      final metas = await (db.select(
        db.dictionaryTermMetaEntries,
      )..where((t) => t.dictionaryId.equals(dictionaryId))).get();

      final bareFreq = metas.firstWhere(
        (m) => m.mode == 'freq' && jsonDecode(m.dataJson) is int,
      );
      expect(bareFreq.reading, isNull);

      final readingSpecificFreq = metas.firstWhere(
        (m) => m.mode == 'freq' && jsonDecode(m.dataJson) is Map,
      );
      expect(readingSpecificFreq.reading, 'うつ');

      final pitchEntries = metas.where((m) => m.mode == 'pitch').toList();
      expect(pitchEntries.map((m) => m.reading), containsAll(['うつ', 'たべる']));

      final ipaEntry = metas.firstWhere((m) => m.mode == 'ipa');
      expect(ipaEntry.reading, 'うつ');
    });

    test('populates all 8 tag_bank entries across both files', () async {
      final dictionaryId = await importFixture('yomitan_sample_dictionary.zip');
      final tags = await (db.select(
        db.dictionaryTagEntries,
      )..where((t) => t.dictionaryId.equals(dictionaryId))).get();

      expect(tags, hasLength(8));
      final v5 = tags.firstWhere((t) => t.name == 'v5');
      expect(v5.category, 'partOfSpeech');
      expect(v5.sortOrder, 0);
      expect(v5.notes, 'godan verb');
      expect(v5.score, -5.0);

      final popular = tags.firstWhere((t) => t.name == 'P');
      expect(popular.category, 'popular');
      expect(popular.notes, 'common word');
      expect(popular.score, 5.0);
    });

    test('reports unzipping/parsing/writing progress ending in a done event '
        'at fraction 1.0, with non-decreasing fractions', () async {
      final events = <DictionaryImportProgress>[];
      await importFixture(
        'yomitan_sample_dictionary.zip',
        progressEvents: events,
      );

      expect(events, isNotEmpty);
      expect(events.first.stage, DictionaryImportStage.unzipping);
      expect(events.last.stage, DictionaryImportStage.done);
      expect(events.last.fraction, 1.0);
      for (var i = 1; i < events.length; i++) {
        expect(
          events[i].fraction,
          greaterThanOrEqualTo(events[i - 1].fraction),
        );
      }
      expect(
        events.any((e) => e.stage == DictionaryImportStage.writing),
        isTrue,
      );
    });

    test('re-importing the same zip replaces rows instead of duplicating them, '
        'and preserves user-set priority/enabled', () async {
      final firstId = await importFixture('yomitan_sample_dictionary.zip');

      // Simulate the user having reordered/disabled this dictionary.
      await (db.update(
        db.dictionaries,
      )..where((d) => d.id.equals(firstId))).write(
        const DictionariesCompanion(priority: Value(7), enabled: Value(false)),
      );

      final secondId = await importFixture('yomitan_sample_dictionary.zip');
      expect(secondId, firstId);

      final dictionaryRows = await db.select(db.dictionaries).get();
      expect(dictionaryRows, hasLength(1));
      expect(dictionaryRows.single.priority, 7); // preserved
      expect(dictionaryRows.single.enabled, isFalse); // preserved

      final terms = await (db.select(
        db.dictionaryTermEntries,
      )..where((t) => t.dictionaryId.equals(firstId))).get();
      expect(terms, hasLength(10)); // not doubled

      final metas = await (db.select(
        db.dictionaryTermMetaEntries,
      )..where((t) => t.dictionaryId.equals(firstId))).get();
      expect(metas, hasLength(5)); // not doubled

      final tags = await (db.select(
        db.dictionaryTagEntries,
      )..where((t) => t.dictionaryId.equals(firstId))).get();
      expect(tags, hasLength(8)); // not doubled
    });
  });

  group('multiple dictionaries', () {
    test('a second, distinct dictionary gets the next free priority', () async {
      await importFixture('yomitan_sample_dictionary.zip');
      await importFixture('yomitan_second_dictionary.zip');

      final rows = await db.select(db.dictionaries).get();
      expect(rows, hasLength(2));
      final priorities = rows.map((d) => d.priority).toList()..sort();
      expect(priorities, [0, 1]);
    });
  });

  group('invalid dictionaries', () {
    test('rejects an unsupported format version', () async {
      expect(
        () => importFixture('yomitan_unsupported_format.zip'),
        throwsFormatException,
      );

      // Nothing should have been written on a rejected import.
      final rows = await db.select(db.dictionaries).get();
      expect(rows, isEmpty);
    });

    test('rejects a zip with no index.json', () async {
      expect(
        () => importFixture('yomitan_missing_index.zip'),
        throwsFormatException,
      );
    });
  });
}
