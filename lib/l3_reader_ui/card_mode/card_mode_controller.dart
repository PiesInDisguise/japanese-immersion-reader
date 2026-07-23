import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_repository.dart';
import 'package:japanese_immersion_reader/l2_linguistics/tokenizer/reconcile.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/mining_engine.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/source_ref.dart';

import '../../app/services.dart';

/// The `Document` Card Mode is currently showing, or `null` before any book
/// is opened. Deliberately a plain [Notifier] holding one value (not a
/// family parameter on [CardModeController]) since only one document is
/// ever open at a time in this app -- [CardModeController] just watches
/// this rather than needing per-document controller instances.
class CurrentDocument extends Notifier<Document?> {
  @override
  Document? build() => null;

  void set(Document? document) => state = document;
}

final currentDocumentProvider = NotifierProvider<CurrentDocument, Document?>(
  CurrentDocument.new,
);

/// A single flattened chapter/block/sentence position -- Card Mode is a
/// linear feed of sentences (spec §6: "one sentence per card"), regardless
/// of how deeply nested the source `Document` is.
class _FlatPosition {
  const _FlatPosition(this.sentence);
  final Sentence sentence;
}

/// One card's fully-processed content: the L1 sentence plus its L2-real
/// (Sudachi-tokenized, ruby/sourceRect/confidence-reconciled) tokens. Built
/// by [CardModeController._loadCard] -- see `reconcile.dart` for what
/// "reconciled" means and why L1's placeholder tokens alone aren't enough
/// to show a real card.
class CardModeState {
  const CardModeState({
    required this.document,
    required this.cardIndex,
    required this.totalCards,
    required this.sentence,
    required this.tokens,
    required this.isFlipped,
  });

  final Document document;
  final int cardIndex;
  final int totalCards;
  final Sentence sentence;
  final List<Token> tokens;
  final bool isFlipped;

  bool get hasNext => cardIndex < totalCards - 1;
  bool get hasPrevious => cardIndex > 0;

  CardModeState copyWith({
    int? cardIndex,
    List<Token>? tokens,
    bool? isFlipped,
  }) => CardModeState(
    document: document,
    cardIndex: cardIndex ?? this.cardIndex,
    totalCards: totalCards,
    sentence: sentence,
    tokens: tokens ?? this.tokens,
    isFlipped: isFlipped ?? this.isFlipped,
  );
}

final cardModeControllerProvider =
    AsyncNotifierProvider<CardModeController, CardModeState>(
      CardModeController.new,
    );

/// Drives one Card Mode session over whatever [currentDocumentProvider]
/// currently holds (spec §6).
///
/// **Scope note**: implements auto-add-ON mining semantics only (tap a word
/// -> `WordCollectionRepository.mine` decides fresh-add vs.
/// reset-to-new-if-already-collected internally, matching spec's "tapping
/// an already-collected word resets its SRS state" -- the controller never
/// needs to check collected-state itself before calling `mine`). Auto-add
/// OFF's +/- toggle needs a "is this already collected" query that doesn't
/// exist on `WordCollectionRepository` yet, plus a settings screen to
/// choose the mode -- neither exists, so that mode is a deliberate follow-up
/// rather than something guessed at here. Grammar-point mining is similarly
/// deferred: there's no grammar-point database yet (spec §8, a later
/// phase) to mine *from*.
class CardModeController extends AsyncNotifier<CardModeState> {
  late List<_FlatPosition> _positions;
  MineResult? _lastMineResult;

  @override
  Future<CardModeState> build() async {
    final document = ref.watch(currentDocumentProvider);
    if (document == null) {
      throw StateError(
        'CardModeController.build: no document loaded -- set '
        'currentDocumentProvider before watching cardModeControllerProvider.',
      );
    }
    _positions = [
      for (final chapter in document.chapters)
        for (final block in chapter.blocks)
          for (final sentence in block.sentences) _FlatPosition(sentence),
    ];
    return _loadCard(document, 0);
  }

  Future<CardModeState> _loadCard(Document document, int index) async {
    final position = _positions[index];
    final tokenizer = await ref.read(tokenizerProvider.future);
    final sudachiTokens = await tokenizer.tokenize(
      position.sentence.surfaceText,
    );
    final reconciled = reconcileSentenceTokens(
      position.sentence.tokens,
      sudachiTokens,
    );
    return CardModeState(
      document: document,
      cardIndex: index,
      totalCards: _positions.length,
      sentence: position.sentence,
      tokens: reconciled,
      isFlipped: false,
    );
  }

  /// Doesn't show a loading state between cards -- tokenizing one sentence
  /// is fast enough (see docs/research/r4-tokenizer.md) that the previous
  /// card stays on screen until the next one is ready, rather than flashing
  /// a spinner between every swipe.
  Future<void> next() async {
    final current = state.value;
    if (current == null || !current.hasNext) return;
    state = AsyncData(await _loadCard(current.document, current.cardIndex + 1));
  }

  Future<void> previous() async {
    final current = state.value;
    if (current == null || !current.hasPrevious) return;
    state = AsyncData(await _loadCard(current.document, current.cardIndex - 1));
  }

  /// Tap-empty-card-space (spec §6): flips to the grammar/token-gloss side.
  /// Only layer 1 of spec §8's three-layer grammar breakdown (token gloss:
  /// surface/dictForm/reading/pos/inflection, already on [CardModeState]'s
  /// tokens) is available this pass -- matched grammar points (layer 2) and
  /// the LLM explanation (layer 3) are later phases.
  void toggleFlip() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(isFlipped: !current.isFlipped));
  }

  /// Tap-a-word (spec §6): definition + reading popup content.
  Future<List<DictionaryLookupHit>> lookupWord(Token token) {
    final dictForm = token.dictForm ?? token.surface;
    final surfaceForm = token.surface;
    return ref
        .read(dictionaryRepositoryProvider)
        .lookup(
          dictForm: dictForm,
          surfaceForm: surfaceForm,
          reading: token.reading,
        );
  }

  /// Auto-add-ON's core tap behavior: add fresh, or reset-to-new if already
  /// collected (spec §6) -- `WordCollectionRepository.mine` decides which
  /// internally. `senses` should come from whatever the popup's own
  /// [lookupWord] call already found for this token, so mining and looking
  /// up a word always agree on which dictionary senses it's associated with.
  Future<void> mineWord(Token token, List<DictionaryLookupHit> senses) async {
    final current = state.value;
    if (current == null) return;

    final repository = ref.read(wordCollectionRepositoryProvider);
    final result = await repository.mine(
      dictForm: token.dictForm ?? token.surface,
      reading: token.reading ?? token.surface,
      senseIds: [for (final hit in senses) hit.term.id],
      source: SourceRef(
        workId: current.document.id,
        sentenceId: current.sentence.id,
        mediaType: CollectionMediaType.lightNovel,
      ),
    );
    _lastMineResult = result;
  }

  /// Long-press-to-remove (spec §6), given the word's own dictForm/reading
  /// (its collection identity -- see `contentDerivedWordId`).
  Future<void> removeWord(String dictForm, String reading) {
    _lastMineResult = null;
    return ref
        .read(wordCollectionRepositoryProvider)
        .remove(dictForm: dictForm, reading: reading);
  }

  /// The undo-toast action (spec §6): reverses whatever the *last*
  /// [mineWord] call did, whether that was a fresh add or a reset. A no-op
  /// if nothing has been mined yet this session, or the last action was
  /// already undone/removed.
  Future<void> undoLastMining() async {
    final result = _lastMineResult;
    if (result == null) return;
    _lastMineResult = null;
    await ref.read(wordCollectionRepositoryProvider).undo(result);
  }
}
