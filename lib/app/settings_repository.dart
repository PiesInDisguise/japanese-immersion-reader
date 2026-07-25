import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';

/// Default document-wide mined-word highlight color: yellow at ~40% alpha,
/// used both as `AppSettings.defaults`' value and whenever a stored row has
/// no customized value yet.
const defaultHighlightColor = Color(0x66FFEE58);

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
  });

  static const defaults = AppSettings(
    llmApiKey: null,
    llmExplanationsEnabled: true,
    ttsEnabled: false,
    pitchAccentAudioEnabled: false,
    highlightColor: defaultHighlightColor,
    autoAddToCollection: false,
  );

  final String? llmApiKey;
  final bool llmExplanationsEnabled;
  final bool ttsEnabled;
  final bool pitchAccentAudioEnabled;
  final Color highlightColor;

  /// Spec §6/§14: "Mining — auto-add on/off." See `WordLookupSheet.autoMine`
  /// for what this actually changes at the UI level.
  final bool autoAddToCollection;

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
  );
}
