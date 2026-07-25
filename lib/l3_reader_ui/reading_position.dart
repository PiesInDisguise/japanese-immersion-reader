import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';

import '../app/services.dart';

/// The `Document` currently open, or `null` before any book is opened.
/// Deliberately a plain [Notifier] holding one value rather than a family
/// parameter on each mode's controller, since only one document is ever
/// open at a time in this app.
class CurrentDocument extends Notifier<Document?> {
  @override
  Document? build() => null;

  void set(Document? document) => state = document;
}

final currentDocumentProvider = NotifierProvider<CurrentDocument, Document?>(
  CurrentDocument.new,
);

/// The stable Sentence ID (`lib/core/ids/stable_id.dart`) either reading
/// mode last showed, or `null` if nothing has been read yet this session.
///
/// Spec §5: "Reading position — persisted per work; mode switches preserve
/// position via the shared Sentence ID." Both `CardModeController` and
/// `DocumentModeController` write here as the reader moves, and read it as
/// their starting position on `build()` -- this is the one piece of state
/// that makes switching modes resume at the same place rather than
/// restarting from the top, per spec's own explanation of why `Sentence`
/// carries a stable ID at all (`docs/spec.md` §3).
///
/// Persisted per spec §5: every [set] call also fire-and-forget writes
/// through to `Documents.lastSentenceId` (`DocumentRepository
/// .updateLastSentenceId`), keyed by whichever document
/// `currentDocumentProvider` currently holds. `home_screen.dart`'s
/// `_openDocument` reads that persisted value back and seeds this provider
/// before pushing the reader screen, so reopening a book (from the Library,
/// or a fresh app launch) resumes at the same sentence a prior session left
/// off at.
class CurrentSentencePosition extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? sentenceId) {
    state = sentenceId;
    if (sentenceId == null) return;
    final document = ref.read(currentDocumentProvider);
    if (document == null) return;
    // Fire-and-forget: a card swipe/scroll tick must not block on a DB
    // write completing. Mirrors `ReadingTimeTracker`'s identical
    // `unawaited(...)` use of `documentRepositoryProvider`'s sibling
    // repository for spec §15 (`reading_time_tracker.dart`).
    unawaited(
      ref
          .read(documentRepositoryProvider)
          .updateLastSentenceId(document.id, sentenceId),
    );
  }
}

final currentSentencePositionProvider =
    NotifierProvider<CurrentSentencePosition, String?>(
      CurrentSentencePosition.new,
    );
