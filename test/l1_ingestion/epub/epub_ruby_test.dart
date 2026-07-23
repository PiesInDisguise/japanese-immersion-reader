import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:japanese_immersion_reader/l1_ingestion/epub/epub_ruby.dart';
import 'package:xml/xml.dart' as xml;

void main() {
  group('walkInlineXml + plainTextOf (package:xml backend)', () {
    test('plain text with no ruby produces a single TextRun', () {
      final p = xml.XmlDocument.parse('<p>これは普通の文です。</p>').rootElement;
      final runs = walkInlineXml(p);
      expect(runs, hasLength(1));
      expect(runs.single, isA<TextRun>());
      expect(plainTextOf(runs), 'これは普通の文です。');
    });

    test('explicit <rb>/<rt> ruby: base and reading kept separate', () {
      final p = xml.XmlDocument.parse(
        '<p><ruby><rb>東京</rb><rt>とうきょう</rt></ruby></p>',
      ).rootElement;
      final runs = walkInlineXml(p);
      final ruby = runs.single as RubyRun;
      expect(ruby.base, '東京');
      expect(ruby.reading, 'とうきょう');
    });

    test('bare ruby (no <rb>): base falls back to direct text nodes', () {
      final p = xml.XmlDocument.parse(
        '<p><ruby>友達<rt>ともだち</rt></ruby></p>',
      ).rootElement;
      final runs = walkInlineXml(p);
      final ruby = runs.single as RubyRun;
      expect(ruby.base, '友達');
      expect(ruby.reading, 'ともだち');
    });

    test('<rp> fallback parentheses are excluded from base and reading', () {
      final p = xml.XmlDocument.parse(
        '<p><ruby>大丈夫<rp>(</rp><rt>だいじょうぶ</rt><rp>)</rp></ruby></p>',
      ).rootElement;
      final runs = walkInlineXml(p);
      final ruby = runs.single as RubyRun;
      expect(ruby.base, '大丈夫');
      expect(ruby.reading, 'だいじょうぶ');
      expect(ruby.base.contains('('), isFalse);
      expect(ruby.reading.contains('('), isFalse);
    });

    test(
      'surrounding plain text and multiple ruby runs are all preserved, in order',
      () {
        final p = xml.XmlDocument.parse(
          '<p>彼は<ruby><rb>東京</rb><rt>とうきょう</rt></ruby>に行った。'
          'そこで<ruby>友達<rt>ともだち</rt></ruby>に会った。</p>',
        ).rootElement;
        final runs = walkInlineXml(p);
        expect(runs, hasLength(5));
        expect((runs[0] as TextRun).text, '彼は');
        expect((runs[1] as RubyRun).base, '東京');
        expect((runs[2] as TextRun).text, 'に行った。そこで');
        expect((runs[3] as RubyRun).base, '友達');
        expect((runs[4] as TextRun).text, 'に会った。');
        expect(plainTextOf(runs), '彼は東京に行った。そこで友達に会った。');
      },
    );

    test(
      'formatting-only inline elements are flattened but ruby nested inside is still caught',
      () {
        final p = xml.XmlDocument.parse(
          '<p>これは<em>大事な<ruby>本<rt>ほん</rt></ruby></em>です。</p>',
        ).rootElement;
        final runs = walkInlineXml(p);
        expect(plainTextOf(runs), 'これは大事な本です。');
        expect(runs.whereType<RubyRun>().single.reading, 'ほん');
      },
    );
  });

  group('extractRawBlocksXml', () {
    test('finds <p> and heading elements, in document order', () {
      final doc = xml.XmlDocument.parse('''
<body>
<h1>第一章</h1>
<p>最初の文。</p>
<p>二番目の文。</p>
</body>
''');
      final blocks = extractRawBlocksXml(doc.rootElement);
      expect(blocks.map((b) => b.tag).toList(), ['h1', 'p', 'p']);
      expect(plainTextOf(blocks[1].runs), '最初の文。');
    });

    test('descends into wrapping containers like <div>', () {
      final doc = xml.XmlDocument.parse('''
<body><div><section><p>入れ子の文。</p></section></div></body>
''');
      final blocks = extractRawBlocksXml(doc.rootElement);
      expect(blocks, hasLength(1));
      expect(plainTextOf(blocks.single.runs), '入れ子の文。');
    });

    test('drops blocks that flatten to empty/whitespace text', () {
      final doc = xml.XmlDocument.parse(
        '<body><p></p><p>  </p><p>本文。</p></body>',
      );
      final blocks = extractRawBlocksXml(doc.rootElement);
      expect(blocks, hasLength(1));
      expect(plainTextOf(blocks.single.runs), '本文。');
    });
  });

  group('walkInlineHtml + extractRawBlocksHtml (package:html backend)', () {
    test('recovers ruby from a document a strict XML parser would reject', () {
      const malformed =
          '<div><p>これは<b>壊れた<ruby>本<rt>ほん</rt></ruby>タグです</p></div>';
      expect(
        () => xml.XmlDocument.parse(malformed),
        throwsA(isA<xml.XmlException>()),
      );

      final htmlDoc = html_parser.parse(malformed);
      final blocks = extractRawBlocksHtml(htmlDoc.body!);
      expect(blocks, hasLength(1));
      final runs = blocks.single.runs;
      expect(plainTextOf(runs), 'これは壊れた本タグです');
      expect(runs.whereType<RubyRun>().single.reading, 'ほん');
    });

    test('plain HTML with no ruby produces a single TextRun per block', () {
      final htmlDoc = html_parser.parse(
        '<html><body><p>普通の文です。</p></body></html>',
      );
      final blocks = extractRawBlocksHtml(htmlDoc.body!);
      expect(blocks, hasLength(1));
      expect(blocks.single.runs, hasLength(1));
      expect(plainTextOf(blocks.single.runs), '普通の文です。');
    });

    test(
      'bare ruby and <rp> fallback both work through the html backend too',
      () {
        final htmlDoc = html_parser.parse(
          '<html><body><p><ruby>友達<rt>ともだち</rt></ruby>と'
          '<ruby>大丈夫<rp>(</rp><rt>だいじょうぶ</rt><rp>)</rp></ruby></p></body></html>',
        );
        final blocks = extractRawBlocksHtml(htmlDoc.body!);
        final rubyRuns = blocks.single.runs.whereType<RubyRun>().toList();
        expect(rubyRuns[0].base, '友達');
        expect(rubyRuns[0].reading, 'ともだち');
        expect(rubyRuns[1].base, '大丈夫');
        expect(rubyRuns[1].reading, 'だいじょうぶ');
      },
    );
  });
}
