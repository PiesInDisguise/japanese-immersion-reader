import 'package:drift/drift.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';

/// The single row of user-configurable settings this app has real UI for so
/// far -- spec §14's LLM section only (API key, grammar-explanation
/// on/off). See `core/db/tables.dart`'s `Settings` table doc comment for why
/// this is a fixed-shape single row rather than a generic key-value store.
class AppSettings {
  const AppSettings({
    required this.llmApiKey,
    required this.llmExplanationsEnabled,
  });

  static const defaults = AppSettings(
    llmApiKey: null,
    llmExplanationsEnabled: true,
  );

  final String? llmApiKey;
  final bool llmExplanationsEnabled;

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
    return AppSettings(
      llmApiKey: row.llmApiKey,
      llmExplanationsEnabled: row.llmExplanationsEnabled,
    );
  }

  /// Live-updating settings, for UI that needs to react the moment the
  /// settings screen changes the API key or toggle (see `appSettingsProvider`
  /// in `app/services.dart`) without a manual refresh.
  Stream<AppSettings> watch() {
    return (_db.select(
      _db.settings,
    )..where((s) => s.id.equals(_rowId))).watchSingleOrNull().map((row) {
      if (row == null) return AppSettings.defaults;
      return AppSettings(
        llmApiKey: row.llmApiKey,
        llmExplanationsEnabled: row.llmExplanationsEnabled,
      );
    });
  }

  Future<void> update({
    String? llmApiKey,
    bool? llmExplanationsEnabled,
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
          ),
        );
  }
}
