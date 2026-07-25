// ProviderContainer-level tests, no widget tree, no real audio/network --
// same pattern as reader_mining_session_explain_test.dart.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/services.dart';
import 'package:japanese_immersion_reader/app/settings_repository.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/reader_mining_session.dart';
import 'package:japanese_immersion_reader/l6_audio/pitch_accent/pitch_accent_audio_provider.dart';
import 'package:japanese_immersion_reader/l6_audio/pitch_accent/pitch_accent_player.dart';
import 'package:japanese_immersion_reader/l6_audio/tts/tts_service.dart';

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
  }) async {
    _settings = AppSettings(
      llmApiKey: llmApiKey ?? _settings.llmApiKey,
      llmExplanationsEnabled:
          llmExplanationsEnabled ?? _settings.llmExplanationsEnabled,
      ttsEnabled: ttsEnabled ?? _settings.ttsEnabled,
      pitchAccentAudioEnabled:
          pitchAccentAudioEnabled ?? _settings.pitchAccentAudioEnabled,
      highlightColor: highlightColor ?? _settings.highlightColor,
    );
  }
}

class FakeTtsService implements TtsService {
  final List<String> spoken = [];
  bool available = true;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async {}
}

class FakePitchAccentAudioProvider implements PitchAccentAudioProvider {
  FakePitchAccentAudioProvider(this._byWord);

  final Map<String, Uint8List?> _byWord;

  @override
  Future<Uint8List?> fetchAudio({
    required String expression,
    required String reading,
  }) async => _byWord['$expression|$reading'];
}

final _testSessionProvider = Provider<ReaderMiningSession>(
  (ref) => ReaderMiningSession(ref),
);

ProviderContainer _buildContainer({
  required AppSettings settings,
  required FakeTtsService tts,
  required FakePitchAccentAudioProvider pitchAccentProvider,
  required List<String> playedPaths,
}) {
  return ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(
        FakeSettingsRepository(settings),
      ),
      ttsServiceProvider.overrideWithValue(tts),
      pitchAccentPlayerProvider.overrideWithValue(
        PitchAccentPlayer(
          pitchAccentProvider,
          playFile: (path) async => playedPaths.add(path),
          resolveCacheDir: () async =>
              Directory.systemTemp.createTemp('reader_mining_session_audio'),
        ),
      ),
    ],
  );
}

void main() {
  group('ReaderMiningSession TTS', () {
    test('ttsActive reflects the settings toggle', () async {
      final container = _buildContainer(
        settings: const AppSettings(
          llmApiKey: null,
          llmExplanationsEnabled: true,
          ttsEnabled: true,
          pitchAccentAudioEnabled: false,
        ),
        tts: FakeTtsService(),
        pitchAccentProvider: FakePitchAccentAudioProvider(const {}),
        playedPaths: [],
      );
      addTearDown(container.dispose);

      final session = container.read(_testSessionProvider);
      expect(await session.ttsActive(), isTrue);
    });

    test('speak calls through to the TtsService when active', () async {
      final tts = FakeTtsService();
      final container = _buildContainer(
        settings: const AppSettings(
          llmApiKey: null,
          llmExplanationsEnabled: true,
          ttsEnabled: true,
          pitchAccentAudioEnabled: false,
        ),
        tts: tts,
        pitchAccentProvider: FakePitchAccentAudioProvider(const {}),
        playedPaths: [],
      );
      addTearDown(container.dispose);

      final session = container.read(_testSessionProvider);
      await session.speak('こんにちは');

      expect(tts.spoken, ['こんにちは']);
    });

    test('speak throws when TTS is disabled', () async {
      final container = _buildContainer(
        settings: AppSettings.defaults,
        tts: FakeTtsService(),
        pitchAccentProvider: FakePitchAccentAudioProvider(const {}),
        playedPaths: [],
      );
      addTearDown(container.dispose);

      final session = container.read(_testSessionProvider);
      await expectLater(session.speak('x'), throwsStateError);
    });
  });

  group('ReaderMiningSession pitch-accent audio', () {
    test('playPitchAccentAudio plays and returns true when audio exists', () async {
      final playedPaths = <String>[];
      final container = _buildContainer(
        settings: const AppSettings(
          llmApiKey: null,
          llmExplanationsEnabled: true,
          ttsEnabled: false,
          pitchAccentAudioEnabled: true,
        ),
        tts: FakeTtsService(),
        pitchAccentProvider: FakePitchAccentAudioProvider({
          '猫|ねこ': Uint8List.fromList([1, 2, 3]),
        }),
        playedPaths: playedPaths,
      );
      addTearDown(container.dispose);

      final session = container.read(_testSessionProvider);
      final played = await session.playPitchAccentAudio(
        expression: '猫',
        reading: 'ねこ',
      );

      expect(played, isTrue);
      expect(playedPaths, hasLength(1));
    });

    test('playPitchAccentAudio returns false when no recording exists', () async {
      final container = _buildContainer(
        settings: const AppSettings(
          llmApiKey: null,
          llmExplanationsEnabled: true,
          ttsEnabled: false,
          pitchAccentAudioEnabled: true,
        ),
        tts: FakeTtsService(),
        pitchAccentProvider: FakePitchAccentAudioProvider(const {}),
        playedPaths: [],
      );
      addTearDown(container.dispose);

      final session = container.read(_testSessionProvider);
      final played = await session.playPitchAccentAudio(
        expression: '無い',
        reading: 'ない',
      );

      expect(played, isFalse);
    });

    test('playPitchAccentAudio throws when the toggle is off', () async {
      final container = _buildContainer(
        settings: AppSettings.defaults,
        tts: FakeTtsService(),
        pitchAccentProvider: FakePitchAccentAudioProvider(const {}),
        playedPaths: [],
      );
      addTearDown(container.dispose);

      final session = container.read(_testSessionProvider);
      await expectLater(
        session.playPitchAccentAudio(expression: 'x', reading: 'x'),
        throwsStateError,
      );
    });
  });
}
