import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/services.dart';
import 'package:japanese_immersion_reader/app/settings_repository.dart';
import 'package:japanese_immersion_reader/app/settings_screen.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_repository.dart';

AppDatabase? _sharedInertDatabase;
AppDatabase _inertDatabase() => _sharedInertDatabase ??= AppDatabase();

class FakeDictionaryRepository extends DictionaryRepository {
  FakeDictionaryRepository() : super(_inertDatabase());

  @override
  Future<List<Dictionary>> listInstalled() async => const [];
}

class FakeSettingsRepository extends SettingsRepository {
  FakeSettingsRepository([AppSettings? settings])
    : _settings = settings ?? AppSettings.defaults,
      super(_inertDatabase());

  AppSettings _settings;
  final List<Color> highlightColorUpdates = [];

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
  }) async {
    if (highlightColor != null) highlightColorUpdates.add(highlightColor);
    _settings = AppSettings(
      llmApiKey: llmApiKey ?? _settings.llmApiKey,
      llmExplanationsEnabled:
          llmExplanationsEnabled ?? _settings.llmExplanationsEnabled,
      ttsEnabled: ttsEnabled ?? _settings.ttsEnabled,
      pitchAccentAudioEnabled:
          pitchAccentAudioEnabled ?? _settings.pitchAccentAudioEnabled,
      highlightColor: highlightColor ?? _settings.highlightColor,
      autoAddToCollection:
          autoAddToCollection ?? _settings.autoAddToCollection,
    );
  }
}

Future<FakeSettingsRepository> _pumpSettingsScreen(
  WidgetTester tester, {
  AppSettings? settings,
}) async {
  final fakeSettings = FakeSettingsRepository(settings);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(fakeSettings),
        dictionaryRepositoryProvider.overrideWithValue(
          FakeDictionaryRepository(),
        ),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return fakeSettings;
}

void main() {
  testWidgets('shows a swatch matching the current highlight color', (
    tester,
  ) async {
    const customColor = Color(0xFF112233);
    await _pumpSettingsScreen(
      tester,
      settings: const AppSettings(
        llmApiKey: null,
        llmExplanationsEnabled: true,
        ttsEnabled: false,
        pitchAccentAudioEnabled: false,
        highlightColor: customColor,
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Highlight color'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    final swatch = tester.widget<Container>(
      find
          .descendant(
            of: find.widgetWithText(ListTile, 'Highlight color'),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = swatch.decoration! as BoxDecoration;
    expect(decoration.color, customColor);
  });

  testWidgets(
    'opens the color picker dialog and commits the picked color on Save',
    (tester) async {
      final fakeSettings = await _pumpSettingsScreen(tester);

      await tester.scrollUntilVisible(
        find.text('Change...'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Change...'));
      await tester.pumpAndSettle();

      expect(find.text('Highlight color'), findsWidgets);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(fakeSettings.highlightColorUpdates, hasLength(1));
    },
  );

  testWidgets('Cancel does not commit any color update', (tester) async {
    final fakeSettings = await _pumpSettingsScreen(tester);

    await tester.scrollUntilVisible(
      find.text('Change...'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Change...'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(fakeSettings.highlightColorUpdates, isEmpty);
  });

  testWidgets('toggling auto-add to collection updates settings', (
    tester,
  ) async {
    final fakeSettings = await _pumpSettingsScreen(tester);
    expect((await fakeSettings.read()).autoAddToCollection, isFalse);

    await tester.scrollUntilVisible(
      find.text('Auto-add to collection'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Auto-add to collection'));
    await tester.pumpAndSettle();

    expect((await fakeSettings.read()).autoAddToCollection, isTrue);
  });
}
