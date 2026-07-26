import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Documents,
    Chapters,
    Sentences,
    // Dictionary import/lookup (spec §10) -- see
    // docs/research/r5-dictionary.md for the schema design.
    Dictionaries,
    DictionaryTagEntries,
    DictionaryTermEntries,
    DictionaryTermMetaEntries,
    // Collection layer (spec §11) -- see lib/l4_mining/collection/.
    CollectedWords,
    CollectedWordSources,
    CollectedGrammars,
    CollectedGrammarSources,
    // Settings + LLM explanation cache (spec §8 layer 3, spec §14) --
    // added in schemaVersion 2, see `migration` below.
    Settings,
    SentenceExplanations,
    // Reading stats (spec §15) -- added in schemaVersion 5, see `migration`
    // below.
    ReadingActivity,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Real dev/installed databases already exist at schemaVersion 1
      // without Settings/SentenceExplanations -- Drift's default onCreate
      // path never revisits an already-created database, so this is a real
      // migration, not just a formality.
      if (from < 2) {
        await m.createTable(settings);
        await m.createTable(sentenceExplanations);
      }
      // schemaVersion 3 (spec §12): the placeholder SM-2-shaped
      // srsInterval/srsEase columns are replaced by real FSRS memory state
      // (fsrsDifficulty/fsrsStability/lastReviewedAt) now that
      // `lib/l5_srs/fsrs/fsrs_scheduler.dart` exists to populate them.
      if (from < 3) {
        await m.addColumn(collectedWords, collectedWords.fsrsDifficulty);
        await m.addColumn(collectedWords, collectedWords.fsrsStability);
        await m.addColumn(collectedWords, collectedWords.lastReviewedAt);
        await m.dropColumn(collectedWords, 'srs_interval');
        await m.dropColumn(collectedWords, 'srs_ease');

        await m.addColumn(collectedGrammars, collectedGrammars.fsrsDifficulty);
        await m.addColumn(collectedGrammars, collectedGrammars.fsrsStability);
        await m.addColumn(collectedGrammars, collectedGrammars.lastReviewedAt);
        await m.dropColumn(collectedGrammars, 'srs_interval');
        await m.dropColumn(collectedGrammars, 'srs_ease');
      }
      // schemaVersion 4 (spec §9/§14): audio on/off toggles, both
      // off-by-default per spec §9's "optional, off by default".
      if (from < 4) {
        await m.addColumn(settings, settings.ttsEnabled);
        await m.addColumn(settings, settings.pitchAccentAudioEnabled);
      }
      // schemaVersion 5 (spec §15): reading stats.
      if (from < 5) {
        await m.createTable(readingActivity);
      }
      // schemaVersion 6 (spec §13 sync-readiness audit -- see tables.dart's
      // own top-of-file note for the full audit).
      if (from < 6) {
        await m.addColumn(settings, settings.updatedAt);
        await m.addColumn(collectedWordSources, collectedWordSources.uuid);
        await m.addColumn(
          collectedGrammarSources,
          collectedGrammarSources.uuid,
        );
      }
      // schemaVersion 7: customizable mined-word highlight color.
      if (from < 7) {
        await m.addColumn(settings, settings.highlightColorValue);
      }
      // schemaVersion 8: cover art + persisted reading position (Library
      // view).
      if (from < 8) {
        await m.addColumn(documents, documents.coverImagePath);
        await m.addColumn(documents, documents.lastSentenceId);
      }
      // schemaVersion 9 (spec §6/§14): auto-add-to-collection toggle.
      if (from < 9) {
        await m.addColumn(settings, settings.autoAddToCollection);
      }
      // schemaVersion 10 (spec §12): real Anki-style learning/relearning
      // steps -- FsrsCardState.step needs somewhere to persist between
      // reviews.
      if (from < 10) {
        await m.addColumn(collectedWords, collectedWords.srsStep);
        await m.addColumn(collectedGrammars, collectedGrammars.srsStep);
      }
      // schemaVersion 11 (spec §12): sentence-on-front review cards + review
      // swipe-to-rate gestures.
      if (from < 11) {
        await m.addColumn(settings, settings.reviewShowSentenceOnFront);
        await m.addColumn(settings, settings.reviewSwipeUpEnabled);
        await m.addColumn(settings, settings.reviewSwipeDownEnabled);
        await m.addColumn(settings, settings.reviewSwipeLeftEnabled);
        await m.addColumn(settings, settings.reviewSwipeRightEnabled);
      }
      // schemaVersion 12: app-wide font-size scaling + a custom
      // background/text/card/accent color theme.
      if (from < 12) {
        await m.addColumn(settings, settings.fontScale);
        await m.addColumn(settings, settings.useCustomTheme);
        await m.addColumn(settings, settings.themeBackgroundColorValue);
        await m.addColumn(settings, settings.themeTextColorValue);
        await m.addColumn(settings, settings.themeCardColorValue);
        await m.addColumn(settings, settings.themeAccentColorValue);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'japanese_immersion_reader.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
