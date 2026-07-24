import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/services.dart';
import '../app/stats/reading_activity_repository.dart';

/// Spec §15's "time read"/streak/heatmap data collection: accumulates
/// elapsed wall-clock time via a [Stopwatch] for as long as a reading-mode
/// controller (`CardModeController`/`DocumentModeController`) is alive, and
/// periodically (plus on dispose) flushes it to
/// `ReadingActivityRepository.addSeconds`.
///
/// **Deliberately time-since-controller-alive, not time-since-last-
/// interaction**: both reading modes' controllers are only alive while
/// their screen is actually being watched (spec §5/§6/§7's reading flow),
/// so "the controller exists" is already a reasonable proxy for "the
/// reader has this book open" without needing separate app-lifecycle
/// (foreground/background) plumbing this pass. A future pass could
/// pause/resume around `AppLifecycleState` changes for more precision.
class ReadingTimeTracker {
  /// Reads [ReadingActivityRepository] once, upfront -- Riverpod forbids
  /// calling `Ref.read` from inside an `onDispose` callback ("Cannot use
  /// Ref or modify other providers inside life-cycles/selectors"), so the
  /// repository this needs at flush time (including the dispose-time
  /// flush) must already be in hand before that callback ever runs.
  ReadingTimeTracker(Ref ref)
    : _repository = ref.read(readingActivityRepositoryProvider) {
    _stopwatch.start();
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flush());
    ref.onDispose(() {
      _flushTimer.cancel();
      _flush();
    });
  }

  /// Frequent enough that a reading session ended by a crash or force-quit
  /// (which skips the dispose-time flush) only ever loses a small, bounded
  /// amount of time, without writing to the database on every frame.
  static const _flushInterval = Duration(seconds: 20);

  final ReadingActivityRepository _repository;
  final Stopwatch _stopwatch = Stopwatch();
  late final Timer _flushTimer;

  void _flush() {
    final elapsedSeconds = _stopwatch.elapsed.inSeconds;
    if (elapsedSeconds <= 0) return;
    // Sub-second remainder (up to ~1s per flush) is simply dropped rather
    // than carried over -- immaterial for a streak/heatmap/total-time
    // feature, and not worth the extra bookkeeping.
    _stopwatch
      ..stop()
      ..reset()
      ..start();
    unawaited(_repository.addSeconds(elapsedSeconds));
  }
}
