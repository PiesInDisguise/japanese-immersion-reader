import 'package:drift/drift.dart';

/// One row per imported work. `updatedAt` is sync-ready per spec §13 (every
/// mutable row carries a stable ID + updatedAt so an optional sync layer can
/// use last-write-wins/CRDT later without a schema change).
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get sourceType => text()();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Block/Sentence/Token are stored as a single JSON blob per chapter rather
/// than normalized rows: OCR background jobs write per-chapter, and a fully
/// normalized per-token table would be expensive to write during that job.
/// The `sentences` table below is the queryable index over this blob.
class Chapters extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text().references(Documents, #id)();
  IntColumn get chapterIndex => integer().named('chapter_index')();
  TextColumn get title => text().nullable()();
  TextColumn get blocksJson => text().named('blocks_json')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Flat, queryable index over sentences so Card Mode/Document Mode can
/// resolve a stable Sentence ID to its chapter/position in O(1) instead of
/// scanning every chapter's blocksJson blob.
class Sentences extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text().references(Documents, #id)();
  TextColumn get chapterId => text().references(Chapters, #id)();
  IntColumn get chapterIndex => integer().named('chapter_index')();
  IntColumn get blockIndex => integer().named('block_index')();
  IntColumn get sentenceIndex => integer().named('sentence_index')();
  TextColumn get content => text()();

  @override
  Set<Column> get primaryKey => {id};
}
