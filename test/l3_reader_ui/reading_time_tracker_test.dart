// A real (short, ~1s) wall-clock wait rather than a fake clock: Stopwatch
// reads real elapsed time and isn't virtualized by fake_async's Timer
// mocking, so faking this deterministically isn't straightforward. Kept to
// a single short test rather than exercising the 20-second periodic flush
// interval, which would make this suite slow for little extra confidence.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/services.dart';
import 'package:japanese_immersion_reader/app/stats/reading_activity_repository.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/reading_time_tracker.dart';

AppDatabase? _sharedInertDatabase;
AppDatabase _inertDatabase() => _sharedInertDatabase ??= AppDatabase();

class FakeReadingActivityRepository extends ReadingActivityRepository {
  FakeReadingActivityRepository() : super(_inertDatabase());

  final List<int> addSecondsCalls = [];

  @override
  Future<void> addSeconds(int seconds, {DateTime? now}) async {
    addSecondsCalls.add(seconds);
  }
}

final _trackerProvider = Provider<ReadingTimeTracker>(
  (ref) => ReadingTimeTracker(ref),
);

void main() {
  test('flushes accumulated elapsed time to the repository on dispose', () async {
    final fakeRepository = FakeReadingActivityRepository();
    final container = ProviderContainer(
      overrides: [
        readingActivityRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );

    container.read(_trackerProvider); // starts the stopwatch
    await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));

    container.dispose();

    expect(fakeRepository.addSecondsCalls, isNotEmpty);
    expect(fakeRepository.addSecondsCalls.single, greaterThanOrEqualTo(1));
  });

  test('does not call addSeconds if disposed before a full second elapses', () async {
    final fakeRepository = FakeReadingActivityRepository();
    final container = ProviderContainer(
      overrides: [
        readingActivityRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );

    container.read(_trackerProvider);
    container.dispose();

    expect(fakeRepository.addSecondsCalls, isEmpty);
  });
}
