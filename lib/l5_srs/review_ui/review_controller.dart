import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/app/services.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_repository.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/definition_rendering.dart';
import 'package:japanese_immersion_reader/l5_srs/fsrs/rating.dart';

export 'package:japanese_immersion_reader/l5_srs/fsrs/rating.dart' show Rating;

/// Which collection table [ReviewCard.entryId] belongs to -- so
/// [ReviewController.rate] knows which repository's `review` method to call.
enum ReviewCardKind { word, grammar }

/// One card in the review deck (spec §12): a word or grammar point that's
/// due, its recognition-card front/back content, and its original source
/// sentence as context (when available -- see `DocumentRepository`'s own
/// "null means unavailable, not an error" contract).
class ReviewCard {
  const ReviewCard({
    required this.kind,
    required this.entryId,
    required this.front,
    required this.back,
    required this.contextSentence,
    required this.due,
  });

  final ReviewCardKind kind;
  final String entryId;

  /// Spec §12's default recognition card type: what the reader sees first
  /// (a word's dictForm+reading, or a grammar point's display pattern).
  final String front;

  /// Revealed on tap/button (a word's dictionary definitions joined, or a
  /// grammar point's explanation).
  final String back;

  final String? contextSentence;
  final DateTime due;
}

/// [ReviewController]'s state: the due-card queue built once at `build()`
/// time, plus where the reader currently is in it. Rating a card advances
/// [index] rather than removing it from [cards] -- keeps "how many did I
/// review this session" derivable from `index` alone.
class ReviewQueueState {
  const ReviewQueueState({
    required this.cards,
    required this.index,
    required this.isRevealed,
  });

  final List<ReviewCard> cards;
  final int index;
  final bool isRevealed;

  ReviewCard? get current => index < cards.length ? cards[index] : null;
  bool get isComplete => index >= cards.length;
  int get remaining => cards.length - index;

  ReviewQueueState copyWith({int? index, bool? isRevealed}) => ReviewQueueState(
    cards: cards,
    index: index ?? this.index,
    isRevealed: isRevealed ?? this.isRevealed,
  );
}

final reviewControllerProvider =
    AsyncNotifierProvider<ReviewController, ReviewQueueState>(
      ReviewController.new,
    );

/// Drives one review-deck session (spec §12): builds the due queue (words +
/// grammar points, earliest-due first) once, then reveals/rates one card at
/// a time. Real scheduling itself lives in `ReviewEngine`
/// (`lib/l4_mining/collection/review_engine.dart`), reached through
/// `WordCollectionRepository.review`/`GrammarCollectionRepository.review` --
/// this class only owns the queue/reveal-state concern, mirroring how
/// `CardModeController` only owns card position on top of the shared
/// `ReaderMiningSession`.
class ReviewController extends AsyncNotifier<ReviewQueueState> {
  @override
  Future<ReviewQueueState> build() async {
    final wordRepository = ref.watch(wordCollectionRepositoryProvider);
    final grammarRepository = ref.watch(grammarCollectionRepositoryProvider);
    final dictionaryRepository = ref.watch(dictionaryRepositoryProvider);
    final documentRepository = ref.watch(documentRepositoryProvider);
    final grammarMatcher = await ref.watch(grammarDatabaseProvider.future);

    final now = DateTime.now().toUtc();
    final cards = <ReviewCard>[];

    for (final word in await wordRepository.due(now: now)) {
      final hits = await dictionaryRepository.lookup(
        dictForm: word.dictForm,
        surfaceForm: word.dictForm,
        reading: word.reading,
      );
      final sentenceId = await wordRepository.latestSightingSentenceId(
        word.id,
      );
      final context = sentenceId == null
          ? null
          : await documentRepository.sentenceContent(sentenceId);
      cards.add(
        ReviewCard(
          kind: ReviewCardKind.word,
          entryId: word.id,
          front: '${word.dictForm} (${word.reading})',
          back: hits.isEmpty
              ? 'No dictionary entry found.'
              : hits.map(_definitionText).join('; '),
          contextSentence: context,
          due: word.due,
        ),
      );
    }

    for (final grammar in await grammarRepository.due(now: now)) {
      final point = grammarMatcher.pointById(grammar.grammarPointId);
      final sentenceId = await grammarRepository.latestSightingSentenceId(
        grammar.id,
      );
      final context = sentenceId == null
          ? null
          : await documentRepository.sentenceContent(sentenceId);
      cards.add(
        ReviewCard(
          kind: ReviewCardKind.grammar,
          entryId: grammar.id,
          front: point?.pattern ?? grammar.grammarPointId,
          back: point?.explanation ?? 'Grammar point not found.',
          contextSentence: context,
          due: grammar.due,
        ),
      );
    }

    cards.sort((a, b) => a.due.compareTo(b.due));
    return ReviewQueueState(cards: cards, index: 0, isRevealed: false);
  }

  /// Reuses `definition_rendering.dart`'s structured-content-aware parser --
  /// Yomitan's `definitionsJson` array can mix plain strings with
  /// `{type: "structured-content", ...}` objects (common even for JMdict's
  /// own conversion, not just monolingual dictionaries), so a naive
  /// `.cast<String>()` throws the moment it hits one of those, crashing the
  /// whole review deck rather than just that one card's definition text.
  String _definitionText(DictionaryLookupHit hit) {
    return parseDefinitionEntries(hit.term.definitionsJson).join('; ');
  }

  /// Tap-to-reveal: shows the current card's [ReviewCard.back]/
  /// [ReviewCard.contextSentence] and the rating buttons.
  void reveal() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(isRevealed: true));
  }

  /// Scores the current card via the real FSRS scheduler (spec §12's rating
  /// buttons) and advances to the next one.
  Future<void> rate(Rating rating) async {
    final queue = state.value;
    final card = queue?.current;
    if (queue == null || card == null) return;

    switch (card.kind) {
      case ReviewCardKind.word:
        await ref
            .read(wordCollectionRepositoryProvider)
            .review(card.entryId, rating);
      case ReviewCardKind.grammar:
        await ref
            .read(grammarCollectionRepositoryProvider)
            .review(card.entryId, rating);
    }

    state = AsyncData(
      queue.copyWith(index: queue.index + 1, isRevealed: false),
    );
  }
}
