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
