import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/card_mode_controller.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/reader_mining_session.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/word_collection_repository.dart';

import '../services.dart';
import 'comprehension_calculator.dart';

/// Spec §15's progress/stats snapshot, computed fresh each time
/// [statsControllerProvider] is watched -- this screen isn't meant to be
/// long-lived/continuously updating, so a plain one-shot [AsyncNotifier]
/// (re-run via `ref.invalidate` if the user wants a refresh) is enough.
class StatsState {
  const StatsState({
    required this.wordsMinedCount,
    required this.grammarPointsMinedCount,
    required this.currentStreakDays,
    required this.totalSecondsRead,
    required this.heatmap,
    required this.comprehensionPercent,
  });

  final int wordsMinedCount;
  final int grammarPointsMinedCount;
  final int currentStreakDays;
  final int totalSecondsRead;

  /// The last [StatsController.heatmapDays] UTC calendar days' reading
  /// time, keyed by that day's UTC midnight -- days with no activity are
  /// simply absent (see `ReadingActivityRepository.activityByDay`).
  final Map<DateTime, int> heatmap;

  /// Spec §15: "comprehension % per page" for whatever document is
  /// currently open (its first chapter, sampled -- see
  /// [StatsController.comprehensionSampleSize]'s own doc comment). `null`
  /// if no document is open, or it has no chapters/sentences to sample.
  final double? comprehensionPercent;
}

final statsControllerProvider =
    AsyncNotifierProvider<StatsController, StatsState>(StatsController.new);

class StatsController extends AsyncNotifier<StatsState> {
  /// ~12 weeks -- enough for a real heatmap without pulling and rendering a
  /// full year's worth of cells for a stats screen this simple.
  static const heatmapDays = 84;

  /// Spec §15's "per page" framing means this is a snapshot of the
  /// *current* reading position, not a whole-book aggregate -- sampling
  /// the first chapter's first 80 sentences (rather than tokenizing an
  /// entire novel synchronously every time this screen opens) is a
  /// reasonable stand-in for "the page(s) around where the reader is."
  static const comprehensionSampleSize = 80;

  @override
  Future<StatsState> build() async {
    final wordRepository = ref.watch(wordCollectionRepositoryProvider);
    final grammarRepository = ref.watch(grammarCollectionRepositoryProvider);
    final activityRepository = ref.watch(readingActivityRepositoryProvider);

    final wordsMinedCount = await wordRepository.count();
    final grammarPointsMinedCount = await grammarRepository.count();
    final currentStreakDays = await activityRepository.currentStreakDays();
    final totalSecondsRead = await activityRepository.totalSecondsRead();
    final heatmap = await activityRepository.activityByDay(
      days: heatmapDays,
    );

    return StatsState(
      wordsMinedCount: wordsMinedCount,
      grammarPointsMinedCount: grammarPointsMinedCount,
      currentStreakDays: currentStreakDays,
      totalSecondsRead: totalSecondsRead,
      heatmap: heatmap,
      comprehensionPercent: await _comprehensionForCurrentDocument(
        wordRepository,
      ),
    );
  }

  Future<double?> _comprehensionForCurrentDocument(
    WordCollectionRepository wordRepository,
  ) async {
    final document = ref.watch(currentDocumentProvider);
    if (document == null || document.chapters.isEmpty) return null;

    final sentences = document.chapters.first.blocks
        .expand((block) => block.sentences)
        .take(comprehensionSampleSize)
        .toList();
    if (sentences.isEmpty) return null;

    final session = ReaderMiningSession(ref);
    final tokenizedSentences = <List<Token>>[];
    for (final sentence in sentences) {
      tokenizedSentences.add(await session.tokenizeSentence(sentence));
    }

    final calculator = ComprehensionCalculator(
      ({required dictForm, required reading}) => wordRepository.isCollected(
        dictForm: dictForm,
        reading: reading,
      ),
    );
    return calculator.compute(tokenizedSentences);
  }
}
