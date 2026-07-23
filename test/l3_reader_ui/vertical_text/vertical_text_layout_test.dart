import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/vertical_text/vertical_text_layout.dart';

void main() {
  // Fixture chosen so every measurement is an exact, hand-verifiable
  // integer: fontSize 20 with 1.5x factors gives 30x30 cells, and a
  // 300x90 viewport fits exactly 3 characters per column. 10 characters
  // then wrap into 4 columns (3, 3, 3, 1) -- enough to exercise a full
  // column, a middle column, and a partially-filled last column.
  //
  // This class holds no Flutter framework state (no BuildContext, no
  // RenderObject) specifically so these tests can assert on layout and
  // hit-test math directly, without pumping a widget tree.
  const text = 'あいうえおかきくけこ'; // 10 kana, index 0-9.
  const layout = VerticalTextLayout(
    text: text,
    fontSize: 20,
    viewportSize: Size(300, 90),
    lineHeightFactor: 1.5,
    columnSpacingFactor: 1.5,
  );

  group('grid metrics', () {
    test('derives cell sizes from fontSize and the spacing factors', () {
      expect(layout.charHeight, 30);
      expect(layout.columnWidth, 30);
    });

    test('charsPerColumn fits the viewport height', () {
      expect(layout.charsPerColumn, 3);
    });

    test('columnCount wraps a partially-filled final column upward', () {
      expect(layout.columnCount, 4); // ceil(10 / 3)
    });

    test('contentSize spans every column at the full column height', () {
      expect(layout.contentSize, const Size(120, 90)); // 4*30 x 3*30
    });

    test('charsPerColumn is never zero, even for a tiny viewport', () {
      const tiny = VerticalTextLayout(
        text: text,
        fontSize: 20,
        viewportSize: Size(300, 1),
        lineHeightFactor: 1.5,
        columnSpacingFactor: 1.5,
      );
      expect(tiny.charsPerColumn, 1);
    });

    test('columnCount and contentSize are zero for empty text', () {
      const empty = VerticalTextLayout(
        text: '',
        fontSize: 20,
        viewportSize: Size(300, 90),
      );
      expect(empty.columnCount, 0);
      expect(empty.contentSize, Size.zero);
    });

    test('an exact multiple of charsPerColumn leaves no partial column', () {
      const nineChars = VerticalTextLayout(
        text: 'あいうえおかきくけ', // 9 kana
        fontSize: 20,
        viewportSize: Size(300, 90),
        lineHeightFactor: 1.5,
        columnSpacingFactor: 1.5,
      );
      expect(nineChars.columnCount, 3);
    });
  });

  group('column/row indexing', () {
    test('columnIndexOf groups charsPerColumn characters per column', () {
      expect(layout.columnIndexOf(0), 0);
      expect(layout.columnIndexOf(2), 0);
      expect(layout.columnIndexOf(3), 1);
      expect(layout.columnIndexOf(9), 3);
    });

    test('rowIndexOf counts top-to-bottom within a column', () {
      expect(layout.rowIndexOf(0), 0);
      expect(layout.rowIndexOf(2), 2);
      expect(layout.rowIndexOf(3), 0);
      expect(layout.rowIndexOf(9), 0);
    });
  });

  group('rectForChar places columns right-to-left', () {
    test('the first character sits in the rightmost column', () {
      expect(layout.rectForChar(0), const Rect.fromLTWH(270, 0, 30, 30));
    });

    test('later rows in the same column stay in that column', () {
      expect(layout.rectForChar(2), const Rect.fromLTWH(270, 60, 30, 30));
    });

    test('the second column sits immediately LEFT of the first', () {
      // Index 3 is the first character of column 1. Its left edge (240)
      // must be less than column 0's left edge (270): proof the column
      // order is right-to-left, not left-to-right.
      final col0Left = layout.rectForChar(0).left;
      final col1Left = layout.rectForChar(3).left;
      expect(col1Left, lessThan(col0Left));
      expect(layout.rectForChar(3), const Rect.fromLTWH(240, 0, 30, 30));
    });

    test('the last character sits in the last (leftmost) column', () {
      expect(layout.columnIndexOf(9), layout.columnCount - 1);
      expect(layout.rectForChar(9), const Rect.fromLTWH(180, 0, 30, 30));
    });

    test('throws RangeError for an out-of-range index', () {
      expect(() => layout.rectForChar(-1), throwsRangeError);
      expect(() => layout.rectForChar(text.length), throwsRangeError);
    });
  });

  group('hitTest resolves a local Offset back to a character index', () {
    test('the center of the first character resolves to index 0', () {
      expect(layout.hitTest(const Offset(285, 15)), 0);
    });

    test('the center of a middle-column character resolves correctly', () {
      // Index 3 (column 1 of 0..3) is neither the first nor the last
      // column -- this is the "middle column" case.
      expect(layout.hitTest(const Offset(255, 15)), 3);
    });

    test('the center of the last character, in the last/leftmost column, '
        'resolves correctly', () {
      expect(layout.hitTest(const Offset(195, 15)), 9);
    });

    test('every character round-trips through rectForChar -> hitTest', () {
      for (var i = 0; i < text.length; i++) {
        final rect = layout.rectForChar(i);
        expect(layout.hitTest(rect.center), i, reason: 'character $i');
      }
    });

    test('a tap past the right edge misses (negative distanceFromRight)', () {
      expect(layout.hitTest(const Offset(305, 15)), isNull);
    });

    test('a tap past the left edge (beyond the last column) misses', () {
      expect(layout.hitTest(const Offset(-5, 15)), isNull);
    });

    test('a tap above the top edge misses', () {
      expect(layout.hitTest(const Offset(285, -5)), isNull);
    });

    test('a tap below the last row of a column misses', () {
      expect(layout.hitTest(const Offset(285, 1000)), isNull);
    });

    test('a tap in the unfilled tail of a partially-filled final column '
        'misses, even though its column index is valid', () {
      // Column 3 (the last column) holds only index 9 at row 0; rows 1
      // and 2 of that same column are unfilled (10 characters don't
      // divide evenly by 3).
      expect(layout.hitTest(const Offset(195, 45)), isNull);
    });

    test('every offset misses on empty text', () {
      const empty = VerticalTextLayout(
        text: '',
        fontSize: 20,
        viewportSize: Size(300, 90),
      );
      expect(empty.hitTest(const Offset(150, 45)), isNull);
    });
  });
}
