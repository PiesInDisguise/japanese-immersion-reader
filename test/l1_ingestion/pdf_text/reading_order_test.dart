import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_text/reading_order.dart';
import 'package:pdfrx_engine/pdfrx_engine.dart';

void main() {
  group('reconstructReadingOrder', () {
    test('returns empty for a page with no characters', () {
      final pageText = _pageText(
        fullText: '',
        charRects: [],
        fragmentSpecs: [],
      );

      expect(reconstructReadingOrder(pageText), isEmpty);
    });

    test('filters zero-size (PDFium-generated filler) characters', () {
      final pageText = _pageText(
        fullText: 'A\nB',
        charRects: [
          const PdfRect(0, 20, 10, 10), // 'A': real, 10x10
          const PdfRect(10, 20, 10, 10), // '\n': zero width -> isEmpty
          const PdfRect(20, 20, 30, 10), // 'B': real, 10x10
        ],
        fragmentSpecs: const [(length: 3, direction: PdfTextDirection.ltr)],
      );

      final result = reconstructReadingOrder(pageText);

      expect(result.map((c) => c.char).join(), 'AB');
    });

    test('filters whitespace characters even with a non-degenerate box', () {
      final pageText = _pageText(
        fullText: 'A B',
        charRects: [
          const PdfRect(0, 20, 10, 10),
          const PdfRect(10, 20, 15, 10), // generated-gap space: real box
          const PdfRect(20, 20, 30, 10),
        ],
        fragmentSpecs: const [(length: 3, direction: PdfTextDirection.ltr)],
      );

      final result = reconstructReadingOrder(pageText);

      expect(result.map((c) => c.char).join(), 'AB');
    });

    test('horizontal: orders rows top-to-bottom and each row left-to-right, '
        'independent of input (paint) order', () {
      // Row 1 (top, y~90): a,b,c left-to-right. Row 2 (bottom, y~40):
      // d,e,f left-to-right. Supplied scrambled ("ceafbd") to prove
      // reconstruction doesn't trust extraction order.
      final pageText = _pageText(
        fullText: 'ceafbd',
        charRects: [
          const PdfRect(40, 100, 50, 80), // c: row1 col3
          const PdfRect(20, 50, 30, 30), // e: row2 col2
          const PdfRect(0, 100, 10, 80), // a: row1 col1
          const PdfRect(40, 50, 50, 30), // f: row2 col3
          const PdfRect(20, 100, 30, 80), // b: row1 col2
          const PdfRect(0, 50, 10, 30), // d: row2 col1
        ],
        fragmentSpecs: const [(length: 6, direction: PdfTextDirection.ltr)],
      );

      final result = reconstructReadingOrder(pageText);

      expect(result.map((c) => c.char).join(), 'abcdef');
    });

    test(
      'vertical: orders columns right-to-left and each column top-to-bottom, '
      'independent of input (paint) order',
      () {
        // Column A (x~45, rightmost/read-first): a,b,c top-to-bottom.
        // Column B (x~5, read second): d,e,f top-to-bottom. Supplied
        // scrambled ("dafceb") to prove reconstruction doesn't trust
        // extraction order (mirrors the real scrambled-fixture regression
        // this importer must not reintroduce; see
        // docs/research/r2-pdf-text.md §3.4).
        final pageText = _pageText(
          fullText: 'dafceb',
          charRects: [
            const PdfRect(0, 100, 10, 90), // d: col B top
            const PdfRect(40, 100, 50, 90), // a: col A top
            const PdfRect(0, 40, 10, 30), // f: col B bottom
            const PdfRect(40, 40, 50, 30), // c: col A bottom
            const PdfRect(0, 70, 10, 60), // e: col B mid
            const PdfRect(40, 70, 50, 60), // b: col A mid
          ],
          fragmentSpecs: const [(length: 6, direction: PdfTextDirection.vrtl)],
        );

        final result = reconstructReadingOrder(pageText);

        expect(result.map((c) => c.char).join(), 'abcdef');
      },
    );

    test("an unknown-direction fragment inherits the preceding fragment's "
        'direction, and its characters are still included (not dropped) at '
        'their correct geometric position', () {
      // 2x2 grid: col A (x~45) / col B (x~5) cross row-top (y~90) /
      // row-bottom (y~40). Vertical regime reads "abcd" (col A
      // top-to-bottom, then col B top-to-bottom); horizontal regime would
      // instead read "cadb" (row-top left-to-right, then row-bottom) --
      // so this setup actually distinguishes the two outcomes, unlike a
      // degenerate single-column case. The final character's fragment is
      // `unknown` (the real, observed PDFium/pdfrx quirk -- see
      // docs/research/r2-pdf-text.md §3.3) and must still resolve to
      // vertical by inheriting from the preceding vrtl fragment.
      final pageText = _pageText(
        fullText: 'abcd',
        charRects: [
          const PdfRect(40, 100, 50, 80), // a: col A, row top
          const PdfRect(40, 50, 50, 30), // b: col A, row bottom
          const PdfRect(0, 100, 10, 80), // c: col B, row top
          const PdfRect(0, 50, 10, 30), // d: col B, row bottom
        ],
        fragmentSpecs: const [
          (length: 1, direction: PdfTextDirection.vrtl), // 'a'
          (length: 2, direction: PdfTextDirection.vrtl), // 'bc'
          (length: 1, direction: PdfTextDirection.unknown), // 'd'
        ],
      );

      final result = reconstructReadingOrder(pageText);

      expect(result.map((c) => c.char).join(), 'abcd');
    });
  });
}

PdfPageText _pageText({
  required String fullText,
  required List<PdfRect> charRects,
  required List<({int length, PdfTextDirection direction})> fragmentSpecs,
}) {
  final fragments = <PdfPageTextFragment>[];
  final pageText = PdfPageText(
    pageNumber: 1,
    fullText: fullText,
    charRects: charRects,
    fragments: fragments,
  );

  var start = 0;
  for (final spec in fragmentSpecs) {
    final end = start + spec.length;
    fragments.add(
      PdfPageTextFragment(
        pageText: pageText,
        index: start,
        length: spec.length,
        bounds: charRects.sublist(start, end).reduce((a, b) => a.merge(b)),
        charRects: charRects.sublist(start, end),
        direction: spec.direction,
      ),
    );
    start = end;
  }

  return pageText;
}
