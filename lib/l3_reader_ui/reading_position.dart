import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';

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
/// Session-only for now, not yet persisted across app restarts (spec §5's
/// "persisted per work" implies durable storage keyed by work -- that needs
/// a real per-Document reading-position table, which doesn't exist yet; a
/// reasonable, separately-scoped follow-up once a Library view exists to
/// actually list multiple works with saved positions).
class CurrentSentencePosition extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? sentenceId) => state = sentenceId;
}

final currentSentencePositionProvider =
    NotifierProvider<CurrentSentencePosition, String?>(
      CurrentSentencePosition.new,
    );
