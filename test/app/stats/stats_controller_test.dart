// ProviderContainer-level tests, no widget tree -- every dependency is
// overridden with an in-memory fake, same pattern as
// review_controller_test.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/services.dart';
import 'package:japanese_immersion_reader/app/stats/reading_activity_repository.dart';
import 'package:japanese_immersion_reader/app/stats/stats_controller.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l2_linguistics/tokenizer/tokenizer.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/card_mode_controller.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/grammar_collection_repository.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/word_collection_repository.dart';

AppDatabase? _sharedInertDatabase;
AppDatabase _inertDatabase() => _sharedInertDatabase ??= AppDatabase();

class FakeWordCollectionRepository extends WordCollectionRepository {
  FakeWordCollectionRepository({this.collectedCount = 0, Set<String>? known})
    : _known = known ?? const {},
      super(_inertDatabase());

  final int collectedCount;
  final Set<String> _known;

  @override
  Future<int> count() async => collectedCount;

  @override
  Future<bool> isCollected({
    required String dictForm,
    required String reading,
  }) async => _known.contains('$dictForm|$reading');
}

class FakeGrammarCollectionRepository extends GrammarCollectionRepository {
  FakeGrammarCollectionRepository({this.collectedCount = 0})
    : super(_inertDatabase());

  final int collectedCount;

  @override
  Future<int> count() async => collectedCount;
}

class FakeReadingActivityRepository extends ReadingActivityRepository {
  FakeReadingActivityRepository({
    this.streak = 0,
    this.totalSeconds = 0,
    Map<DateTime, int>? heatmap,
  }) : _heatmap = heatmap ?? const {},
       super(_inertDatabase());

  final int streak;
  final int totalSeconds;
  final Map<DateTime, int> _heatmap;

  @override
  Future<int> currentStreakDays({DateTime? now}) async => streak;

  @override
  Future<int> totalSecondsRead() async => totalSeconds;

  @override
  Future<Map<DateTime, int>> activityByDay({
    required int days,
    DateTime? now,
  }) async => _heatmap;
}

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

class FixedCurrentDocument extends CurrentDocument {
  FixedCurrentDocument(this._document);
  final Document? _document;

  @override
  Document? build() => _document;
}

Document _buildDocument() {
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
                tokens: const [Token(surface: '猫が好きです。')],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  ProviderContainer buildContainer({
    FakeWordCollectionRepository? wordRepository,
    FakeGrammarCollectionRepository? grammarRepository,
    FakeReadingActivityRepository? activityRepository,
    Document? document,
    FakeTokenizer? tokenizer,
  }) {
    return ProviderContainer(
      overrides: [
        wordCollectionRepositoryProvider.overrideWithValue(
          wordRepository ?? FakeWordCollectionRepository(),
        ),
        grammarCollectionRepositoryProvider.overrideWithValue(
          grammarRepository ?? FakeGrammarCollectionRepository(),
        ),
        readingActivityRepositoryProvider.overrideWithValue(
          activityRepository ?? FakeReadingActivityRepository(),
        ),
        currentDocumentProvider.overrideWith(
          () => FixedCurrentDocument(document),
        ),
        tokenizerProvider.overrideWith(
          (ref) async => tokenizer ?? FakeTokenizer(const {}),
        ),
      ],
    );
  }

  test('reports counts/streak/time-read from the repositories', () async {
    final container = buildContainer(
      wordRepository: FakeWordCollectionRepository(collectedCount: 5),
      grammarRepository: FakeGrammarCollectionRepository(collectedCount: 2),
      activityRepository: FakeReadingActivityRepository(
        streak: 3,
        totalSeconds: 7200,
      ),
    );
    addTearDown(container.dispose);

    final state = await container.read(statsControllerProvider.future);

    expect(state.wordsMinedCount, 5);
    expect(state.grammarPointsMinedCount, 2);
    expect(state.currentStreakDays, 3);
    expect(state.totalSecondsRead, 7200);
  });

  test('comprehensionPercent is null with no document open', () async {
    final container = buildContainer();
    addTearDown(container.dispose);

    final state = await container.read(statsControllerProvider.future);

    expect(state.comprehensionPercent, isNull);
  });

  test('computes comprehensionPercent by tokenizing the first chapter', () async {
    final container = buildContainer(
      document: _buildDocument(),
      wordRepository: FakeWordCollectionRepository(known: {'猫|ネコ'}),
      tokenizer: FakeTokenizer({
        '猫が好きです。': const [
          Token(surface: '猫', dictForm: '猫', reading: 'ネコ'),
          Token(surface: 'が', dictForm: 'が', reading: 'ガ'),
          Token(surface: '好き', dictForm: '好き', reading: 'スキ'),
          Token(surface: 'です', dictForm: 'です', reading: 'デス'),
          Token(surface: '。', dictForm: '。', reading: '。'),
        ],
      }),
    );
    addTearDown(container.dispose);

    final state = await container.read(statsControllerProvider.future);

    // 4 non-punctuation tokens, 1 collected ("猫").
    expect(state.comprehensionPercent, 0.25);
  });
}
