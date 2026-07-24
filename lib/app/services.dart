import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_repository.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_database.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_matcher.dart';
import 'package:japanese_immersion_reader/l2_linguistics/llm/grammar_explanation_client.dart';
import 'package:japanese_immersion_reader/l2_linguistics/tokenizer/native_library_loader.dart';
import 'package:japanese_immersion_reader/l2_linguistics/tokenizer/sudachi_tokenizer.dart';
import 'package:japanese_immersion_reader/l2_linguistics/tokenizer/tokenizer.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/grammar_collection_repository.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/word_collection_repository.dart';

import 'dictionary_paths.dart';
import 'explanation_repository.dart';
import 'settings_repository.dart';

/// One shared [AppDatabase] for the app's lifetime. Riverpod keeps this
/// alive for as long as anything is watching it (every other provider below
/// depends on it, directly or transitively, so in practice that's the whole
/// app session).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Async because loading the Sudachi dictionary takes real time (dictionary
/// parsing, not just a file read) -- UI that needs tokenization should watch
/// this and show a loading state until it resolves, per
/// `SudachiTokenizer.create`'s own doc comment.
///
/// Path resolution here is intentionally minimal (see `dictionary_paths.dart`
/// for what's actually a placeholder vs. real): a shipped app needs to
/// bundle or download this dictionary, which is explicitly out of scope for
/// this pass (see docs/research/r4-tokenizer.md §3/§6) -- this provider just
/// wires whatever path that future resolution produces into the tokenizer.
final tokenizerProvider = FutureProvider<Tokenizer>((ref) async {
  // Must happen before any SudachiTokenizer is constructed -- flutter_rust_bridge
  // throws "Bad state: flutter_rust_bridge has not been initialized" from
  // every generated call otherwise. See native_library_loader.dart.
  await ensureSudachiNativeLibraryInitialized();
  final paths = await resolveSudachiDictionaryPaths();
  return SudachiTokenizer.create(
    resourceDir: paths.resourceDir,
    dictionaryPath: paths.dictionaryPath,
  );
});

final dictionaryRepositoryProvider = Provider<DictionaryRepository>((ref) {
  return DictionaryRepository(ref.watch(appDatabaseProvider));
});

final wordCollectionRepositoryProvider = Provider<WordCollectionRepository>((
  ref,
) {
  return WordCollectionRepository(ref.watch(appDatabaseProvider));
});

final grammarCollectionRepositoryProvider =
    Provider<GrammarCollectionRepository>((ref) {
      return GrammarCollectionRepository(ref.watch(appDatabaseProvider));
    });

/// Spec §8 layer 2's grammar-point database, loaded once from the bundled
/// asset (`assets/grammar/grammar_points.json`) and compiled into a ready
/// [GrammarMatcher] -- async (`FutureProvider`, matching [tokenizerProvider]'s
/// own shape) since asset loading is genuinely async, even though this
/// particular asset is small enough to resolve near-instantly.
final grammarDatabaseProvider = FutureProvider<GrammarMatcher>((ref) async {
  final points = await loadGrammarPoints();
  return GrammarMatcher(points);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
});

final explanationRepositoryProvider = Provider<ExplanationRepository>((ref) {
  return ExplanationRepository(ref.watch(appDatabaseProvider));
});

/// Spec §8 layer 3's live settings row, watchable so UI (the on/off toggle,
/// whether the explanation section even attempts a call) updates the moment
/// the settings screen changes it, without needing a manual refresh.
final appSettingsProvider = StreamProvider<AppSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).watch();
});

/// Builds a real [GrammarExplanationClient] from a live API key. Kept as a
/// factory seam (not a single shared instance) rather than
/// `ReaderMiningSession` constructing `AnthropicGrammarExplanationClient`
/// directly, for the same reason `l1_ingestion/pdf_scanned` takes an
/// `OcrEngineFactory` rather than a concrete engine: tests override this
/// with a fake-emitting factory so nothing in the test suite ever makes a
/// real network call, and a fresh client is built per explanation (the key
/// can change if the user edits Settings mid-session).
final grammarExplanationClientFactoryProvider =
    Provider<GrammarExplanationClient Function(String apiKey)>((ref) {
      return (apiKey) => AnthropicGrammarExplanationClient(apiKey: apiKey);
    });
