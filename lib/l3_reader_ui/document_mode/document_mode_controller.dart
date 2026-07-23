import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_repository.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_matcher.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_point.dart';

import '../reader_mining_session.dart';
import '../reading_position.dart';

export '../reading_position.dart' show CurrentDocument, currentDocumentProvider;

/// Document Mode's whole-book state (spec §7): unlike Card Mode's one
/// sentence at a time, every chapter/sentence is potentially on screen at
/// once via scrolling, so this holds the full [document] rather than a
/// single current sentence/card index.
///
/// [initialSentenceId] is where the reader view should scroll to right
/// after building -- either the shared reading position left by a prior
/// Card Mode/Document Mode session (spec §5), or the book's first sentence
/// if nothing has been read yet. It's a sentence ID rather than a raw list
/// index because the widget building the scrollable list is the one that
/// knows its own item numbering (it interleaves chapter-header rows with
/// sentence rows); re-deriving that numbering here would just be a second,
/// easy-to-desync copy of it.
class DocumentModeState {
  const DocumentModeState({
    required this.document,
    required this.initialSentenceId,
  });

  final Document document;
  final String initialSentenceId;
}

final documentModeControllerProvider =
    AsyncNotifierProvider<DocumentModeController, DocumentModeState>(
      DocumentModeController.new,
    );

/// Drives one Document Mode session over whatever [currentDocumentProvider]
/// currently holds (spec §7). Like [CardModeController]
/// (`../card_mode/card_mode_controller.dart`), the real tokenize/lookup/
/// mine/undo logic lives in the shared [ReaderMiningSession] -- this class
/// owns only Document Mode's own concerns: lazily tokenizing whichever
/// sentences the reader actually scrolls to, and keeping the shared
/// reading-position provider up to date as they do.
///
/// **Scope note** (mirrors `CardModeController`'s own): the spec's
/// drag-across-characters tokenizer-boundary override isn't implemented
/// this pass -- no importer/tokenizer surface yet exists for a user
/// override to feed back into. Double-tap's grammar breakdown popup shows
/// spec §8's layer 1 (token gloss) and layer 2 (matched grammar points,
/// [matchGrammarFor]) together; the LLM explanation layer is a later,
/// network-dependent phase, same as Card Mode.
class DocumentModeController extends AsyncNotifier<DocumentModeState> {
  late ReaderMiningSession _mining;
  final Map<String, List<Token>> _tokenCache = {};
  final Map<String, List<GrammarMatch>> _grammarMatchCache = {};

  @override
  Future<DocumentModeState> build() async {
    final document = ref.watch(currentDocumentProvider);
    if (document == null) {
      throw StateError(
        'DocumentModeController.build: no document loaded -- set '
        'currentDocumentProvider before watching documentModeControllerProvider.',
      );
    }
    _mining = ReaderMiningSession(ref);
    _tokenCache.clear();
    _grammarMatchCache.clear();

    final storedSentenceId = ref.read(currentSentencePositionProvider);
    final initialSentenceId =
        (storedSentenceId != null && _containsSentence(document, storedSentenceId))
        ? storedSentenceId
        : _firstSentenceId(document);

    return DocumentModeState(
      document: document,
      initialSentenceId: initialSentenceId,
    );
  }

  bool _containsSentence(Document document, String sentenceId) {
    for (final chapter in document.chapters) {
      for (final block in chapter.blocks) {
        for (final sentence in block.sentences) {
          if (sentence.id == sentenceId) return true;
        }
      }
    }
    return false;
  }

  String _firstSentenceId(Document document) {
    for (final chapter in document.chapters) {
      for (final block in chapter.blocks) {
        for (final sentence in block.sentences) {
          return sentence.id;
        }
      }
    }
    throw StateError(
      'DocumentModeController: document "${document.id}" has no sentences.',
    );
  }

  /// Real (Sudachi-tokenized, reconciled) tokens for [sentence], memoized per
  /// controller instance -- Document Mode's scrollable list only needs to
  /// tokenize sentences as they're actually built/scrolled to, and shouldn't
  /// redo that work every time the list widget rebuilds the same row.
  Future<List<Token>> tokensFor(Sentence sentence) async {
    final cached = _tokenCache[sentence.id];
    if (cached != null) return cached;
    final tokens = await _mining.tokenizeSentence(sentence);
    _tokenCache[sentence.id] = tokens;
    return tokens;
  }

  /// Spec §8 layer 2's matches for [sentence], memoized per controller
  /// instance -- same reasoning as [tokensFor].
  Future<List<GrammarMatch>> matchGrammarFor(Sentence sentence) async {
    final cached = _grammarMatchCache[sentence.id];
    if (cached != null) return cached;
    final matches = await _mining.matchGrammar(sentence);
    _grammarMatchCache[sentence.id] = matches;
    return matches;
  }

  /// Called by the reader view as the reader scrolls (spec §5's shared
  /// position sync) -- whichever sentence it considers "currently being
  /// read" (e.g. topmost visible), so switching to Card Mode resumes there.
  void reportVisibleSentence(String sentenceId) {
    ref.read(currentSentencePositionProvider.notifier).set(sentenceId);
  }

  Future<List<DictionaryLookupHit>> lookupWord(Token token) =>
      _mining.lookupWord(token);

  /// Same mining rules as Card Mode (spec §7), but -- unlike
  /// [CardModeController.mineWord] -- there's no single "current sentence"
  /// to read the source from, since every sentence on screen is equally
  /// "current" in a continuous view. Callers pass whichever sentence
  /// actually contains the tapped [token].
  Future<void> mineWord(
    Token token,
    List<DictionaryLookupHit> senses, {
    required String sentenceId,
  }) async {
    final document = state.value?.document;
    if (document == null) return;
    await _mining.mineWord(
      token,
      senses,
      workId: document.id,
      sentenceId: sentenceId,
    );
  }

  Future<void> removeWord(String dictForm, String reading) =>
      _mining.removeWord(dictForm, reading);

  /// Grammar-side mirror of [mineWord] -- see that method's own doc comment
  /// for why [sentenceId] is required here (no single "current sentence" in
  /// a continuous view).
  Future<void> mineGrammarPoint(
    GrammarPoint point, {
    required String sentenceId,
  }) async {
    final document = state.value?.document;
    if (document == null) return;
    await _mining.mineGrammarPoint(
      point,
      workId: document.id,
      sentenceId: sentenceId,
    );
  }

  Future<void> removeGrammarPoint(String grammarPointId) =>
      _mining.removeGrammarPoint(grammarPointId);

  Future<void> undoLastMining() => _mining.undoLastMining();
}
