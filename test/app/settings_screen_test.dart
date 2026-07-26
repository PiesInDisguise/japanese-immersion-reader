import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/app_theme.dart';
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
  final List<Color> themeBackgroundColorUpdates = [];
  final _controller = StreamController<AppSettings>.broadcast();

  @override
  Future<AppSettings> read() async => _settings;

  /// Reactive, unlike a plain `Stream.value(_settings)` -- this suite's own
  /// tests (e.g. toggling "Use custom theme colors" and asserting the four
  /// color rows then appear) need `SettingsScreen`'s
  /// `ref.watch(appSettingsProvider)` to actually rebuild after [update]
  /// mutates [_settings] while the widget is already mounted, which a
  /// one-shot stream can never do (it emits once, at subscribe time, and
  /// never again).
  @override
  Stream<AppSettings> watch() async* {
    yield _settings;
    yield* _controller.stream;
  }

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
    double? fontScale,
    bool? useCustomTheme,
    Color? themeBackgroundColor,
    Color? themeTextColor,
    Color? themeCardColor,
    Color? themeAccentColor,
  }) async {
    if (highlightColor != null) highlightColorUpdates.add(highlightColor);
    if (themeBackgroundColor != null) {
      themeBackgroundColorUpdates.add(themeBackgroundColor);
    }
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
      fontScale: fontScale ?? _settings.fontScale,
      useCustomTheme: useCustomTheme ?? _settings.useCustomTheme,
      themeBackgroundColor:
          themeBackgroundColor ?? _settings.themeBackgroundColor,
      themeTextColor: themeTextColor ?? _settings.themeTextColor,
      themeCardColor: themeCardColor ?? _settings.themeCardColor,
      themeAccentColor: themeAccentColor ?? _settings.themeAccentColor,
    );
    _controller.add(_settings);
  }
}

/// Tall enough that this screen's whole `ListView` fits in one screen with
/// no scrolling needed at all, sidestepping an entire class of test
/// flakiness: a plain `ListView` only lazily builds items near the current
/// viewport (true of every `ListView`, not just `.builder` -- the Sliver
/// protocol itself is lazy regardless of which delegate supplies the
/// children), so anything that scrolls content into/out of existence (a
/// toggle that reveals more rows, in this screen's case) needs the target
/// to already be built to find it at all -- simplest fix is to just make
/// sure nothing is ever off-screen to begin with.
Future<FakeSettingsRepository> _pumpSettingsScreen(
  WidgetTester tester, {
  AppSettings? settings,
}) async {
  final originalSize = tester.view.physicalSize;
  final originalRatio = tester.view.devicePixelRatio;
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.physicalSize = originalSize;
    tester.view.devicePixelRatio = originalRatio;
  });

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

    await tester.tap(find.text('Auto-add to collection'));
    await tester.pumpAndSettle();

    expect((await fakeSettings.read()).autoAddToCollection, isTrue);
  });

  testWidgets('moving the font size slider updates settings', (tester) async {
    final fakeSettings = await _pumpSettingsScreen(tester);
    expect((await fakeSettings.read()).fontScale, 1.0);

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(1.5);
    await tester.pump();

    expect((await fakeSettings.read()).fontScale, 1.5);
  });

  testWidgets(
    'the four custom-theme color pickers are hidden until the toggle is on',
    (tester) async {
      await _pumpSettingsScreen(tester);

      expect(find.text('Background'), findsNothing);
      expect(find.text('Text'), findsNothing);
      expect(find.text('Card'), findsNothing);
      expect(find.text('Accent'), findsNothing);

      await tester.tap(find.text('Use custom theme colors'));
      await tester.pumpAndSettle();

      expect(find.text('Background'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
      expect(find.text('Accent'), findsOneWidget);
    },
  );

  testWidgets('picking a custom-theme color commits it via update()', (
    tester,
  ) async {
    final fakeSettings = await _pumpSettingsScreen(
      tester,
      settings: const AppSettings(
        llmApiKey: null,
        llmExplanationsEnabled: true,
        ttsEnabled: false,
        pitchAccentAudioEnabled: false,
        useCustomTheme: true,
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Background'),
        matching: find.text('Change...'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Background color'), findsWidgets);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Proves the "Background" tile is wired to `themeBackgroundColor`
    // specifically (not, say, `highlightColor` or another color field) --
    // not what particular color got picked, since the test never
    // interacts with the picker's own wheel/sliders.
    expect(fakeSettings.themeBackgroundColorUpdates, hasLength(1));
    expect(fakeSettings.highlightColorUpdates, isEmpty);
  });

  testWidgets(
    'tapping a palette preset applies all four of its colors and turns on '
    'the custom theme, in one shot',
    (tester) async {
      final fakeSettings = await _pumpSettingsScreen(tester);
      expect((await fakeSettings.read()).useCustomTheme, isFalse);

      final preset = themePresets.first;
      await tester.tap(find.text(preset.name));
      await tester.pumpAndSettle();

      final updated = await fakeSettings.read();
      expect(updated.useCustomTheme, isTrue);
      expect(updated.themeBackgroundColor, preset.background);
      expect(updated.themeTextColor, preset.text);
      expect(updated.themeCardColor, preset.card);
      expect(updated.themeAccentColor, preset.accent);
    },
  );
}
