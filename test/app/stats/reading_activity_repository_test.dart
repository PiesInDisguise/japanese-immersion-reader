import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/stats/reading_activity_repository.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';

void main() {
  late AppDatabase db;
  late ReadingActivityRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ReadingActivityRepository(db);
  });

  tearDown(() => db.close());

  final day1 = DateTime.utc(2026, 1, 1, 10);
  final day2 = DateTime.utc(2026, 1, 2, 9);
  final day3 = DateTime.utc(2026, 1, 3, 23);

  group('addSeconds', () {
    test('creates a row for a fresh day', () async {
      await repository.addSeconds(120, now: day1);
      final activity = await repository.activityByDay(days: 1, now: day1);
      expect(activity[DateTime.utc(2026, 1, 1)], 120);
    });

    test('accumulates multiple calls on the same UTC day', () async {
      await repository.addSeconds(100, now: day1);
      await repository.addSeconds(50, now: day1.add(const Duration(hours: 2)));

      final activity = await repository.activityByDay(days: 1, now: day1);
      expect(activity[DateTime.utc(2026, 1, 1)], 150);
    });

    test('zero or negative seconds is a no-op', () async {
      await repository.addSeconds(0, now: day1);
      await repository.addSeconds(-5, now: day1);
      final activity = await repository.activityByDay(days: 1, now: day1);
      expect(activity, isEmpty);
    });
  });

  group('activityByDay', () {
    test('only returns days within the requested range', () async {
      await repository.addSeconds(60, now: day1);
      await repository.addSeconds(60, now: day3);

      final activity = await repository.activityByDay(days: 2, now: day3);

      expect(activity.containsKey(DateTime.utc(2026, 1, 1)), isFalse);
      expect(activity[DateTime.utc(2026, 1, 3)], 60);
    });
  });

  group('totalSecondsRead', () {
    test('sums every recorded day', () async {
      await repository.addSeconds(100, now: day1);
      await repository.addSeconds(200, now: day2);
      expect(await repository.totalSecondsRead(), 300);
    });

    test('is 0 with no activity recorded', () async {
      expect(await repository.totalSecondsRead(), 0);
    });
  });

  group('currentStreakDays', () {
    test('is 0 with no activity at all', () async {
      expect(await repository.currentStreakDays(now: day3), 0);
    });

    test('counts consecutive days ending today', () async {
      await repository.addSeconds(60, now: day1);
      await repository.addSeconds(60, now: day2);
      await repository.addSeconds(60, now: day3);

      expect(await repository.currentStreakDays(now: day3), 3);
    });

    test('a gap breaks the streak', () async {
      await repository.addSeconds(60, now: day1);
      // day2 skipped
      await repository.addSeconds(60, now: day3);

      expect(await repository.currentStreakDays(now: day3), 1);
    });

    test('today having no activity yet does not break an in-progress streak', () async {
      await repository.addSeconds(60, now: day1);
      await repository.addSeconds(60, now: day2);
      // "now" is day3, but nothing has been read yet today.

      expect(await repository.currentStreakDays(now: day3), 2);
    });
  });
}
