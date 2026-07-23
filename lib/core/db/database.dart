import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Documents,
    Chapters,
    Sentences,
    // Dictionary import/lookup (spec §10) -- see
    // docs/research/r5-dictionary.md for the schema design.
    Dictionaries,
    DictionaryTagEntries,
    DictionaryTermEntries,
    DictionaryTermMetaEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'japanese_immersion_reader.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
