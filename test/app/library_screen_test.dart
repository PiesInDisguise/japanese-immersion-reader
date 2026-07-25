import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/document_repository.dart';
import 'package:japanese_immersion_reader/app/library_screen.dart';
import 'package:japanese_immersion_reader/app/services.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';

AppDatabase? _sharedInertDatabase;
AppDatabase _inertDatabase() => _sharedInertDatabase ??= AppDatabase();

class FakeDocumentRepository extends DocumentRepository {
  FakeDocumentRepository(this._documents) : super(_inertDatabase());

  final List<DocumentRow> _documents;

  @override
  Future<List<DocumentRow>> listDocuments() async => _documents;
}

DocumentRow _row({
  required String id,
  required String title,
  String sourceType = 'epub',
}) {
  final now = DateTime.utc(2026, 1, 1);
  return DocumentRow(
    id: id,
    title: title,
    sourceType: sourceType,
    addedAt: now,
    updatedAt: now,
  );
}

Future<void> _pumpLibraryScreen(
  WidgetTester tester,
  List<DocumentRow> documents,
) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        documentRepositoryProvider.overrideWithValue(
          FakeDocumentRepository(documents),
        ),
      ],
      child: const MaterialApp(home: LibraryScreen()),
    ),
  );
}

void main() {
  testWidgets('shows an empty-state message when there are no books', (
    tester,
  ) async {
    await _pumpLibraryScreen(tester, const []);
    await tester.pumpAndSettle();

    expect(
      find.text('No books yet -- import one to get started.'),
      findsOneWidget,
    );
  });

  testWidgets('lists every document\'s title', (tester) async {
    await _pumpLibraryScreen(tester, [
      _row(id: 'doc-1', title: 'First Book'),
      _row(id: 'doc-2', title: 'Second Book', sourceType: 'pdfText'),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('First Book'), findsOneWidget);
    expect(find.text('Second Book'), findsOneWidget);
  });

  testWidgets('tapping a book pops the screen with its id', (tester) async {
    String? poppedValue;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentRepositoryProvider.overrideWithValue(
            FakeDocumentRepository([_row(id: 'doc-1', title: 'First Book')]),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                poppedValue = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (_) => const LibraryScreen()),
                );
              },
              child: const Text('Open Library'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First Book'));
    await tester.pumpAndSettle();

    expect(poppedValue, 'doc-1');
  });
}
