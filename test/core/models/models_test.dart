import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';

void main() {
  test('Document round-trips through JSON with full nesting', () {
    final document = Document(
      id: 'doc-1',
      title: 'Fixture Novel',
      sourceType: DocumentSourceType.pdfText,
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
                  tokens: [
                    const Token(
                      surface: 'こんにちは',
                      sourceRect: SourceRect(
                        pageIndex: 0,
                        x: 10,
                        y: 20,
                        width: 30,
                        height: 40,
                        pageWidth: 600,
                        pageHeight: 800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    final restored = Document.fromJson(document.toJson());

    expect(restored, equals(document));
    expect(
      restored.chapters.first.blocks.first.sentences.first.surfaceText,
      'こんにちは',
    );
  });

  test('Token linguistic fields default to null (pre-L2 state)', () {
    const token = Token(surface: '食べた');
    expect(token.dictForm, isNull);
    expect(token.reading, isNull);
    expect(token.pos, isNull);
    expect(token.inflection, isNull);
    expect(token.sourceRect, isNull);
  });

  test(
      'a pre-L2 sentence may hold multiple tokens split at ruby boundaries '
      '(each independent furigana span needs its own reading)', () {
    const sentence = Sentence(
      id: 'doc-1/0/0/0',
      index: 0,
      tokens: [
        Token(surface: '彼は'),
        Token(surface: '東京', reading: 'とうきょう'),
        Token(surface: 'に行った'),
      ],
    );

    expect(sentence.surfaceText, '彼は東京に行った');
    expect(sentence.tokens[1].reading, 'とうきょう');
    for (final token in sentence.tokens) {
      expect(token.dictForm, isNull);
      expect(token.pos, isNull);
      expect(token.inflection, isNull);
    }
  });
}
