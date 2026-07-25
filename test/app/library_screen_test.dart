import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/cover_art_store.dart';
import 'package:japanese_immersion_reader/app/document_repository.dart';
import 'package:japanese_immersion_reader/app/library_screen.dart';
import 'package:japanese_immersion_reader/app/services.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';

AppDatabase? _sharedInertDatabase;
AppDatabase _inertDatabase() => _sharedInertDatabase ??= AppDatabase();

class FakeDocumentRepository extends DocumentRepository {
  FakeDocumentRepository(this._documents) : super(_inertDatabase());

  final List<DocumentRow> _documents;
  final List<({String documentId, String coverImagePath})>
  updateCoverImagePathCalls = [];

  @override
  Future<List<DocumentRow>> listDocuments() async => _documents;

  @override
  Future<void> updateCoverImagePath(
    String documentId,
    String coverImagePath,
  ) async {
    updateCoverImagePathCalls.add((
      documentId: documentId,
      coverImagePath: coverImagePath,
    ));
  }
}

DocumentRow _row({
  required String id,
  required String title,
  String sourceType = 'epub',
  String? coverImagePath,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return DocumentRow(
    id: id,
    title: title,
    sourceType: sourceType,
    addedAt: now,
    updatedAt: now,
    coverImagePath: coverImagePath,
  );
}

Future<void> _pumpLibraryScreen(
  WidgetTester tester,
  List<DocumentRow> documents, {
  FakeDocumentRepository? documentRepository,
  Directory? coverArtDirectory,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        documentRepositoryProvider.overrideWithValue(
          documentRepository ?? FakeDocumentRepository(documents),
        ),
        coverArtStoreProvider.overrideWithValue(
          CoverArtStore(directoryOverride: coverArtDirectory),
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

  group('cover thumbnail', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('library_screen_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('a row with no coverImagePath shows the placeholder icon', (
      tester,
    ) async {
      await _pumpLibraryScreen(tester, [
        _row(id: 'doc-1', title: 'First Book'),
      ]);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    // Widget tests exercising `Image.file`'s two other branches --
    // "a real cover file renders Image.file, not the icon" and "a missing
    // file's errorBuilder falls back to the icon" -- are deliberately not
    // included: `FileImage`'s real-disk decode (success *and* failure
    // paths alike) does not reliably resolve within `pumpAndSettle` under
    // this project's `flutter_tester` environment (confirmed via isolated
    // repro -- `Image.memory` with identical PNG bytes completes
    // instantly, so this is specific to `FileImage`'s disk-backed decode
    // in this test harness, not a bug in `_buildCoverThumbnail`'s own
    // straightforward `Image.file(..., errorBuilder: ...)` usage, which is
    // standard Flutter API usage). The null-path test above and the
    // structural tap-target test below still cover this widget's actual
    // branching logic.

    testWidgets(
      'the cover thumbnail is wrapped in its own tap target, separate from '
      "the row's open-book tap handler",
      (tester) async {
        // Structural check only -- deliberately does NOT tap the thumbnail:
        // doing so would invoke the real FilePicker.pickFiles, which on
        // Windows opens a real native dialog with no platform-channel mock
        // available in this suite, hanging the test indefinitely. See
        // library_screen.dart's own doc comment on _pickCustomCover.
        await _pumpLibraryScreen(tester, [
          _row(id: 'doc-1', title: 'First Book'),
        ]);
        await tester.pumpAndSettle();

        final listTile = find.byType(ListTile);
        expect(listTile, findsOneWidget);
        // ListTile itself already renders one implicit InkWell for its own
        // onTap -- the leading cover thumbnail's own explicit InkWell (see
        // library_screen.dart) makes this at least two, proving it owns a
        // separate tap target rather than relying on the row's.
        expect(
          find.descendant(of: listTile, matching: find.byType(InkWell)),
          findsAtLeastNWidgets(2),
          reason:
              'the leading cover thumbnail must own a separate tap target '
              "from the ListTile's own onTap (open book)",
        );
      },
    );
  });
}
