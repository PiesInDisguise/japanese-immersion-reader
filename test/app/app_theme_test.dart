import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/app_theme.dart';
import 'package:japanese_immersion_reader/app/settings_repository.dart';

void main() {
  test('returns the unchanged default theme when useCustomTheme is off', () {
    final theme = buildAppTheme(AppSettings.defaults);
    expect(theme, same(defaultAppTheme));
  });

  test(
    'builds a theme from the four color slots when useCustomTheme is on',
    () {
      const background = Color(0xFF112233);
      const text = Color(0xFFAABBCC);
      const card = Color(0xFF445566);
      const accent = Color(0xFFEE0033);
      const settings = AppSettings(
        llmApiKey: null,
        llmExplanationsEnabled: true,
        ttsEnabled: false,
        pitchAccentAudioEnabled: false,
        useCustomTheme: true,
        themeBackgroundColor: background,
        themeTextColor: text,
        themeCardColor: card,
        themeAccentColor: accent,
      );

      final theme = buildAppTheme(settings);

      expect(theme.scaffoldBackgroundColor, background);
      expect(theme.colorScheme.surface, card);
      expect(theme.colorScheme.onSurface, text);
      expect(theme.colorScheme.primary, accent);
      expect(theme.textTheme.bodyMedium?.color, text);
    },
  );

  test('picks a dark-appropriate scheme for a dark background, light for a '
      'light one', () {
    final darkTheme = buildAppTheme(
      const AppSettings(
        llmApiKey: null,
        llmExplanationsEnabled: true,
        ttsEnabled: false,
        pitchAccentAudioEnabled: false,
        useCustomTheme: true,
        themeBackgroundColor: Color(0xFF000000),
        themeTextColor: Color(0xFFFFFFFF),
      ),
    );
    final lightTheme = buildAppTheme(
      const AppSettings(
        llmApiKey: null,
        llmExplanationsEnabled: true,
        ttsEnabled: false,
        pitchAccentAudioEnabled: false,
        useCustomTheme: true,
        themeBackgroundColor: Color(0xFFFFFFFF),
        themeTextColor: Color(0xFF000000),
      ),
    );

    expect(darkTheme.colorScheme.brightness, Brightness.dark);
    expect(lightTheme.colorScheme.brightness, Brightness.light);
  });
}
