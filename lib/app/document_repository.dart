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
      await _db
          .into(_db.documents)
          .insertOnConflictUpdate(
            DocumentsCompanion.insert(
              id: document.id,
              title: document.title,
              sourceType: document.sourceType.name,
              addedAt: now,
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
}
