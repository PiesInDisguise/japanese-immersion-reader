import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/app/services.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_repository.dart';
import 'package:japanese_immersion_reader/l2_linguistics/tokenizer/tokenizer.dart';
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
    this.frontHighlightStart,
    this.frontHighlightEnd,
  });

  final ReviewCardKind kind;
  final String entryId;

  /// Spec §12's default recognition card type: what the reader sees first
  /// (a word's dictForm+reading, or a grammar point's display pattern).
  /// Still populated even when [frontHighlightStart]/[frontHighlightEnd] are
  /// set (as a fallback/for accessibility), but `review_screen.dart` prefers
  /// [contextSentence] with the highlighted span when those are present.
  final String front;

  /// Revealed on tap/button (a word's dictionary definitions joined, or a
  /// grammar point's explanation).
  final String back;

  final String? contextSentence;
  final DateTime due;

  /// The `[start, end)` character span of this word within
  /// [contextSentence] to highlight when the "show sentence on front"
  /// setting is on -- both null if that setting is off, [contextSentence]
  /// is null, or the word couldn't be relocated in it (see
  /// `ReviewController.build`'s re-tokenize-and-match step). Always null
  /// for grammar cards: there's no single matching span to find. A non-null
  /// pair always satisfies `0 <= frontHighlightStart < frontHighlightEnd <=
  /// contextSentence!.length`.
  final int? frontHighlightStart;
  final int? frontHighlightEnd;
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

/// Keyed by [ReviewController.workId] -- `null` is spec's "All" deck
/// (every due word/grammar point, regardless of book); a real document id
/// scopes the deck to only what was sighted in that book (see
/// `WordCollectionRepository.dueForWork`/`GrammarCollectionRepository.
/// dueForWork`). [ReviewDeckPickerScreen] is what actually offers both.
final reviewControllerProvider =
    AsyncNotifierProvider.family<ReviewController, ReviewQueueState, String?>(
      ReviewController.new,
    );

/// Drives one review-deck session (spec §12): builds the due queue (words +
/// grammar points, earliest-due first, optionally scoped to one book via
/// [workId]) once, then reveals/rates one card at a time. Real scheduling
/// itself lives in `ReviewEngine`
/// (`lib/l4_mining/collection/review_engine.dart`), reached through
/// `WordCollectionRepository.review`/`GrammarCollectionRepository.review` --
/// this class only owns the queue/reveal-state concern, mirroring how
/// `CardModeController` only owns card position on top of the shared
/// `ReaderMiningSession`.
class ReviewController extends AsyncNotifier<ReviewQueueState> {
  ReviewController(this.workId);

  /// `null` for spec's "All" deck; a document id to scope this session to
  /// just that book's due words/grammar points.
  final String? workId;

  @override
  Future<ReviewQueueState> build() async {
    final wordRepository = ref.watch(wordCollectionRepositoryProvider);
    final grammarRepository = ref.watch(grammarCollectionRepositoryProvider);
    final dictionaryRepository = ref.watch(dictionaryRepositoryProvider);
    final documentRepository = ref.watch(documentRepositoryProvider);
    final grammarMatcher = await ref.watch(grammarDatabaseProvider.future);
    final settings = await ref.watch(appSettingsProvider.future);
    // Only pay for a tokenizer instance when the setting that needs it is
    // actually on -- most callers never touch this.
    final tokenizer = settings.reviewShowSentenceOnFront
        ? await ref.watch(tokenizerProvider.future)
        : null;

    final now = DateTime.now().toUtc();
    final cards = <ReviewCard>[];

    final dueWords = workId == null
        ? await wordRepository.due(now: now)
        : await wordRepository.dueForWork(workId!, now: now);
    for (final word in dueWords) {
      final hits = await dictionaryRepository.lookup(
        dictForm: word.dictForm,
        surfaceForm: word.dictForm,
        reading: word.reading,
      );
      final sentenceId = await wordRepository.latestSightingSentenceId(word.id);
      final context = sentenceId == null
          ? null
          : await documentRepository.sentenceContent(sentenceId);
      final highlight = tokenizer == null || context == null
          ? null
          : await _findHighlightSpan(
              tokenizer,
              context,
              dictForm: word.dictForm,
            );
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
          frontHighlightStart: highlight?.$1,
          frontHighlightEnd: highlight?.$2,
        ),
      );
    }

    final dueGrammars = workId == null
        ? await grammarRepository.due(now: now)
        : await grammarRepository.dueForWork(workId!, now: now);
    for (final grammar in dueGrammars) {
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

  /// Re-tokenizes [sentence] (the word's own stored source sentence text)
  /// and returns the `[start, end)` character span of whichever token's
  /// `dictForm` matches [dictForm] -- needed because a mined word's surface
  /// form in its sentence is usually conjugated (e.g. 走った for dictForm
  /// 走る), so a plain substring search on [dictForm] itself would usually
  /// fail to find it at all. Tokens are assumed to concatenate back to
  /// exactly [sentence] with no gaps (true of every tokenizer this app uses
  /// -- see how Card Mode/Document Mode already render a sentence as nothing
  /// but its tokens' surfaces in sequence), so each token's offset is just
  /// the running sum of every earlier token's surface length.
  ///
  /// Matches on [dictForm] alone, not also the word's stored `reading`:
  /// that reading reflects whatever conjugation the word had at *mine*
  /// time, which can genuinely differ from its conjugation in [sentence] --
  /// the *latest* sighting's sentence, which may not be the same sighting
  /// the word was first mined from (re-tap "forgot it" resets don't update
  /// `reading`; see `WordCollectionRepository.mine`'s doc comment). A
  /// same-dictForm collision within one sentence is rare enough not to
  /// bother disambiguating against a `reading` that might itself be stale.
  ///
  /// Returns `null` if no token matches (rare -- e.g. the sentence text
  /// changed since this word was mined) rather than guessing; the caller
  /// falls back to showing the sentence with no highlighted span.
  Future<(int, int)?> _findHighlightSpan(
    Tokenizer tokenizer,
    String sentence, {
    required String dictForm,
  }) async {
    final tokens = await tokenizer.tokenize(sentence);
    var offset = 0;
    for (final token in tokens) {
      final tokenDictForm = token.dictForm ?? token.surface;
      if (tokenDictForm == dictForm) {
        return (offset, offset + token.surface.length);
      }
      offset += token.surface.length;
    }
    return null;
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
