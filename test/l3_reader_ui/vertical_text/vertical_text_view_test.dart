import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/vertical_text/render_vertical_text.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/vertical_text/vertical_text.dart';

void main() {
  // Same fixture shape as vertical_text_layout_test.dart's hand-verifiable
  // numbers, but exercised through the real widget tree this time: fontSize
  // 16 with 1.5x factors gives 24x24 cells, and a 300x240 viewport fits
  // exactly 10 characters per column. sampleVerticalText is 33 characters,
  // wrapping into 4 columns (10, 10, 10, 3).
  const fontSize = 16.0;
  const lineHeightFactor = 1.5;
  const columnSpacingFactor = 1.5;
  const viewportSize = Size(300, 240);

  Widget buildTestee({ValueChanged<int>? onCharacterTapped}) {
    // Centered rather than pumped bare: a fixed-size widget's SizedBox can
    // only achieve its requested size when the ambient constraints actually
    // allow it (ordinary Flutter box-layout rules -- ambient tight
    // constraints, like the bare test surface's, otherwise win). Center
    // supplies the loose constraints a real embedding (a reader screen) is
    // expected to provide too.
    return Center(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: VerticalTextView(
          text: sampleVerticalText,
          size: viewportSize,
          fontSize: fontSize,
          lineHeightFactor: lineHeightFactor,
          columnSpacingFactor: columnSpacingFactor,
          onCharacterTapped: onCharacterTapped,
        ),
      ),
    );
  }

  test('the widget exposes the same layout math its render object uses', () {
    const view = VerticalTextView(
      text: sampleVerticalText,
      size: viewportSize,
      fontSize: fontSize,
      lineHeightFactor: lineHeightFactor,
      columnSpacingFactor: columnSpacingFactor,
    );

    expect(view.layout.charsPerColumn, 10);
    expect(view.layout.columnCount, 4); // ceil(33 / 10)
    expect(view.layout.rectForChar(0), const Rect.fromLTWH(276, 0, 24, 24));
  });

  testWidgets('pumps and sizes itself to the requested viewport', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestee());

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(VerticalTextView)), viewportSize);
  });

  testWidgets('tapping the first character reports index 0', (tester) async {
    int? tapped;
    await tester.pumpWidget(
      buildTestee(onCharacterTapped: (index) => tapped = index),
    );

    final topLeft = tester.getTopLeft(find.byType(VerticalTextView));
    // Center of character 0's cell: column 0 (rightmost), row 0.
    await tester.tapAt(topLeft + const Offset(288, 12));
    await tester.pump();

    expect(tapped, 0);
  });

  testWidgets(
    'tapping a character in a middle column reports the right-to-left '
    'column order, not left-to-right',
    (tester) async {
      int? tapped;
      await tester.pumpWidget(
        buildTestee(onCharacterTapped: (index) => tapped = index),
      );

      final topLeft = tester.getTopLeft(find.byType(VerticalTextView));
      // Center of character 10's cell: column 1 of 0..3 (a middle column,
      // not the first or last), row 0. If columns were accidentally laid
      // out left-to-right, this tap would land on a much later character
      // instead.
      await tester.tapAt(topLeft + const Offset(264, 12));
      await tester.pump();

      expect(tapped, 10);
    },
  );

  testWidgets(
    'tapping the last character, in the last/leftmost column, resolves '
    'correctly',
    (tester) async {
      int? tapped;
      await tester.pumpWidget(
        buildTestee(onCharacterTapped: (index) => tapped = index),
      );

      final topLeft = tester.getTopLeft(find.byType(VerticalTextView));
      // Center of character 32's cell (the final character): column 3
      // (the last, leftmost column), row 2.
      await tester.tapAt(topLeft + const Offset(216, 60));
      await tester.pump();

      expect(tapped, 32);
    },
  );

  testWidgets(
    'tapping the unfilled tail of a partially-filled final column does '
    'not report any character',
    (tester) async {
      int? tapped;
      await tester.pumpWidget(
        buildTestee(onCharacterTapped: (index) => tapped = index),
      );

      final topLeft = tester.getTopLeft(find.byType(VerticalTextView));
      // Column 3 (the last column) only has 3 characters (rows 0-2); row 5
      // in that same column is unfilled.
      await tester.tapAt(topLeft + const Offset(216, 132));
      await tester.pump();

      expect(tapped, isNull);
    },
  );

  testWidgets('a tap is silently ignored with no onCharacterTapped set', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestee());

    final topLeft = tester.getTopLeft(find.byType(VerticalTextView));
    await tester.tapAt(topLeft + const Offset(288, 12));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  group('word highlighting', () {
    testWidgets(
      'forwards highlightedCharIndices/highlightColor to the render object '
      'and paints without error',
      (tester) async {
        const highlightColor = Color(0x66FFEE58);
        await tester.pumpWidget(
          Center(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: VerticalTextView(
                text: sampleVerticalText,
                size: viewportSize,
                fontSize: fontSize,
                lineHeightFactor: lineHeightFactor,
                columnSpacingFactor: columnSpacingFactor,
                highlightedCharIndices: const {0, 1, 2},
                highlightColor: highlightColor,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        final renderObject = tester.renderObject<RenderVerticalText>(
          find.byType(RawVerticalText),
        );
        expect(renderObject.highlightedCharIndices, {0, 1, 2});
        expect(renderObject.highlightColor, highlightColor);
      },
    );

    testWidgets('defaults to no highlighting when unset', (tester) async {
      await tester.pumpWidget(buildTestee());

      final renderObject = tester.renderObject<RenderVerticalText>(
        find.byType(RawVerticalText),
      );
      expect(renderObject.highlightedCharIndices, isNull);
      expect(renderObject.highlightColor, isNull);
    });
  });
}
