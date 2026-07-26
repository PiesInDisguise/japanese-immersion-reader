import 'package:flutter/material.dart';

import 'settings_repository.dart';

/// The app's default look, unchanged from before appearance customization
/// existed -- used whenever [AppSettings.useCustomTheme] is off, which is
/// the default for every install.
final defaultAppTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
);

/// Builds the app's actual [ThemeData] from [settings] -- [defaultAppTheme]
/// unchanged when [AppSettings.useCustomTheme] is off, otherwise a theme
/// derived from the four user-picked color slots (background/text/card/
/// accent). Deliberately a plain function (not a widget/provider) so it's
/// trivial to unit-test without pumping a widget tree.
ThemeData buildAppTheme(AppSettings settings) {
  if (!settings.useCustomTheme) return defaultAppTheme;

  final brightness = ThemeData.estimateBrightnessForColor(
    settings.themeBackgroundColor,
  );
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: settings.themeAccentColor,
        brightness: brightness,
      ).copyWith(
        primary: settings.themeAccentColor,
        surface: settings.themeCardColor,
        onSurface: settings.themeTextColor,
      );
  final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: settings.themeBackgroundColor,
    cardColor: settings.themeCardColor,
    cardTheme: base.cardTheme.copyWith(color: settings.themeCardColor),
    textTheme: base.textTheme.apply(
      bodyColor: settings.themeTextColor,
      displayColor: settings.themeTextColor,
    ),
  );
}

/// One named, ready-made set of the four custom-theme color slots -- picking
/// one applies all four at once (and turns [AppSettings.useCustomTheme] on),
/// rather than the user needing to hand-pick every slot individually.
class ThemePreset {
  const ThemePreset({
    required this.name,
    required this.background,
    required this.text,
    required this.card,
    required this.accent,
  });

  final String name;
  final Color background;
  final Color text;
  final Color card;
  final Color accent;
}

/// A handful of curated, coherent palettes (real, checked color
/// combinations -- Nord/Solarized's own published palettes for those two,
/// the rest hand-picked for background/text contrast and a card tone that
/// reads as distinct from the background without clashing) spanning light,
/// dark, warm, cool, and pastel -- not exhaustive, just enough variety to
/// start from instead of an empty color wheel.
const themePresets = [
  ThemePreset(
    name: 'Classic Light',
    background: Color(0xFFFFFFFF),
    text: Color(0xFF1A1C1B),
    card: Color(0xFFF3F3F3),
    accent: Color(0xFF009688),
  ),
  ThemePreset(
    name: 'Midnight Dark',
    background: Color(0xFF121212),
    text: Color(0xFFE0E0E0),
    card: Color(0xFF1E1E1E),
    accent: Color(0xFFBB86FC),
  ),
  ThemePreset(
    name: 'Sepia Reading',
    background: Color(0xFFF4ECD8),
    text: Color(0xFF5B4636),
    card: Color(0xFFEAE0C8),
    accent: Color(0xFFA0522D),
  ),
  ThemePreset(
    name: 'Nord',
    background: Color(0xFF2E3440),
    text: Color(0xFFECEFF4),
    card: Color(0xFF3B4252),
    accent: Color(0xFF88C0D0),
  ),
  ThemePreset(
    name: 'Solarized Light',
    background: Color(0xFFFDF6E3),
    text: Color(0xFF657B83),
    card: Color(0xFFEEE8D5),
    accent: Color(0xFF268BD2),
  ),
  ThemePreset(
    name: 'Solarized Dark',
    background: Color(0xFF002B36),
    text: Color(0xFF839496),
    card: Color(0xFF073642),
    accent: Color(0xFF2AA198),
  ),
  ThemePreset(
    name: 'Rose Pastel',
    background: Color(0xFFFFF5F7),
    text: Color(0xFF4A3B3F),
    card: Color(0xFFFDE8ED),
    accent: Color(0xFFE07A9E),
  ),
  ThemePreset(
    name: 'Forest',
    background: Color(0xFFF1F5F0),
    text: Color(0xFF2E3D2F),
    card: Color(0xFFE0EBDD),
    accent: Color(0xFF4C7A44),
  ),
];
