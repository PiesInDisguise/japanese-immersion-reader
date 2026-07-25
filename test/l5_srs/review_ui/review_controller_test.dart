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
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_repository.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_matcher.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_point.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/grammar_collection_repository.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/word_collection_repository.dart';
import 'package:japanese_immersion_reader/l5_srs/review_ui/review_controller.dart';

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
    dictionaryRepository = FakeDictionaryRepository({'猫': [_catHit()]});
    documentRepository = FakeDocumentRepository({
      'sentence-1': '猫が好きです。',
    });

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
      ],
    );
    addTearDown(container.dispose);
  });

  test('builds an empty queue when nothing is due', () async {
    final state = await container.read(reviewControllerProvider.future);
    expect(state.cards, isEmpty);
    expect(state.isComplete, isTrue);
  });

  test('builds word cards with dictionary meaning and source context', () async {
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
  });

  test(
    'builds a word card whose definitions mix plain strings and '
    'structured-content entries, without crashing',
    () async {
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
    },
  );

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

  test('rate calls the right repository\'s review() and advances the queue', () async {
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
  });
}
