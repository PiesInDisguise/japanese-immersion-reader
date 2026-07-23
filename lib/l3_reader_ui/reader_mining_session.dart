import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_repository.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_matcher.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_point.dart';
import 'package:japanese_immersion_reader/l2_linguistics/tokenizer/reconcile.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/mining_engine.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/source_ref.dart';

import '../app/services.dart';

/// The real-tokenization/lookup/mining logic shared by every reading mode
/// (Card Mode and Document Mode both need it identically -- spec §7: "All
/// mining rules, undo behavior, and settings carry over unchanged from Card
/// Mode"). Written once here rather than duplicated per-controller, same
/// reasoning as `MiningEngine` being shared by the word/grammar collection
/// repositories in `lib/l4_mining/collection/`.
///
/// Not itself a riverpod controller/provider -- a plain class a mode's own
/// `AsyncNotifier` constructs and holds (with its own `Ref`), since the
/// *session-scoped* state here (`_lastMineResult`, for undo) is genuinely
/// per-reading-session, not shared app-wide the way `tokenizerProvider` etc.
/// are.
///
/// **Scope note** (mirrors `CardModeController`'s own): auto-add-ON mining
/// only -- `WordCollectionRepository.mine`/`GrammarCollectionRepository.mine`
/// decide fresh-add vs. reset-to-new-if-already-collected internally.
/// Auto-add OFF's +/- toggle needs an "is this already collected" query
/// that doesn't exist yet, plus a settings screen to choose the mode.
class ReaderMiningSession {
  ReaderMiningSession(this._ref);

  final Ref _ref;
  MineResult? _lastMineResult;

  /// Which repository [_lastMineResult] came from, so [undoLastMining]
  /// reverses it against the right one -- words and grammar points share
  /// [MineResult]'s shape (see `mining_engine.dart`) but live in separate
  /// tables/repositories.
  bool _lastMineWasGrammar = false;

  /// Real (Sudachi-tokenized, ruby/sourceRect/confidence-reconciled) tokens
  /// for [sentence] -- see `reconcile.dart` for what "reconciled" means and
  /// why L1's placeholder tokens alone aren't enough to show real content.
  Future<List<Token>> tokenizeSentence(Sentence sentence) async {
    final tokenizer = await _ref.read(tokenizerProvider.future);
    final sudachiTokens = await tokenizer.tokenize(sentence.surfaceText);
    return reconcileSentenceTokens(sentence.tokens, sudachiTokens);
  }

  /// Spec §8 layer 2: every grammar point (from the bundled database, spec
  /// §8's content note) whose pattern appears in [sentence]'s surface text.
  /// See `grammar_matcher.dart`'s own doc comment for why this is a
  /// surface-text regex match rather than a token-sequence one.
  Future<List<GrammarMatch>> matchGrammar(Sentence sentence) async {
    final matcher = await _ref.read(grammarDatabaseProvider.future);
    return matcher.matchSentence(sentence.surfaceText);
  }

  /// Tap-a-word (spec §6/§7): definition + reading popup content.
  Future<List<DictionaryLookupHit>> lookupWord(Token token) {
    return _ref
        .read(dictionaryRepositoryProvider)
        .lookup(
          dictForm: token.dictForm ?? token.surface,
          surfaceForm: token.surface,
          reading: token.reading,
        );
  }

  /// Auto-add-ON's core tap behavior: add fresh, or reset-to-new if already
  /// collected (spec §6) -- `WordCollectionRepository.mine` decides which
  /// internally. `senses` should come from whatever the popup's own
  /// [lookupWord] call already found for this token, so mining and looking
  /// up a word always agree on which dictionary senses it's associated
  /// with. `workId`/`sentenceId` identify where this sighting came from
  /// (spec §11's `sourceRefs`).
  Future<void> mineWord(
    Token token,
    List<DictionaryLookupHit> senses, {
    required String workId,
    required String sentenceId,
  }) async {
    final repository = _ref.read(wordCollectionRepositoryProvider);
    _lastMineResult = await repository.mine(
      dictForm: token.dictForm ?? token.surface,
      reading: token.reading ?? token.surface,
      senseIds: [for (final hit in senses) hit.term.id],
      source: SourceRef(
        workId: workId,
        sentenceId: sentenceId,
        mediaType: CollectionMediaType.lightNovel,
      ),
    );
    _lastMineWasGrammar = false;
  }

  /// Long-press-to-remove (spec §6/§7), given the word's own
  /// dictForm/reading (its collection identity -- see
  /// `contentDerivedWordId`).
  Future<void> removeWord(String dictForm, String reading) {
    _lastMineResult = null;
    return _ref
        .read(wordCollectionRepositoryProvider)
        .remove(dictForm: dictForm, reading: reading);
  }

  /// Tap-a-matched-grammar-point (spec §8 layer 2: "tappable and mines into
  /// the grammar dictionary") -- the grammar-side mirror of [mineWord].
  /// Needs no `senses` equivalent: a [GrammarPoint]'s explanation/examples
  /// already live in the bundled database itself, unlike a word's dictionary
  /// senses, which come from a separate lookup.
  Future<void> mineGrammarPoint(
    GrammarPoint point, {
    required String workId,
    required String sentenceId,
  }) async {
    final repository = _ref.read(grammarCollectionRepositoryProvider);
    _lastMineResult = await repository.mine(
      grammarPointId: point.id,
      source: SourceRef(
        workId: workId,
        sentenceId: sentenceId,
        mediaType: CollectionMediaType.lightNovel,
      ),
    );
    _lastMineWasGrammar = true;
  }

  /// Long-press-to-remove for a matched grammar point -- the grammar-side
  /// mirror of [removeWord].
  Future<void> removeGrammarPoint(String grammarPointId) {
    _lastMineResult = null;
    return _ref
        .read(grammarCollectionRepositoryProvider)
        .remove(grammarPointId: grammarPointId);
  }

  /// The undo-toast action (spec §6/§7): reverses whatever the *last*
  /// [mineWord]/[mineGrammarPoint] call did, whether that was a fresh add
  /// or a reset. A no-op if nothing has been mined yet this session, or the
  /// last action was already undone/removed.
  Future<void> undoLastMining() async {
    final result = _lastMineResult;
    if (result == null) return;
    _lastMineResult = null;
    if (_lastMineWasGrammar) {
      await _ref.read(grammarCollectionRepositoryProvider).undo(result);
    } else {
      await _ref.read(wordCollectionRepositoryProvider).undo(result);
    }
  }
}
