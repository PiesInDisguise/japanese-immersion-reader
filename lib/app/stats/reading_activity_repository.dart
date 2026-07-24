import 'package:drift/drift.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';

/// Reads/writes spec §15's reading-activity data (streak, heatmap, total
/// time read) -- one [ReadingActivity] row per calendar day (UTC midnight)
/// that had any reading time, written to by
/// `lib/l3_reader_ui/reading_time_tracker.dart`.
class ReadingActivityRepository {
  ReadingActivityRepository(this._db);

  final AppDatabase _db;

  static DateTime _startOfDayUtc(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  /// Adds [seconds] of reading time to [now]'s (UTC) calendar day, creating
  /// that day's row if it doesn't exist yet.
  Future<void> addSeconds(int seconds, {DateTime? now}) async {
    if (seconds <= 0) return;
    final day = _startOfDayUtc(now ?? DateTime.now());

    final existing = await (_db.select(
      _db.readingActivity,
    )..where((r) => r.date.equals(day))).getSingleOrNull();

    await _db
        .into(_db.readingActivity)
        .insertOnConflictUpdate(
          ReadingActivityCompanion.insert(
            date: day,
            secondsRead: Value((existing?.secondsRead ?? 0) + seconds),
          ),
        );
  }

  /// Every day with recorded activity, in the inclusive range
  /// `[now - days + 1, now]` (UTC calendar days) -- days with no activity
  /// are simply absent, not zero-valued rows. Spec §15's heatmap /
  /// "time read" both read from this.
  Future<Map<DateTime, int>> activityByDay({
    required int days,
    DateTime? now,
  }) async {
    final today = _startOfDayUtc(now ?? DateTime.now());
    final start = today.subtract(Duration(days: days - 1));

    final rows =
        await (_db.select(_db.readingActivity)
              ..where((r) => r.date.isBiggerOrEqualValue(start)))
            .get();

    // Drift reads DateTimeColumn values back tagged as local time even
    // though the underlying instant is correct (the same quirk documented
    // in word_collection_repository_test.dart) -- `.toUtc()` recovers the
    // right UTC DateTime. Without this, every key here would fail to
    // `==`/hash-match the UTC keys `_startOfDayUtc` produces everywhere
    // else in this class, silently breaking every map lookup against this
    // result.
    return {for (final row in rows) row.date.toUtc(): row.secondsRead};
  }

  /// Spec §15's "reading streak": the number of consecutive UTC calendar
  /// days with any recorded activity, counting backward from [now] --
  /// today not having activity *yet* doesn't break the streak (the reader
  /// might still read later today), but today AND yesterday both missing
  /// does.
  Future<int> currentStreakDays({DateTime? now}) async {
    final today = _startOfDayUtc(now ?? DateTime.now());
    // A year is comfortably more than any real streak needs, and keeps
    // this a single bounded query rather than one row-existence check per
    // day going back indefinitely.
    final activity = await activityByDay(days: 366, now: today);

    var streak = 0;
    var day = today;
    if (!activity.containsKey(day)) {
      // Today has no activity yet -- start counting from yesterday instead,
      // so a streak in progress isn't reported as broken before the day is
      // even over.
      day = day.subtract(const Duration(days: 1));
    }
    while (activity.containsKey(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Spec §15's "time read" -- total seconds across every recorded day.
  Future<int> totalSecondsRead() async {
    final sumColumn = _db.readingActivity.secondsRead.sum();
    final query = _db.selectOnly(_db.readingActivity)..addColumns([sumColumn]);
    final row = await query.getSingleOrNull();
    return row?.read(sumColumn) ?? 0;
  }
}
