import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_repository.dart';

import '../reader_mining_session.dart';

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
/// currently holds (spec §6). The real tokenize/lookup/mine/undo logic
/// lives in [ReaderMiningSession] (shared with Document Mode); this class
/// only owns Card Mode's own concern -- the linear card position and the
/// flip state.
class CardModeController extends AsyncNotifier<CardModeState> {
  late List<_FlatPosition> _positions;
  late ReaderMiningSession _mining;

  @override
  Future<CardModeState> build() async {
    final document = ref.watch(currentDocumentProvider);
    if (document == null) {
      throw StateError(
        'CardModeController.build: no document loaded -- set '
        'currentDocumentProvider before watching cardModeControllerProvider.',
      );
    }
    _mining = ReaderMiningSession(ref);
    _positions = [
      for (final chapter in document.chapters)
        for (final block in chapter.blocks)
          for (final sentence in block.sentences) _FlatPosition(sentence),
    ];
    return _loadCard(document, 0);
  }

  Future<CardModeState> _loadCard(Document document, int index) async {
    final position = _positions[index];
    final tokens = await _mining.tokenizeSentence(position.sentence);
    return CardModeState(
      document: document,
      cardIndex: index,
      totalCards: _positions.length,
      sentence: position.sentence,
      tokens: tokens,
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

  Future<List<DictionaryLookupHit>> lookupWord(Token token) =>
      _mining.lookupWord(token);

  Future<void> mineWord(Token token, List<DictionaryLookupHit> senses) {
    final current = state.value;
    if (current == null) return Future.value();
    return _mining.mineWord(
      token,
      senses,
      workId: current.document.id,
      sentenceId: current.sentence.id,
    );
  }

  Future<void> removeWord(String dictForm, String reading) =>
      _mining.removeWord(dictForm, reading);

  Future<void> undoLastMining() => _mining.undoLastMining();
}
