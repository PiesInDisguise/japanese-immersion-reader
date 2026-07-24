import 'package:drift/native.dart';
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
