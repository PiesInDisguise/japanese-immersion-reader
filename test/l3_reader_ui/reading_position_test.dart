import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/document_repository.dart';
import 'package:japanese_immersion_reader/app/services.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/reading_position.dart';

AppDatabase? _sharedInertDatabase;
AppDatabase _inertDatabase() => _sharedInertDatabase ??= AppDatabase();

class _RecordingDocumentRepository extends DocumentRepository {
  _RecordingDocumentRepository() : super(_inertDatabase());

  final List<({String documentId, String sentenceId})> calls = [];

  @override
  Future<void> updateLastSentenceId(String documentId, String sentenceId) async {
    calls.add((documentId: documentId, sentenceId: sentenceId));
  }
}

class _ThrowingDocumentRepository extends DocumentRepository {
  _ThrowingDocumentRepository() : super(_inertDatabase());

  @override
  Future<void> updateLastSentenceId(String documentId, String sentenceId) {
    throw StateError(
      '_ThrowingDocumentRepository.updateLastSentenceId should not be called',
    );
  }
}

Document _document(String id) => Document(
  id: id,
  title: 'Test Book',
  sourceType: DocumentSourceType.epub,
  chapters: const [],
);

void main() {
  test('set() with no current document does not throw and does not persist', () async {
    final container = ProviderContainer(
      overrides: [
        documentRepositoryProvider.overrideWithValue(
          _ThrowingDocumentRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentSentencePositionProvider.notifier).set('sent-1');
    await Future<void>.delayed(Duration.zero);

    expect(container.read(currentSentencePositionProvider), 'sent-1');
  });

  test('set(null) does not persist', () async {
    final repository = _RecordingDocumentRepository();
    final container = ProviderContainer(
      overrides: [
        documentRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.read(currentDocumentProvider.notifier).set(_document('doc-1'));

    container.read(currentSentencePositionProvider.notifier).set(null);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(currentSentencePositionProvider), isNull);
    expect(repository.calls, isEmpty);
  });

  test('set() with a current document persists via updateLastSentenceId', () async {
    final repository = _RecordingDocumentRepository();
    final container = ProviderContainer(
      overrides: [
        documentRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.read(currentDocumentProvider.notifier).set(_document('doc-1'));

    container.read(currentSentencePositionProvider.notifier).set('sent-3');
    // The write is fire-and-forget -- let the microtask run before asserting.
    await Future<void>.delayed(Duration.zero);

    expect(container.read(currentSentencePositionProvider), 'sent-3');
    expect(repository.calls, [(documentId: 'doc-1', sentenceId: 'sent-3')]);
  });
}
