// Plain `test()` over a `ProviderContainer` -- no widget tree, so this
// suite exercises `ReaderMiningSession.explainSentence`'s cache/call/cache-
// write logic without going anywhere near the known `testWidgets`+
// `rootBundle` hang (see the grammar-point database commit history). Every
// dependency is faked at the provider level, mirroring
// `test/l3_reader_ui/card_mode/card_mode_test_helpers.dart`'s own pattern --
// no real database or network call happens here.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/explanation_repository.dart';
import 'package:japanese_immersion_reader/app/services.dart';
import 'package:japanese_immersion_reader/app/settings_repository.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/core/ids/stable_id.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l2_linguistics/llm/grammar_explanation_client.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/reader_mining_session.dart';

/// Never queried by any fake below -- just satisfies
/// `SettingsRepository`/`ExplanationRepository`'s constructors. Same
/// reasoning as `card_mode_test_helpers.dart`'s own `_inertDatabase`.
AppDatabase? _sharedInertDatabase;
AppDatabase _inertDatabase() => _sharedInertDatabase ??= AppDatabase();

class FakeSettingsRepository extends SettingsRepository {
  FakeSettingsRepository(this._settings) : super(_inertDatabase());

  AppSettings _settings;

  @override
  Future<AppSettings> read() async => _settings;

  @override
  Stream<AppSettings> watch() => Stream.value(_settings);

  @override
  Future<void> update({
    String? llmApiKey,
    bool? llmExplanationsEnabled,
    bool? ttsEnabled,
    bool? pitchAccentAudioEnabled,
    Color? highlightColor,
    bool? autoAddToCollection,
    bool? reviewShowSentenceOnFront,
    bool? reviewSwipeUpEnabled,
    bool? reviewSwipeDownEnabled,
    bool? reviewSwipeLeftEnabled,
    bool? reviewSwipeRightEnabled,
  }) async {
    _settings = AppSettings(
      llmApiKey: llmApiKey ?? _settings.llmApiKey,
      llmExplanationsEnabled:
          llmExplanationsEnabled ?? _settings.llmExplanationsEnabled,
      ttsEnabled: ttsEnabled ?? _settings.ttsEnabled,
      pitchAccentAudioEnabled:
          pitchAccentAudioEnabled ?? _settings.pitchAccentAudioEnabled,
      highlightColor: highlightColor ?? _settings.highlightColor,
      autoAddToCollection: autoAddToCollection ?? _settings.autoAddToCollection,
      reviewShowSentenceOnFront:
          reviewShowSentenceOnFront ?? _settings.reviewShowSentenceOnFront,
      reviewSwipeUpEnabled:
          reviewSwipeUpEnabled ?? _settings.reviewSwipeUpEnabled,
      reviewSwipeDownEnabled:
          reviewSwipeDownEnabled ?? _settings.reviewSwipeDownEnabled,
      reviewSwipeLeftEnabled:
          reviewSwipeLeftEnabled ?? _settings.reviewSwipeLeftEnabled,
      reviewSwipeRightEnabled:
          reviewSwipeRightEnabled ?? _settings.reviewSwipeRightEnabled,
    );
  }
}

class FakeExplanationRepository extends ExplanationRepository {
  FakeExplanationRepository() : super(_inertDatabase());

  final Map<String, String> store = {};

  @override
  Future<String?> read(String id) async => store[id];

  @override
  Future<void> write(String id, String explanation) async {
    store[id] = explanation;
  }
}

/// Emits [chunks] in order and records how many times it was invoked, so
/// tests can assert a cache hit never reaches the client at all.
class FakeGrammarExplanationClient implements GrammarExplanationClient {
  FakeGrammarExplanationClient(this.chunks);

  final List<String> chunks;
  int callCount = 0;
  String? lastApiKey;

  @override
  Stream<String> streamExplanation({
    required String sentenceText,
    required String contextText,
  }) async* {
    callCount++;
    for (final chunk in chunks) {
      yield chunk;
    }
  }
}

/// Constructs a real [ReaderMiningSession] the same way every mode
/// controller does (`ReaderMiningSession(ref)`), so the session's `Ref`
/// stays valid for the lifetime of the test's [ProviderContainer].
final _testSessionProvider = Provider<ReaderMiningSession>(
  (ref) => ReaderMiningSession(ref),
);

Sentence _sentence(String id, String surface) => Sentence(
  id: id,
  index: 0,
  tokens: [Token(surface: surface)],
);

void main() {
  group('ReaderMiningSession.explanationsActive', () {
    test('true only when both an API key and the toggle are set', () async {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(
              const AppSettings(
                llmApiKey: 'sk-key',
                llmExplanationsEnabled: true,
                ttsEnabled: false,
                pitchAccentAudioEnabled: false,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final session = container.read(_testSessionProvider);
      expect(await session.explanationsActive(), isTrue);
    });

    test('false when no API key is configured', () async {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(AppSettings.defaults),
          ),
        ],
      );
      addTearDown(container.dispose);

      final session = container.read(_testSessionProvider);
      expect(await session.explanationsActive(), isFalse);
    });
  });

  group('ReaderMiningSession.explainSentence', () {
    test('returns the cached value and never calls the client', () async {
      final sentence = _sentence('s1', '猫が好きです。');
      final cacheId = contentDerivedExplanationId(
        sentenceText: sentence.surfaceText,
        contextText: '',
      );
      final explanationRepo = FakeExplanationRepository()
        ..store[cacheId] = 'Cached explanation.';
      final client = FakeGrammarExplanationClient(['should never be read']);

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(
              const AppSettings(
                llmApiKey: 'sk-key',
                llmExplanationsEnabled: true,
                ttsEnabled: false,
                pitchAccentAudioEnabled: false,
              ),
            ),
          ),
          explanationRepositoryProvider.overrideWithValue(explanationRepo),
          grammarExplanationClientFactoryProvider.overrideWithValue(
            (apiKey) => client,
          ),
        ],
      );
      addTearDown(container.dispose);

      final session = container.read(_testSessionProvider);
      final emissions = await session
          .explainSentence(sentence, contextSentences: const [])
          .toList();

      expect(emissions, ['Cached explanation.']);
      expect(client.callCount, 0);
    });

    test(
      'on a cache miss, streams the client\'s output and caches the final chunk',
      () async {
        final sentence = _sentence('s1', 'sentence text');
        final explanationRepo = FakeExplanationRepository();
        final client = FakeGrammarExplanationClient(['Hello', 'Hello world']);

        final container = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(
              FakeSettingsRepository(
                const AppSettings(
                  llmApiKey: 'sk-key',
                  llmExplanationsEnabled: true,
                  ttsEnabled: false,
                  pitchAccentAudioEnabled: false,
                ),
              ),
            ),
            explanationRepositoryProvider.overrideWithValue(explanationRepo),
            grammarExplanationClientFactoryProvider.overrideWithValue(
              (apiKey) => client,
            ),
          ],
        );
        addTearDown(container.dispose);

        final session = container.read(_testSessionProvider);
        final emissions = await session
            .explainSentence(sentence, contextSentences: const [])
            .toList();

        expect(emissions, ['Hello', 'Hello world']);
        expect(client.callCount, 1);

        final cacheId = contentDerivedExplanationId(
          sentenceText: sentence.surfaceText,
          contextText: '',
        );
        expect(explanationRepo.store[cacheId], 'Hello world');
      },
    );

    test('joins context sentences with newlines into the cache key', () async {
      final sentence = _sentence('s1', 'main line');
      final context = [_sentence('s0', 'before'), _sentence('s2', 'after')];
      final explanationRepo = FakeExplanationRepository();
      final client = FakeGrammarExplanationClient(['explanation']);

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(
              const AppSettings(
                llmApiKey: 'sk-key',
                llmExplanationsEnabled: true,
                ttsEnabled: false,
                pitchAccentAudioEnabled: false,
              ),
            ),
          ),
          explanationRepositoryProvider.overrideWithValue(explanationRepo),
          grammarExplanationClientFactoryProvider.overrideWithValue(
            (apiKey) => client,
          ),
        ],
      );
      addTearDown(container.dispose);

      final session = container.read(_testSessionProvider);
      await session
          .explainSentence(sentence, contextSentences: context)
          .drain<void>();

      final expectedCacheId = contentDerivedExplanationId(
        sentenceText: 'main line',
        contextText: 'before\nafter',
      );
      expect(explanationRepo.store[expectedCacheId], 'explanation');
    });

    test('throws StateError when no API key is configured', () async {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(AppSettings.defaults),
          ),
        ],
      );
      addTearDown(container.dispose);

      final session = container.read(_testSessionProvider);
      await expectLater(
        session
            .explainSentence(_sentence('s1', 'x'), contextSentences: const [])
            .drain<void>(),
        throwsStateError,
      );
    });
  });
}
