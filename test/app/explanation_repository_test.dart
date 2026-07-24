import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/explanation_repository.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';

void main() {
  late AppDatabase db;
  late ExplanationRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ExplanationRepository(db);
  });

  tearDown(() => db.close());

  group('ExplanationRepository', () {
    test('read() returns null for an id that was never written', () async {
      expect(await repository.read('explanation-missing'), isNull);
    });

    test('write() then read() round-trips the explanation text', () async {
      await repository.write('explanation-1', 'A short grammar note.');
      expect(await repository.read('explanation-1'), 'A short grammar note.');
    });

    test('write() to an existing id overwrites rather than duplicating', () async {
      await repository.write('explanation-1', 'First version.');
      await repository.write('explanation-1', 'Corrected version.');
      expect(await repository.read('explanation-1'), 'Corrected version.');
    });
  });
}
