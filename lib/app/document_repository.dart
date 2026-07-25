import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';

/// Persists an in-memory [Document] into `Documents`/`Chapters`/`Sentences`
/// (`lib/core/db/tables.dart`) so a sentence's real text survives after the
/// document itself is no longer loaded in memory -- specifically, so a
/// spec §12 review card can show "the original source sentence built in as
/// context" for a word/grammar point mined long after that reading session
/// ended.
///
/// **Why this exists now, and didn't before**: every importer/`HomeScreen`
/// import flow has always held its `Document` purely in memory
/// (`currentDocumentProvider`) -- mining only ever stored a sentence's
/// *id* (`CollectedWordSources.sentenceId` etc.), never its text, because
/// nothing needed to resolve that id back to real content until the review
/// deck did. This is that resolution layer, not a retrofit of importing
/// itself: `HomeScreen` calls [save] once, right after loading a document,
/// same as it already seeds the sample dictionary.
class DocumentRepository {
  DocumentRepository(this._db);

  final AppDatabase _db;

  /// Upserts [document] and every chapter/sentence it contains. Safe to call
  /// again for the same document (e.g. re-opening a previously-read book) --
  /// every row is keyed by the document's own stable, content-derived id
  /// (see `contentDerivedDocumentId`), so this overwrites rather than
  /// duplicates.
  Future<void> save(Document document) {
    return _db.transaction(() async {
      final now = DateTime.now().toUtc();
      // Preserve the real first-added timestamp across re-saves (e.g.
      // reopening a book from the Library re-runs this same save call) --
      // `insertOnConflictUpdate` would otherwise overwrite every column,
      // including `addedAt`, to `now` on every reopen.
      final existing = await (_db.select(
        _db.documents,
      )..where((d) => d.id.equals(document.id))).getSingleOrNull();
      await _db
          .into(_db.documents)
          .insertOnConflictUpdate(
            DocumentsCompanion.insert(
              id: document.id,
              title: document.title,
              sourceType: document.sourceType.name,
              addedAt: existing?.addedAt ?? now,
              updatedAt: now,
            ),
          );

      final chapterRows = <ChaptersCompanion>[];
      final sentenceRows = <SentencesCompanion>[];
      for (final chapter in document.chapters) {
        chapterRows.add(
          ChaptersCompanion.insert(
            id: chapter.id,
            documentId: document.id,
            chapterIndex: chapter.index,
            title: Value(chapter.title),
            blocksJson: jsonEncode(
              chapter.blocks.map((block) => block.toJson()).toList(),
            ),
          ),
        );
        for (final block in chapter.blocks) {
          for (final sentence in block.sentences) {
            sentenceRows.add(
              SentencesCompanion.insert(
                id: sentence.id,
                documentId: document.id,
                chapterId: chapter.id,
                chapterIndex: chapter.index,
                blockIndex: block.index,
                sentenceIndex: sentence.index,
                content: sentence.surfaceText,
              ),
            );
          }
        }
      }

      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.chapters, chapterRows);
        batch.insertAllOnConflictUpdate(_db.sentences, sentenceRows);
      });
    });
  }

  /// A sentence's real text, if it (and its owning document) was ever
  /// [save]d -- `null` if not (e.g. the document was mined from but the app
  /// was closed before a `save` call, or this is a fixture/test id).
  /// Callers (the review deck) must treat a `null` result as "no context
  /// available" rather than an error -- this is additive, per spec §12
  /// showing the source sentence as context, not a hard requirement for a
  /// card to be reviewable at all.
  Future<String?> sentenceContent(String sentenceId) async {
    final row = await (_db.select(
      _db.sentences,
    )..where((s) => s.id.equals(sentenceId))).getSingleOrNull();
    return row?.content;
  }

  /// A document's title, if it was ever [save]d -- same "null means
  /// unavailable, not an error" contract as [sentenceContent].
  Future<String?> documentTitle(String documentId) async {
    final row = await (_db.select(
      _db.documents,
    )..where((d) => d.id.equals(documentId))).getSingleOrNull();
    return row?.title;
  }

  /// Every [save]d document, most-recently-opened first -- the Library
  /// screen's own data source. Ordered by `updatedAt` (not `addedAt`):
  /// [save] runs on every reopen, not just first import, so `updatedAt`
  /// already behaves as "last opened," which is the ordering a library
  /// actually wants (continue reading the most recent book first).
  Future<List<DocumentRow>> listDocuments() {
    return (_db.select(
      _db.documents,
    )..orderBy([(d) => OrderingTerm.desc(d.updatedAt)])).get();
  }

  /// Sets [documentId]'s cover unconditionally -- the user's own deliberate
  /// pick (Library's tap-to-customize flow) always wins, even over a
  /// previously-set auto-extracted or user-picked cover. A targeted UPDATE
  /// by id: no-ops if [documentId] has no row yet, so callers must only
  /// invoke this after [save] has guaranteed the row exists.
  Future<void> updateCoverImagePath(String documentId, String coverImagePath) {
    return (_db.update(_db.documents)..where((d) => d.id.equals(documentId)))
        .write(DocumentsCompanion(coverImagePath: Value(coverImagePath)));
  }

  /// Sets [documentId]'s cover only if it doesn't already have one --
  /// import-time auto-extraction must never clobber a user-picked custom
  /// cover on a later re-import of the same source file (same
  /// content-derived [Document.id], so the same row).
  Future<void> setAutoExtractedCoverIfAbsent(
    String documentId,
    String coverImagePath,
  ) {
    return (_db.update(_db.documents)
          ..where((d) => d.id.equals(documentId) & d.coverImagePath.isNull()))
        .write(DocumentsCompanion(coverImagePath: Value(coverImagePath)));
  }

  /// Persists the reading position (spec §5) for [documentId] -- a targeted
  /// UPDATE, not a [save] round-trip, since this fires on every card
  /// swipe/scroll sentence-boundary change and must not re-serialize every
  /// chapter/sentence each time.
  Future<void> updateLastSentenceId(String documentId, String sentenceId) {
    return (_db.update(_db.documents)..where((d) => d.id.equals(documentId)))
        .write(DocumentsCompanion(lastSentenceId: Value(sentenceId)));
  }

  /// The persisted reading position for [documentId], or `null` if none was
  /// ever saved (never opened, or opened before this feature existed).
  Future<String?> lastSentenceId(String documentId) async {
    final row = await (_db.select(
      _db.documents,
    )..where((d) => d.id.equals(documentId))).getSingleOrNull();
    return row?.lastSentenceId;
  }

  /// Reconstructs a full, in-memory [Document] -- every chapter/block/
  /// sentence/token -- from what [save] persisted, so the Library screen
  /// can reopen a book without re-picking/re-importing its source file.
  /// `null` if [documentId] was never saved. Rebuilds purely from
  /// `Chapters.blocksJson` (each chapter's full `List<Block>`, already
  /// JSON round-trip-capable via `Block.toJson`/`Block.fromJson`) --
  /// `Sentences` (a flat, plain-text index for [sentenceContent]/mining
  /// lookups) isn't needed for this, since the real sentence/token data
  /// already lives in `blocksJson`.
  Future<Document?> loadDocument(String documentId) async {
    final documentRow = await (_db.select(
      _db.documents,
    )..where((d) => d.id.equals(documentId))).getSingleOrNull();
    if (documentRow == null) return null;

    final chapterRows =
        await (_db.select(_db.chapters)
              ..where((c) => c.documentId.equals(documentId))
              ..orderBy([(c) => OrderingTerm.asc(c.chapterIndex)]))
            .get();

    final chapters = [
      for (final row in chapterRows)
        Chapter(
          id: row.id,
          index: row.chapterIndex,
          title: row.title,
          blocks: (jsonDecode(row.blocksJson) as List)
              .map((json) => Block.fromJson(json as Map<String, dynamic>))
              .toList(),
        ),
    ];

    return Document(
      id: documentRow.id,
      title: documentRow.title,
      sourceType: DocumentSourceType.values.byName(documentRow.sourceType),
      chapters: chapters,
    );
  }
}
