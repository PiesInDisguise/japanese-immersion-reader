// Shared fakes/harness for Card Mode's *and* Document Mode's widget tests
// (Document Mode's own suite imports this file rather than duplicating any
// of it -- see `test/l3_reader_ui/document_mode/document_mode_screen_test.dart`).
// Deliberately not named `*_test.dart` so `flutter test` doesn't try to run
// it as its own suite -- see the individual `*_test.dart` files for the
// actual test cases.
//
// Per the task brief: fakes are wired in at the *provider* level
// (`tokenizerProvider`/`dictionaryRepositoryProvider`/
// `wordCollectionRepositoryProvider`, all from `lib/app/services.dart`) so
// these widget tests never touch a real database or a real Sudachi
// tokenizer -- that heavier, real-integration style of test already exists
// elsewhere (e.g. `test/l2_linguistics/tokenizer/
// sudachi_reconcile_integration_test.dart`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/services.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_repository.dart';
import 'package:japanese_immersion_reader/l2_linguistics/tokenizer/tokenizer.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/card_mode_controller.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/card_mode_screen.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/document_mode/document_mode_screen.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/mining_engine.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/source_ref.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/word_collection_repository.dart';

/// An inert placeholder [AppDatabase], only ever used to satisfy
/// [DictionaryRepository]'s/[WordCollectionRepository]'s constructors below
/// -- every fake here overrides *every* method that would otherwise touch
/// it. Safe to construct with no setup: `AppDatabase()`'s connection is a
/// drift `LazyDatabase`, which never opens a real file or platform channel
/// until something actually issues a query against it (see
/// `lib/core/db/database.dart`), and these fakes never do.
///
/// Memoized to a single shared instance rather than one per fake: it's
/// never queried either way (nothing here is stateful), and constructing a
/// fresh `AppDatabase()` per fake makes drift log a harmless but noisy
/// "you've created the database class AppDatabase multiple times" warning
/// in every test.
AppDatabase? _sharedInertDatabase;
AppDatabase _inertDatabase() => _sharedInertDatabase ??= AppDatabase();

/// A [Tokenizer] whose output is entirely test-controlled: maps a whole
/// sentence's surface text to the token list "Sudachi" should return for
/// it, so a test picks exactly what `CardModeController`'s reconciliation
/// step sees. Every fixture registered here must have token surfaces that
/// concatenate back to the exact registered key -- `reconcileSentenceTokens`
/// enforces this (see `lib/l2_linguistics/tokenizer/reconcile.dart`) and
/// throws if it doesn't.
class FakeTokenizer implements Tokenizer {
  FakeTokenizer(this._bySurface);

  final Map<String, List<Token>> _bySurface;

  @override
  Future<List<Token>> tokenize(String text) async {
    final tokens = _bySurface[text];
    if (tokens == null) {
      throw StateError('FakeTokenizer: no fixture registered for "$text"');
    }
    return tokens;
  }
}

/// A [DictionaryRepository] whose `lookup` is entirely test-controlled,
/// keyed by the dictionary form the controller looks up with. Records every
/// call for assertions.
class FakeDictionaryRepository extends DictionaryRepository {
  FakeDictionaryRepository([Map<String, List<DictionaryLookupHit>>? byDictForm])
    : _byDictForm = byDictForm ?? const {},
      super(_inertDatabase());

  final Map<String, List<DictionaryLookupHit>> _byDictForm;
  final List<String> lookupCalls = [];

  @override
  Future<List<DictionaryLookupHit>> lookup({
    required String dictForm,
    required String surfaceForm,
    String? reading,
  }) async {
    lookupCalls.add(dictForm);
    return _byDictForm[dictForm] ?? const [];
  }
}

/// A [WordCollectionRepository] that never touches a database: `mine`/
/// `remove`/`undo` just record their arguments so a test can assert
/// `CardModeScreen` called through to the controller correctly.
class FakeWordCollectionRepository extends WordCollectionRepository {
  FakeWordCollectionRepository() : super(_inertDatabase());

  final List<({String dictForm, String reading, List<int> senseIds})>
  mineCalls = [];
  final List<({String dictForm, String reading})> removeCalls = [];
  final List<MineResult> undoCalls = [];

  int _nextSightingId = 1;

  @override
  Future<MineResult> mine({
    required String dictForm,
    required String reading,
    required List<int> senseIds,
    required SourceRef source,
  }) async {
    mineCalls.add((dictForm: dictForm, reading: reading, senseIds: senseIds));
    return MineResult.freshAdd(
      entryId: '$dictForm|$reading',
      sightingId: _nextSightingId++,
    );
  }

  @override
  Future<void> remove({
    required String dictForm,
    required String reading,
  }) async {
    removeCalls.add((dictForm: dictForm, reading: reading));
  }

  @override
  Future<void> undo(MineResult result) async {
    undoCalls.add(result);
  }
}

/// Overrides [currentDocumentProvider] with a fixed, already-loaded
/// [Document] -- standing in for "a separate part of the app" (per
/// `CardModeController`'s own doc comment) that sets this before Card Mode
/// ever watches `cardModeControllerProvider`.
class FixedCurrentDocument extends CurrentDocument {
  FixedCurrentDocument(this._document);

  final Document? _document;

  @override
  Document? build() => _document;
}

/// A minimal, three-sentence book: enough to exercise swiping forward,
/// backward, and hitting both ends. Every sentence's L1 tokens are a single
/// placeholder spanning the whole surface text with no reading/sourceRect/
/// confidence -- matching `Sentence`'s own doc comment for "no ruby
/// evidence available", so every displayed `reading` in tests comes
/// straight from the fake tokenizer below, not from a reconciled L1 ruby
/// span.
Document buildTestDocument() {
  return Document(
    id: 'doc-1',
    title: 'Test Book',
    sourceType: DocumentSourceType.epub,
    chapters: [
      Chapter(
        id: 'ch-1',
        index: 0,
        title: 'Chapter 1',
        blocks: [
          Block(
            id: 'block-1',
            index: 0,
            kind: BlockKind.paragraph,
            sentences: [
              Sentence(
                id: 'sent-0',
                index: 0,
                tokens: const [Token(surface: '猫が走る。')],
              ),
              Sentence(
                id: 'sent-1',
                index: 1,
                tokens: const [Token(surface: '犬が鳴く。')],
              ),
              Sentence(
                id: 'sent-2',
                index: 2,
                tokens: const [Token(surface: '鳥が飛ぶ。')],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// The fake "Sudachi" segmentation for [buildTestDocument]'s three
/// sentences -- surfaces concatenate back to each sentence's exact text, as
/// `reconcileSentenceTokens` requires.
FakeTokenizer buildTestTokenizer() {
  return FakeTokenizer({
    '猫が走る。': const [
      Token(surface: '猫', dictForm: '猫', reading: 'ネコ', pos: '名詞'),
      Token(surface: 'が', dictForm: 'が', reading: 'ガ', pos: '助詞'),
      Token(
        surface: '走る',
        dictForm: '走る',
        reading: 'ハシル',
        pos: '動詞',
        inflection: '五段-ラ行;終止形-一般',
      ),
      Token(surface: '。', dictForm: '。', reading: '。', pos: '補助記号'),
    ],
    '犬が鳴く。': const [
      Token(surface: '犬', dictForm: '犬', reading: 'イヌ', pos: '名詞'),
      Token(surface: 'が', dictForm: 'が', reading: 'ガ', pos: '助詞'),
      Token(
        surface: '鳴く',
        dictForm: '鳴く',
        reading: 'ナク',
        pos: '動詞',
        inflection: '五段-カ行;終止形-一般',
      ),
      Token(surface: '。', dictForm: '。', reading: '。', pos: '補助記号'),
    ],
    '鳥が飛ぶ。': const [
      Token(surface: '鳥', dictForm: '鳥', reading: 'トリ', pos: '名詞'),
      Token(surface: 'が', dictForm: 'が', reading: 'ガ', pos: '助詞'),
      Token(
        surface: '飛ぶ',
        dictForm: '飛ぶ',
        reading: 'トブ',
        pos: '動詞',
        inflection: '五段-バ行;終止形-一般',
      ),
      Token(surface: '。', dictForm: '。', reading: '。', pos: '補助記号'),
    ],
  });
}

/// A single dictionary hit for 猫 ("cat"), used by the lookup/mine tests.
DictionaryLookupHit buildCatLookupHit() {
  const entry = DictionaryTermEntry(
    id: 1,
    dictionaryId: 'dict-1',
    headword: '猫',
    reading: 'ねこ',
    readingNormalized: 'ねこ',
    definitionTags: null,
    rules: '',
    score: 0,
    definitionsJson: '["cat; feline"]',
    sequence: 1,
    termTags: '',
    importOrder: 0,
  );
  return const DictionaryLookupHit(
    term: entry,
    dictionaryId: 'dict-1',
    dictionaryTitle: 'Test Dictionary',
    dictionaryPriority: 0,
    matchedVia: MatchTier.dictionaryForm,
  );
}

/// Pumps [CardModeScreen] inside a [ProviderScope] with every dependency
/// [CardModeController]/`CardModeScreen` needs overridden with fakes.
/// [document] is left `null` to exercise the controller's own "no document
/// loaded" error path (`currentDocumentProvider`'s real default, per
/// `CurrentDocument.build`).
Future<void> pumpCardModeScreen(
  WidgetTester tester, {
  Document? document,
  required FakeTokenizer tokenizer,
  required FakeDictionaryRepository dictionaryRepository,
  required FakeWordCollectionRepository wordCollectionRepository,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentDocumentProvider.overrideWith(
          () => FixedCurrentDocument(document),
        ),
        tokenizerProvider.overrideWith((ref) async => tokenizer),
        dictionaryRepositoryProvider.overrideWithValue(dictionaryRepository),
        wordCollectionRepositoryProvider.overrideWithValue(
          wordCollectionRepository,
        ),
      ],
      child: const MaterialApp(home: CardModeScreen()),
    ),
  );
}

/// Pumps [DocumentModeScreen] inside a [ProviderScope] with the same set of
/// fake dependency overrides as [pumpCardModeScreen] -- both screens sit on
/// top of the same `tokenizerProvider`/`dictionaryRepositoryProvider`/
/// `wordCollectionRepositoryProvider`/`currentDocumentProvider` seams, so
/// there's nothing Document-Mode-specific to fake here beyond swapping
/// which screen widget gets pumped.
Future<void> pumpDocumentModeScreen(
  WidgetTester tester, {
  Document? document,
  required FakeTokenizer tokenizer,
  required FakeDictionaryRepository dictionaryRepository,
  required FakeWordCollectionRepository wordCollectionRepository,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentDocumentProvider.overrideWith(
          () => FixedCurrentDocument(document),
        ),
        tokenizerProvider.overrideWith((ref) async => tokenizer),
        dictionaryRepositoryProvider.overrideWithValue(dictionaryRepository),
        wordCollectionRepositoryProvider.overrideWithValue(
          wordCollectionRepository,
        ),
      ],
      child: const MaterialApp(home: DocumentModeScreen()),
    ),
  );
}
