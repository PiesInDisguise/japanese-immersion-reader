import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/document_repository.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';

Document _buildDocument() {
  return Document(
    id: 'doc-1',
    title: 'Test Book',
    sourceType: DocumentSourceType.epub,
    chapters: [
      Chapter(
        id: 'ch-1',
        index: 0,
        title: 'Chapter 1',
        blocks: [
          Block(
            id: 'block-1',
            index: 0,
            kind: BlockKind.paragraph,
            sentences: [
              Sentence(
                id: 'sent-0',
                index: 0,
                tokens: const [Token(surface: '猫が好きです。')],
              ),
              Sentence(
                id: 'sent-1',
                index: 1,
                tokens: const [Token(surface: '犬も好きです。')],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  late AppDatabase db;
  late DocumentRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DocumentRepository(db);
  });

  tearDown(() => db.close());

  group('DocumentRepository', () {
    test('sentenceContent/documentTitle return null before save', () async {
      expect(await repository.sentenceContent('sent-0'), isNull);
      expect(await repository.documentTitle('doc-1'), isNull);
    });

    test('save persists every sentence\'s real text', () async {
      await repository.save(_buildDocument());

      expect(await repository.sentenceContent('sent-0'), '猫が好きです。');
      expect(await repository.sentenceContent('sent-1'), '犬も好きです。');
      expect(await repository.documentTitle('doc-1'), 'Test Book');
    });

    test('save is idempotent: saving again does not duplicate rows', () async {
      final document = _buildDocument();
      await repository.save(document);
      await repository.save(document);

      final sentences = await db.select(db.sentences).get();
      expect(sentences, hasLength(2));
      final documents = await db.select(db.documents).get();
      expect(documents, hasLength(1));
    });

    test('saving again with changed content overwrites, not duplicates', () async {
      await repository.save(_buildDocument());

      final updated = Document(
        id: 'doc-1',
        title: 'Test Book (corrected)',
        sourceType: DocumentSourceType.epub,
        chapters: [
          Chapter(
            id: 'ch-1',
            index: 0,
            title: 'Chapter 1',
            blocks: [
              Block(
                id: 'block-1',
                index: 0,
                kind: BlockKind.paragraph,
                sentences: [
                  Sentence(
                    id: 'sent-0',
                    index: 0,
                    tokens: const [Token(surface: '猫が大好きです。')],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await repository.save(updated);

      expect(await repository.sentenceContent('sent-0'), '猫が大好きです。');
      expect(await repository.documentTitle('doc-1'), 'Test Book (corrected)');
    });

    test(
      're-saving the same document preserves addedAt but bumps updatedAt',
      () async {
        await repository.save(_buildDocument());
        final first = await (db.select(
          db.documents,
        )..where((d) => d.id.equals('doc-1'))).getSingle();

        // Drift's default DateTimeColumn storage is second-precision (unix
        // seconds, not milliseconds) -- a shorter delay wouldn't reliably
        // cross a detectable boundary and would make this test flaky.
        await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));
        await repository.save(_buildDocument());
        final second = await (db.select(
          db.documents,
        )..where((d) => d.id.equals('doc-1'))).getSingle();

        expect(
          second.addedAt.isAtSameMomentAs(first.addedAt),
          isTrue,
          reason: 'addedAt must survive a re-save (e.g. reopening a book)',
        );
        expect(second.updatedAt.isAfter(first.updatedAt), isTrue);
      },
    );
  });

  group('listDocuments', () {
    test('returns an empty list before anything is saved', () async {
      expect(await repository.listDocuments(), isEmpty);
    });

    test('lists saved documents, most-recently-updated first', () async {
      await repository.save(_buildDocument());
      await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));
      await repository.save(
        Document(
          id: 'doc-2',
          title: 'Second Book',
          sourceType: DocumentSourceType.pdfText,
          chapters: const [],
        ),
      );

      final documents = await repository.listDocuments();

      expect(documents.map((d) => d.id).toList(), ['doc-2', 'doc-1']);
      expect(documents.first.title, 'Second Book');
      expect(documents.first.sourceType, 'pdfText');
    });
  });

  group('loadDocument', () {
    test('returns null for an id that was never saved', () async {
      expect(await repository.loadDocument('no-such-id'), isNull);
    });

    test('reconstructs a full Document, byte-for-byte, from what save '
        'persisted', () async {
      final original = _buildDocument();
      await repository.save(original);

      final loaded = await repository.loadDocument('doc-1');

      expect(loaded, isNotNull);
      expect(loaded!.id, original.id);
      expect(loaded.title, original.title);
      expect(loaded.sourceType, original.sourceType);
      expect(loaded.chapters.length, original.chapters.length);
      expect(loaded.chapters.single.blocks.single.sentences.length, 2);
      expect(
        loaded.chapters.single.blocks.single.sentences[0].surfaceText,
        '猫が好きです。',
      );
      expect(
        loaded.chapters.single.blocks.single.sentences[1].surfaceText,
        '犬も好きです。',
      );
      // Full equality, not just spot-checked fields -- freezed gives
      // Document value equality, so this catches any field the spot checks
      // above didn't.
      expect(loaded, original);
    });

    test('reconstructs multiple chapters in chapterIndex order', () async {
      final document = Document(
        id: 'doc-multi',
        title: 'Multi-chapter Book',
        sourceType: DocumentSourceType.epub,
        chapters: [
          Chapter(
            id: 'ch-b',
            index: 1,
            title: 'Chapter 2',
            blocks: [
              Block(
                id: 'block-b',
                index: 0,
                kind: BlockKind.paragraph,
                sentences: [
                  Sentence(
                    id: 'sent-b',
                    index: 0,
                    tokens: const [Token(surface: '二番目。')],
                  ),
                ],
              ),
            ],
          ),
          Chapter(
            id: 'ch-a',
            index: 0,
            title: 'Chapter 1',
            blocks: [
              Block(
                id: 'block-a',
                index: 0,
                kind: BlockKind.paragraph,
                sentences: [
                  Sentence(
                    id: 'sent-a',
                    index: 0,
                    tokens: const [Token(surface: '一番目。')],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await repository.save(document);

      final loaded = await repository.loadDocument('doc-multi');

      expect(loaded!.chapters.map((c) => c.id).toList(), ['ch-a', 'ch-b']);
    });
  });
}
