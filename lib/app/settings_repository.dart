import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';

/// Default document-wide mined-word highlight color: yellow at ~40% alpha,
/// used both as `AppSettings.defaults`' value and whenever a stored row has
/// no customized value yet.
const defaultHighlightColor = Color(0x66FFEE58);

/// Defaults for the custom-theme color slots (`AppSettings.useCustomTheme`)
/// -- a plain light theme, deliberately unrelated to the app's actual
/// default `ColorScheme.fromSeed(seedColor: Colors.teal)` look
/// (`main.dart`): these are never seen until a user turns the toggle on and
/// starts from them, not what a fresh install looks like.
const defaultThemeBackgroundColor = Color(0xFFFFFFFF);
const defaultThemeTextColor = Color(0xFF1A1C1B);
const defaultThemeCardColor = Color(0xFFF3F3F3);
const defaultThemeAccentColor = Color(0xFF009688);

/// The single row of user-configurable settings this app has real UI for so
/// far -- spec §14's LLM section (API key, grammar-explanation on/off), spec
/// §9's audio section (TTS/pitch-accent-audio on/off), and the mined-word
/// highlight color. See `core/db/tables.dart`'s `Settings` table doc comment
/// for why this is a fixed-shape single row rather than a generic key-value
/// store.
class AppSettings {
  const AppSettings({
    required this.llmApiKey,
    required this.llmExplanationsEnabled,
    required this.ttsEnabled,
    required this.pitchAccentAudioEnabled,
    this.highlightColor = defaultHighlightColor,
    this.autoAddToCollection = false,
    this.reviewShowSentenceOnFront = false,
    this.reviewSwipeUpEnabled = true,
    this.reviewSwipeDownEnabled = true,
    this.reviewSwipeLeftEnabled = true,
    this.reviewSwipeRightEnabled = true,
    this.fontScale = 1.0,
    this.useCustomTheme = false,
    this.themeBackgroundColor = defaultThemeBackgroundColor,
    this.themeTextColor = defaultThemeTextColor,
    this.themeCardColor = defaultThemeCardColor,
    this.themeAccentColor = defaultThemeAccentColor,
  });

  static const defaults = AppSettings(
    llmApiKey: null,
    llmExplanationsEnabled: true,
    ttsEnabled: false,
    pitchAccentAudioEnabled: false,
    highlightColor: defaultHighlightColor,
    autoAddToCollection: false,
    reviewShowSentenceOnFront: false,
    reviewSwipeUpEnabled: true,
    reviewSwipeDownEnabled: true,
    reviewSwipeLeftEnabled: true,
    reviewSwipeRightEnabled: true,
    fontScale: 1.0,
    useCustomTheme: false,
    themeBackgroundColor: defaultThemeBackgroundColor,
    themeTextColor: defaultThemeTextColor,
    themeCardColor: defaultThemeCardColor,
    themeAccentColor: defaultThemeAccentColor,
  );

  final String? llmApiKey;
  final bool llmExplanationsEnabled;
  final bool ttsEnabled;
  final bool pitchAccentAudioEnabled;
  final Color highlightColor;

  /// Spec §6/§14: "Mining — auto-add on/off." See `WordLookupSheet.autoMine`
  /// for what this actually changes at the UI level.
  final bool autoAddToCollection;

  /// Spec §12 review screen: show a word card's original source sentence
  /// (with the word itself highlighted) as its front, instead of the bare
  /// word. See `core/db/tables.dart`'s `Settings.reviewShowSentenceOnFront`
  /// for the full reasoning.
  final bool reviewShowSentenceOnFront;

  /// Review-screen swipe-to-rate, one flag per direction -- see
  /// `core/db/tables.dart`'s matching columns for why these are separate
  /// per-direction toggles rather than one on/off switch.
  final bool reviewSwipeUpEnabled;
  final bool reviewSwipeDownEnabled;
  final bool reviewSwipeLeftEnabled;
  final bool reviewSwipeRightEnabled;

  /// App-wide text-size multiplier -- see
  /// `core/db/tables.dart`'s `Settings.fontScale` doc comment.
  final double fontScale;

  /// See `core/db/tables.dart`'s `Settings.useCustomTheme` doc comment for
  /// why this gate exists separately from the four color fields below
  /// always holding a real value.
  final bool useCustomTheme;
  final Color themeBackgroundColor;
  final Color themeTextColor;
  final Color themeCardColor;
  final Color themeAccentColor;

  /// Whether spec §8 layer 3 should actually attempt a real network call --
  /// both the toggle *and* a configured API key are required, not just the
  /// toggle (there is nothing to call without a key regardless of the
  /// toggle's own state).
  bool get llmExplanationsActive =>
      llmExplanationsEnabled && (llmApiKey?.isNotEmpty ?? false);
}

/// Reads/writes the single [Settings] row. Every write reads-merges-writes
/// the full row (rather than a partial SQL upsert) so callers can update
/// just one field at a time without needing to know or preserve the other
/// field's current value themselves.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const _rowId = 0;

  Future<AppSettings> read() async {
    final row = await (_db.select(
      _db.settings,
    )..where((s) => s.id.equals(_rowId))).getSingleOrNull();
    if (row == null) return AppSettings.defaults;
    return _fromRow(row);
  }

  /// Live-updating settings, for UI that needs to react the moment the
  /// settings screen changes the API key or toggle (see `appSettingsProvider`
  /// in `app/services.dart`) without a manual refresh.
  Stream<AppSettings> watch() {
    return (_db.select(
      _db.settings,
    )..where((s) => s.id.equals(_rowId))).watchSingleOrNull().map((row) {
      if (row == null) return AppSettings.defaults;
      return _fromRow(row);
    });
  }

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
    final current = await read();
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(
            id: const Value(_rowId),
            llmApiKey: Value(llmApiKey ?? current.llmApiKey),
            llmExplanationsEnabled: Value(
              llmExplanationsEnabled ?? current.llmExplanationsEnabled,
            ),
            ttsEnabled: Value(ttsEnabled ?? current.ttsEnabled),
            pitchAccentAudioEnabled: Value(
              pitchAccentAudioEnabled ?? current.pitchAccentAudioEnabled,
            ),
            highlightColorValue: Value(
              (highlightColor ?? current.highlightColor).toARGB32(),
            ),
            autoAddToCollection: Value(
              autoAddToCollection ?? current.autoAddToCollection,
            ),
            reviewShowSentenceOnFront: Value(
              reviewShowSentenceOnFront ?? current.reviewShowSentenceOnFront,
            ),
            reviewSwipeUpEnabled: Value(
              reviewSwipeUpEnabled ?? current.reviewSwipeUpEnabled,
            ),
            reviewSwipeDownEnabled: Value(
              reviewSwipeDownEnabled ?? current.reviewSwipeDownEnabled,
            ),
            reviewSwipeLeftEnabled: Value(
              reviewSwipeLeftEnabled ?? current.reviewSwipeLeftEnabled,
            ),
            reviewSwipeRightEnabled: Value(
              reviewSwipeRightEnabled ?? current.reviewSwipeRightEnabled,
            ),
            fontScale: Value(fontScale ?? current.fontScale),
            useCustomTheme: Value(useCustomTheme ?? current.useCustomTheme),
            themeBackgroundColorValue: Value(
              (themeBackgroundColor ?? current.themeBackgroundColor).toARGB32(),
            ),
            themeTextColorValue: Value(
              (themeTextColor ?? current.themeTextColor).toARGB32(),
            ),
            themeCardColorValue: Value(
              (themeCardColor ?? current.themeCardColor).toARGB32(),
            ),
            themeAccentColorValue: Value(
              (themeAccentColor ?? current.themeAccentColor).toARGB32(),
            ),
            // Spec §13 sync-readiness -- see tables.dart's own audit note.
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  AppSettings _fromRow(SettingsRow row) => AppSettings(
    llmApiKey: row.llmApiKey,
    llmExplanationsEnabled: row.llmExplanationsEnabled,
    ttsEnabled: row.ttsEnabled,
    pitchAccentAudioEnabled: row.pitchAccentAudioEnabled,
    highlightColor: row.highlightColorValue == null
        ? defaultHighlightColor
        : Color(row.highlightColorValue!),
    autoAddToCollection: row.autoAddToCollection,
    reviewShowSentenceOnFront: row.reviewShowSentenceOnFront,
    reviewSwipeUpEnabled: row.reviewSwipeUpEnabled,
    reviewSwipeDownEnabled: row.reviewSwipeDownEnabled,
    reviewSwipeLeftEnabled: row.reviewSwipeLeftEnabled,
    reviewSwipeRightEnabled: row.reviewSwipeRightEnabled,
    fontScale: row.fontScale,
    useCustomTheme: row.useCustomTheme,
    themeBackgroundColor: row.themeBackgroundColorValue == null
        ? defaultThemeBackgroundColor
        : Color(row.themeBackgroundColorValue!),
    themeTextColor: row.themeTextColorValue == null
        ? defaultThemeTextColor
        : Color(row.themeTextColorValue!),
    themeCardColor: row.themeCardColorValue == null
        ? defaultThemeCardColor
        : Color(row.themeCardColorValue!),
    themeAccentColor: row.themeAccentColorValue == null
        ? defaultThemeAccentColor
        : Color(row.themeAccentColorValue!),
  );
}
