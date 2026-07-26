// ProviderContainer-level tests, no widget tree -- every dependency
// (including grammarDatabaseProvider, which normally loads a bundled asset
// via rootBundle) is overridden with an in-memory fake, so this suite never
// touches a real database, real asset loading, or the known
// testWidgets+rootBundle hang (see the grammar-point database commit
// history).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/document_repository.dart';
import 'package:japanese_immersion_reader/app/services.dart';
import 'package:japanese_immersion_reader/app/settings_repository.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_repository.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_matcher.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_point.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/grammar_collection_repository.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/word_collection_repository.dart';
import 'package:japanese_immersion_reader/l5_srs/review_ui/review_controller.dart';

import '../../l3_reader_ui/card_mode/card_mode_test_helpers.dart'
    show FakeSettingsRepository, FakeTokenizer;

AppDatabase? _sharedInertDatabase;
AppDatabase _inertDatabase() => _sharedInertDatabase ??= AppDatabase();

const _grammarPoint = GrammarPoint(
  id: 'te-iru-progressive',
  pattern: '～ている',
  matcher: 'ている',
  jlptLevel: 'N5',
  explanation: 'progressive/resulting state',
  examples: [],
);

class FakeWordCollectionRepository extends WordCollectionRepository {
  FakeWordCollectionRepository() : super(_inertDatabase());

  List<DueWord> dueWords = [];
  final Map<String, String> sentenceIdsByEntry = {};
  final List<({String id, Rating rating})> reviewCalls = [];

  @override
  Future<List<DueWord>> due({DateTime? now}) async => dueWords;

  @override
  Future<String?> latestSightingSentenceId(String id) async =>
      sentenceIdsByEntry[id];

  @override
  Future<void> review(String id, Rating rating, {DateTime? now}) async {
    reviewCalls.add((id: id, rating: rating));
  }
}

class FakeGrammarCollectionRepository extends GrammarCollectionRepository {
  FakeGrammarCollectionRepository() : super(_inertDatabase());

  List<DueGrammar> dueGrammars = [];
  final Map<String, String> sentenceIdsByEntry = {};
  final List<({String id, Rating rating})> reviewCalls = [];

  @override
  Future<List<DueGrammar>> due({DateTime? now}) async => dueGrammars;

  @override
  Future<String?> latestSightingSentenceId(String id) async =>
      sentenceIdsByEntry[id];

  @override
  Future<void> review(String id, Rating rating, {DateTime? now}) async {
    reviewCalls.add((id: id, rating: rating));
  }
}

class FakeDictionaryRepository extends DictionaryRepository {
  FakeDictionaryRepository([Map<String, List<DictionaryLookupHit>>? byDictForm])
    : _byDictForm = byDictForm ?? const {},
      super(_inertDatabase());

  final Map<String, List<DictionaryLookupHit>> _byDictForm;

  @override
  Future<List<DictionaryLookupHit>> lookup({
    required String dictForm,
    required String surfaceForm,
    String? reading,
  }) async {
    return _byDictForm[dictForm] ?? const [];
  }
}

class FakeDocumentRepository extends DocumentRepository {
  FakeDocumentRepository([Map<String, String>? bySentenceId])
    : _bySentenceId = bySentenceId ?? const {},
      super(_inertDatabase());

  final Map<String, String> _bySentenceId;

  @override
  Future<String?> sentenceContent(String sentenceId) async =>
      _bySentenceId[sentenceId];
}

DictionaryLookupHit _catHit() {
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

/// A hit whose `definitionsJson` mixes a plain string with a Yomitan
/// `structured-content` object -- the shape that used to crash the whole
/// review deck (a naive cast throwing a type error on the Map entry) rather
/// than degrading gracefully.
DictionaryLookupHit _structuredContentHit() {
  const entry = DictionaryTermEntry(
    id: 2,
    dictionaryId: 'dict-1',
    headword: '難しい',
    reading: 'むずかしい',
    readingNormalized: 'むずかしい',
    definitionTags: null,
    rules: '',
    score: 0,
    definitionsJson:
        '["difficult",'
        '{"type":"structured-content","content":"hard, tough"}]',
    sequence: 2,
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

void main() {
  late FakeWordCollectionRepository wordRepository;
  late FakeGrammarCollectionRepository grammarRepository;
  late FakeDictionaryRepository dictionaryRepository;
  late FakeDocumentRepository documentRepository;
  late ProviderContainer container;

  setUp(() {
    wordRepository = FakeWordCollectionRepository();
    grammarRepository = FakeGrammarCollectionRepository();
    dictionaryRepository = FakeDictionaryRepository({
      '猫': [_catHit()],
    });
    documentRepository = FakeDocumentRepository({'sentence-1': '猫が好きです。'});

    container = ProviderContainer(
      overrides: [
        wordCollectionRepositoryProvider.overrideWithValue(wordRepository),
        grammarCollectionRepositoryProvider.overrideWithValue(
          grammarRepository,
        ),
        dictionaryRepositoryProvider.overrideWithValue(dictionaryRepository),
        documentRepositoryProvider.overrideWithValue(documentRepository),
        grammarDatabaseProvider.overrideWith(
          (ref) async => GrammarMatcher([_grammarPoint]),
        ),
        // Default settings (reviewShowSentenceOnFront off) -- most tests
        // don't care about it, and this keeps `build()`'s
        // `tokenizerProvider` watch un-triggered for them.
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
      ],
    );
    addTearDown(container.dispose);
  });

  test('builds an empty queue when nothing is due', () async {
    final state = await container.read(reviewControllerProvider.future);
    expect(state.cards, isEmpty);
    expect(state.isComplete, isTrue);
  });

  test(
    'builds word cards with dictionary meaning and source context',
    () async {
      wordRepository.dueWords = [
        DueWord(
          id: 'word-1',
          dictForm: '猫',
          reading: 'ねこ',
          senseIds: const [1],
          due: DateTime.utc(2026, 1, 1),
        ),
      ];
      wordRepository.sentenceIdsByEntry['word-1'] = 'sentence-1';

      final state = await container.read(reviewControllerProvider.future);

      expect(state.cards, hasLength(1));
      final card = state.cards.single;
      expect(card.kind, ReviewCardKind.word);
      expect(card.front, '猫 (ねこ)');
      expect(card.back, 'cat; feline');
      expect(card.contextSentence, '猫が好きです。');
    },
  );

  test('builds a word card whose definitions mix plain strings and '
      'structured-content entries, without crashing', () async {
    dictionaryRepository = FakeDictionaryRepository({
      '難しい': [_structuredContentHit()],
    });
    container.dispose();
    container = ProviderContainer(
      overrides: [
        wordCollectionRepositoryProvider.overrideWithValue(wordRepository),
        grammarCollectionRepositoryProvider.overrideWithValue(
          grammarRepository,
        ),
        dictionaryRepositoryProvider.overrideWithValue(dictionaryRepository),
        documentRepositoryProvider.overrideWithValue(documentRepository),
        grammarDatabaseProvider.overrideWith(
          (ref) async => GrammarMatcher([_grammarPoint]),
        ),
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
      ],
    );
    addTearDown(container.dispose);
    wordRepository.dueWords = [
      DueWord(
        id: 'word-2',
        dictForm: '難しい',
        reading: 'むずかしい',
        senseIds: const [2],
        due: DateTime.utc(2026, 1, 1),
      ),
    ];

    final state = await container.read(reviewControllerProvider.future);

    expect(state.cards, hasLength(1));
    expect(state.cards.single.back, 'difficult; hard, tough');
  });

  test('builds grammar cards from the grammar-point database', () async {
    grammarRepository.dueGrammars = [
      DueGrammar(
        id: 'grammar-1',
        grammarPointId: 'te-iru-progressive',
        due: DateTime.utc(2026, 1, 1),
      ),
    ];

    final state = await container.read(reviewControllerProvider.future);

    expect(state.cards, hasLength(1));
    final card = state.cards.single;
    expect(card.kind, ReviewCardKind.grammar);
    expect(card.front, '～ている');
    expect(card.back, 'progressive/resulting state');
    expect(card.contextSentence, isNull);
  });

  test('merges words and grammar points, sorted earliest-due-first', () async {
    wordRepository.dueWords = [
      DueWord(
        id: 'word-1',
        dictForm: '猫',
        reading: 'ねこ',
        senseIds: const [],
        due: DateTime.utc(2026, 1, 10),
      ),
    ];
    grammarRepository.dueGrammars = [
      DueGrammar(
        id: 'grammar-1',
        grammarPointId: 'te-iru-progressive',
        due: DateTime.utc(2026, 1, 5),
      ),
    ];

    final state = await container.read(reviewControllerProvider.future);

    expect(state.cards.map((c) => c.entryId), ['grammar-1', 'word-1']);
  });

  test('reveal shows the answer without advancing the queue', () async {
    wordRepository.dueWords = [
      DueWord(
        id: 'word-1',
        dictForm: '猫',
        reading: 'ねこ',
        senseIds: const [],
        due: DateTime.utc(2026, 1, 1),
      ),
    ];
    await container.read(reviewControllerProvider.future);

    container.read(reviewControllerProvider.notifier).reveal();

    final state = container.read(reviewControllerProvider).value!;
    expect(state.isRevealed, isTrue);
    expect(state.index, 0);
  });

  test(
    'rate calls the right repository\'s review() and advances the queue',
    () async {
      wordRepository.dueWords = [
        DueWord(
          id: 'word-1',
          dictForm: '猫',
          reading: 'ねこ',
          senseIds: const [],
          due: DateTime.utc(2026, 1, 1),
        ),
      ];
      grammarRepository.dueGrammars = [
        DueGrammar(
          id: 'grammar-1',
          grammarPointId: 'te-iru-progressive',
          due: DateTime.utc(2026, 1, 2),
        ),
      ];
      await container.read(reviewControllerProvider.future);

      final notifier = container.read(reviewControllerProvider.notifier);
      await notifier.rate(Rating.good);

      expect(wordRepository.reviewCalls, [(id: 'word-1', rating: Rating.good)]);
      var state = container.read(reviewControllerProvider).value!;
      expect(state.index, 1);
      expect(state.isRevealed, isFalse);
      expect(state.current!.entryId, 'grammar-1');

      await notifier.rate(Rating.again);
      expect(grammarRepository.reviewCalls, [
        (id: 'grammar-1', rating: Rating.again),
      ]);
      state = container.read(reviewControllerProvider).value!;
      expect(state.isComplete, isTrue);
    },
  );

  group('reviewShowSentenceOnFront', () {
    const showSentenceSettings = AppSettings(
      llmApiKey: null,
      llmExplanationsEnabled: true,
      ttsEnabled: false,
      pitchAccentAudioEnabled: false,
      reviewShowSentenceOnFront: true,
    );

    test('off by default: no highlight span is computed, and the tokenizer is '
        'never even asked for one', () async {
      wordRepository.dueWords = [
        DueWord(
          id: 'word-1',
          dictForm: '猫',
          reading: 'ねこ',
          senseIds: const [],
          due: DateTime.utc(2026, 1, 1),
        ),
      ];
      wordRepository.sentenceIdsByEntry['word-1'] = 'sentence-1';

      final state = await container.read(reviewControllerProvider.future);

      final card = state.cards.single;
      expect(card.frontHighlightStart, isNull);
      expect(card.frontHighlightEnd, isNull);
    });

    test('when on, re-tokenizes the context sentence and highlights the span '
        'whose dictForm matches -- even though the word\'s own stored '
        '`reading` (from whenever it was first mined) no longer matches this '
        'sentence\'s conjugation', () async {
      documentRepository = FakeDocumentRepository({'sentence-1': '猫が走った。'});
      container.dispose();
      container = ProviderContainer(
        overrides: [
          wordCollectionRepositoryProvider.overrideWithValue(wordRepository),
          grammarCollectionRepositoryProvider.overrideWithValue(
            grammarRepository,
          ),
          dictionaryRepositoryProvider.overrideWithValue(dictionaryRepository),
          documentRepositoryProvider.overrideWithValue(documentRepository),
          grammarDatabaseProvider.overrideWith(
            (ref) async => GrammarMatcher([_grammarPoint]),
          ),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(showSentenceSettings),
          ),
          tokenizerProvider.overrideWith(
            (ref) async => FakeTokenizer({
              '猫が走った。': const [
                Token(surface: '猫', dictForm: '猫', reading: 'ネコ'),
                Token(surface: 'が', dictForm: 'が', reading: 'ガ'),
                Token(surface: '走った', dictForm: '走る', reading: 'ハシッタ'),
                Token(surface: '。', dictForm: '。', reading: '。'),
              ],
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      wordRepository.dueWords = [
        // Stored `reading` (ハシル, dictForm 走る's own reading) is
        // deliberately different from the token's actual surface reading
        // (ハシッタ) above -- proof this matches on dictForm alone.
        DueWord(
          id: 'word-1',
          dictForm: '走る',
          reading: 'ハシル',
          senseIds: const [],
          due: DateTime.utc(2026, 1, 1),
        ),
      ];
      wordRepository.sentenceIdsByEntry['word-1'] = 'sentence-1';

      final state = await container.read(reviewControllerProvider.future);

      final card = state.cards.single;
      expect(card.contextSentence, '猫が走った。');
      // '猫'(1) + 'が'(1) = offset 2; '走った' is 3 characters.
      expect(card.frontHighlightStart, 2);
      expect(card.frontHighlightEnd, 5);
    });

    test('falls back to no highlight span (but still keeps the context '
        "sentence) when the word can't be relocated in it", () async {
      documentRepository = FakeDocumentRepository({'sentence-1': '犬が鳴いた。'});
      container.dispose();
      container = ProviderContainer(
        overrides: [
          wordCollectionRepositoryProvider.overrideWithValue(wordRepository),
          grammarCollectionRepositoryProvider.overrideWithValue(
            grammarRepository,
          ),
          dictionaryRepositoryProvider.overrideWithValue(dictionaryRepository),
          documentRepositoryProvider.overrideWithValue(documentRepository),
          grammarDatabaseProvider.overrideWith(
            (ref) async => GrammarMatcher([_grammarPoint]),
          ),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(showSentenceSettings),
          ),
          tokenizerProvider.overrideWith(
            (ref) async => FakeTokenizer({
              '犬が鳴いた。': const [
                Token(surface: '犬', dictForm: '犬', reading: 'イヌ'),
                Token(surface: 'が', dictForm: 'が', reading: 'ガ'),
                Token(surface: '鳴いた', dictForm: '鳴く', reading: 'ナイタ'),
                Token(surface: '。', dictForm: '。', reading: '。'),
              ],
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      wordRepository.dueWords = [
        DueWord(
          id: 'word-1',
          dictForm: '猫',
          reading: 'ネコ',
          senseIds: const [],
          due: DateTime.utc(2026, 1, 1),
        ),
      ];
      wordRepository.sentenceIdsByEntry['word-1'] = 'sentence-1';

      final state = await container.read(reviewControllerProvider.future);

      final card = state.cards.single;
      expect(card.contextSentence, '犬が鳴いた。');
      expect(card.frontHighlightStart, isNull);
      expect(card.frontHighlightEnd, isNull);
    });

    test('never applies to grammar cards', () async {
      grammarRepository.dueGrammars = [
        DueGrammar(
          id: 'grammar-1',
          grammarPointId: 'te-iru-progressive',
          due: DateTime.utc(2026, 1, 1),
        ),
      ];
      grammarRepository.sentenceIdsByEntry['grammar-1'] = 'sentence-1';
      container.dispose();
      container = ProviderContainer(
        overrides: [
          wordCollectionRepositoryProvider.overrideWithValue(wordRepository),
          grammarCollectionRepositoryProvider.overrideWithValue(
            grammarRepository,
          ),
          dictionaryRepositoryProvider.overrideWithValue(dictionaryRepository),
          documentRepositoryProvider.overrideWithValue(documentRepository),
          grammarDatabaseProvider.overrideWith(
            (ref) async => GrammarMatcher([_grammarPoint]),
          ),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(showSentenceSettings),
          ),
          tokenizerProvider.overrideWith(
            (ref) async => FakeTokenizer({'猫が好きです。': const []}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(reviewControllerProvider.future);

      final card = state.cards.single;
      expect(card.kind, ReviewCardKind.grammar);
      expect(card.frontHighlightStart, isNull);
      expect(card.frontHighlightEnd, isNull);
    });
  });
}
