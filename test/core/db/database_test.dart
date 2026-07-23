import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';

void main() {
  test('can write and read back a Documents row', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final now = DateTime.utc(2026, 1, 1);
    await db
        .into(db.documents)
        .insert(
          DocumentsCompanion.insert(
            id: 'doc-1',
            title: 'Fixture Novel',
            sourceType: 'pdfText',
            addedAt: now,
            updatedAt: now,
          ),
        );

    final rows = await db.select(db.documents).get();

    expect(rows, hasLength(1));
    expect(rows.single.title, 'Fixture Novel');
  });
}
