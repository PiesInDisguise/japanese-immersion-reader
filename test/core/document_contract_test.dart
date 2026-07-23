import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';

import 'document_contract.dart';

void main() {
  group('checkDocumentContract', () {
    test('accepts a well-formed EPUB-sourced document', () {
      final doc = _buildDocument(withSourceRects: false);
      expect(
        () => checkDocumentContract(doc, expectSourceRects: false),
        returnsNormally,
      );
    });

    test('accepts a well-formed PDF-sourced document with sourceRects', () {
      final doc = _buildDocument(withSourceRects: true);
      expect(
        () => checkDocumentContract(doc, expectSourceRects: true),
        returnsNormally,
      );
    });

    test('rejects a document with a non-contiguous chapter index', () {
      final base = _buildDocument(withSourceRects: false);
      final broken = base.copyWith(
        chapters: [base.chapters.first.copyWith(index: 5)],
      );
      expect(
        () => checkDocumentContract(broken, expectSourceRects: false),
        throwsA(isA<TestFailure>()),
      );
    });

    test(
      'rejects an EPUB-sourced document that unexpectedly carries a sourceRect',
      () {
        final doc = _buildDocument(withSourceRects: true);
        expect(
          () => checkDocumentContract(doc, expectSourceRects: false),
          throwsA(isA<TestFailure>()),
        );
      },
    );

    test(
      'accepts a sentence pre-split into multiple tokens at ruby '
      'boundaries (no dictForm/pos/inflection yet, since L2 has not run)',
      () {
        final base = _buildDocument(withSourceRects: false);
        final chapter = base.chapters.first;
        final block = chapter.blocks.first;
        final withRubySplit = base.copyWith(
          chapters: [
            chapter.copyWith(
              blocks: [
                block.copyWith(
                  sentences: [
                    block.sentences.first.copyWith(
                      tokens: [
                        const Token(surface: '彼は'),
                        const Token(surface: '東京', reading: 'とうきょう'),
                        const Token(surface: 'に行った'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
        expect(
          () => checkDocumentContract(withRubySplit, expectSourceRects: false),
          returnsNormally,
        );
      },
    );

    test('rejects a sentence with no tokens', () {
      final base = _buildDocument(withSourceRects: false);
      final chapter = base.chapters.first;
      final block = chapter.blocks.first;
      final broken = base.copyWith(
        chapters: [
          chapter.copyWith(
            blocks: [
              block.copyWith(
                sentences: [block.sentences.first.copyWith(tokens: [])],
              ),
            ],
          ),
        ],
      );
      expect(
        () => checkDocumentContract(broken, expectSourceRects: false),
        throwsA(isA<TestFailure>()),
      );
    });
  });

  group('checkSentenceIdsStable', () {
    test('accepts two documents with matching per-position sentence IDs', () {
      final a = _buildDocument(withSourceRects: false);
      final b = _buildDocument(withSourceRects: false);
      expect(() => checkSentenceIdsStable(a, b), returnsNormally);
    });

    test(
      'rejects two documents whose sentence IDs differ at the same position',
      () {
        final a = _buildDocument(withSourceRects: false);
        final bBase = _buildDocument(withSourceRects: false);
        final bChapter = bBase.chapters.first;
        final bBlock = bChapter.blocks.first;
        final b = bBase.copyWith(
          chapters: [
            bChapter.copyWith(
              blocks: [
                bBlock.copyWith(
                  sentences: [
                    bBlock.sentences.first.copyWith(id: 'different-id'),
                  ],
                ),
              ],
            ),
          ],
        );
        expect(() => checkSentenceIdsStable(a, b), throwsA(isA<TestFailure>()));
      },
    );
  });
}

Document _buildDocument({required bool withSourceRects}) {
  SourceRect? rect() => withSourceRects
      ? const SourceRect(
          pageIndex: 0,
          x: 0,
          y: 0,
          width: 10,
          height: 10,
          pageWidth: 100,
          pageHeight: 100,
        )
      : null;

  return Document(
    id: 'doc-1',
    title: 'Fixture',
    sourceType: withSourceRects
        ? DocumentSourceType.pdfText
        : DocumentSourceType.epub,
    chapters: [
      Chapter(
        id: 'doc-1/0',
        index: 0,
        title: 'Chapter 1',
        blocks: [
          Block(
            id: 'doc-1/0/0',
            index: 0,
            kind: BlockKind.paragraph,
            sentences: [
              Sentence(
                id: 'doc-1/0/0/0',
                index: 0,
                tokens: [Token(surface: 'こんにちは', sourceRect: rect())],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
