import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/settings_repository.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = SettingsRepository(db);
  });

  tearDown(() => db.close());

  group('SettingsRepository', () {
    test('read() returns AppSettings.defaults when no row exists yet', () async {
      final settings = await repository.read();
      expect(settings.llmApiKey, isNull);
      expect(settings.llmExplanationsEnabled, isTrue);
      expect(settings.llmExplanationsActive, isFalse);
      expect(settings.ttsEnabled, isFalse);
      expect(settings.pitchAccentAudioEnabled, isFalse);
      expect(settings.highlightColor, defaultHighlightColor);
      expect(settings.autoAddToCollection, isFalse);
    });

    test('update() round-trips autoAddToCollection, leaving other fields '
        'alone', () async {
      await repository.update(ttsEnabled: true);

      await repository.update(autoAddToCollection: true);
      var settings = await repository.read();
      expect(settings.autoAddToCollection, isTrue);
      expect(settings.ttsEnabled, isTrue, reason: 'earlier field preserved');

      await repository.update(llmApiKey: 'sk-abc');
      settings = await repository.read();
      expect(
        settings.autoAddToCollection,
        isTrue,
        reason: 'untouched by an unrelated update',
      );

      await repository.update(autoAddToCollection: false);
      expect((await repository.read()).autoAddToCollection, isFalse);
    });

    test('update() round-trips highlightColor, leaving other fields alone', () async {
      await repository.update(ttsEnabled: true);

      const customColor = Color(0xFF3388CC);
      await repository.update(highlightColor: customColor);
      var settings = await repository.read();
      expect(settings.highlightColor, customColor);
      expect(settings.ttsEnabled, isTrue, reason: 'earlier field preserved');

      await repository.update(llmApiKey: 'sk-abc');
      settings = await repository.read();
      expect(
        settings.highlightColor,
        customColor,
        reason: 'untouched by an unrelated update',
      );
    });

    test('update() writes the audio toggles independently of the LLM ones', () async {
      await repository.update(ttsEnabled: true);
      var settings = await repository.read();
      expect(settings.ttsEnabled, isTrue);
      expect(settings.pitchAccentAudioEnabled, isFalse);
      expect(settings.llmExplanationsEnabled, isTrue, reason: 'untouched default');

      await repository.update(pitchAccentAudioEnabled: true);
      settings = await repository.read();
      expect(settings.ttsEnabled, isTrue, reason: 'earlier field preserved');
      expect(settings.pitchAccentAudioEnabled, isTrue);
    });

    test('update() writes just the given field, preserving the other', () async {
      await repository.update(llmApiKey: 'sk-abc');
      var settings = await repository.read();
      expect(settings.llmApiKey, 'sk-abc');
      expect(settings.llmExplanationsEnabled, isTrue);

      await repository.update(llmExplanationsEnabled: false);
      settings = await repository.read();
      expect(settings.llmApiKey, 'sk-abc', reason: 'earlier field preserved');
      expect(settings.llmExplanationsEnabled, isFalse);
    });

    test(
      'llmExplanationsActive requires both a non-empty key and the toggle',
      () async {
        await repository.update(llmApiKey: 'sk-abc', llmExplanationsEnabled: true);
        expect((await repository.read()).llmExplanationsActive, isTrue);

        await repository.update(llmExplanationsEnabled: false);
        expect((await repository.read()).llmExplanationsActive, isFalse);

        await repository.update(llmExplanationsEnabled: true, llmApiKey: '');
        expect((await repository.read()).llmExplanationsActive, isFalse);
      },
    );

    test('watch() emits a new value after update()', () async {
      final emissions = <AppSettings>[];
      final sub = repository.watch().listen(emissions.add);
      addTearDown(sub.cancel);

      await pumpEventQueue();
      await repository.update(llmApiKey: 'sk-live');
      await pumpEventQueue();

      expect(emissions.last.llmApiKey, 'sk-live');
    });
  });
}
