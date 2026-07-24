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
  });
}
