import 'dart:math' as math;
import 'dart:ui';

/// Pure layout math for rendering [text] top-to-bottom, right-to-left-columns
/// -- the correct visual convention for 縦書き (vertical Japanese writing).
///
/// This is a rendering spike (see docs/spec.md §4 and §16: vertical text is
/// flagged as a place scope can silently triple, worth prototyping early even
/// though full `Document`-model integration is a later phase). It holds no
/// Flutter framework state at all -- no [BuildContext], no `RenderObject` --
/// on purpose, so the layout and hit-test math can be unit-tested as plain
/// Dart values, without pumping a widget tree. `RenderVerticalText` (see
/// `render_vertical_text.dart`) builds one of these every layout pass and
/// uses it for both painting and hit-testing, so the two can never disagree
/// about where a character sits.
///
/// **Coordinate convention:** top-left origin, y grows downward -- the same
/// convention `lib/core/models/source_rect.dart` establishes project-wide
/// (and Flutter's native `Rect`/`Offset`/`Canvas` convention already is
/// top-left/y-down, so this falls out naturally rather than needing any
/// special-cased flip).
///
/// **Reading-order convention:** [text] is assumed to already be in correct
/// 縦書き reading order (this class lays characters out in `text` index
/// order, it does not reorder them). Column `0` -- the first column filled --
/// is placed at the RIGHT edge of [viewportSize], with each subsequent
/// column proceeding leftward, and characters within a column flowing
/// top-to-bottom. This matches the reading-order convention the PDF-text
/// importer independently reconstructs from raw glyph positions (see
/// docs/research/r2-pdf-text.md §3.4-3.5: cluster into columns, sort columns
/// right-to-left, sort each column's characters top-to-bottom).
///
/// **Character indexing:** indices are UTF-16 code-unit offsets into [text]
/// (Dart's native `String` indexing), matching how the rest of the app
/// indexes source strings today (see `lib/core/util/sentence_splitter.dart`).
/// This spike's hardcoded sample text is plain BMP kana/kanji and never
/// exercises surrogate pairs; whoever wires this up to real tokens later
/// should re-verify that assumption against real text -- the same caveat
/// the R2 PDF-text research spike flagged for its own char-index alignment
/// with Sudachi token offsets (docs/research/r2-pdf-text.md §3.5).
///
/// **Known limitation:** every character occupies a uniform cell sized from
/// [fontSize] alone (not measured per-glyph). This is deliberate -- it keeps
/// the grid math exact and independent of font metrics, which is what makes
/// it cheaply/exactly unit-testable -- but it means proportional/measured
/// glyph widths, half-width punctuation, and rotated punctuation (small
/// kana, the long vowel mark ー) are not modeled. A real implementation
/// would need to decide how those interact with the fixed grid.
class VerticalTextLayout {
  const VerticalTextLayout({
    required this.text,
    required this.fontSize,
    required this.viewportSize,
    this.lineHeightFactor = 1.6,
    this.columnSpacingFactor = 1.6,
  }) : assert(fontSize > 0, 'fontSize must be positive'),
       assert(lineHeightFactor > 0, 'lineHeightFactor must be positive'),
       assert(columnSpacingFactor > 0, 'columnSpacingFactor must be positive');

  /// The full source string, already in 縦書き reading order.
  final String text;

  /// Font size in logical pixels. Also drives cell spacing, via
  /// [lineHeightFactor] and [columnSpacingFactor].
  final double fontSize;

  /// The bounded space available to lay text out into. Determines how many
  /// characters fit in a column before wrapping to the next (leftward)
  /// column.
  final Size viewportSize;

  /// Vertical distance between successive characters within a column, as a
  /// multiple of [fontSize].
  final double lineHeightFactor;

  /// Horizontal distance between successive columns, as a multiple of
  /// [fontSize].
  final double columnSpacingFactor;

  /// Height of one character's cell -- the vertical step within a column.
  double get charHeight => fontSize * lineHeightFactor;

  /// Width of one column's cell -- the horizontal step between columns.
  double get columnWidth => fontSize * columnSpacingFactor;

  /// How many characters fit, top-to-bottom, in a single column before
  /// wrapping to the next column. Always at least 1 -- even a pathologically
  /// short [viewportSize] still makes forward progress instead of producing
  /// a zero-height column (which would divide the text into infinite empty
  /// columns).
  int get charsPerColumn {
    final fit = (viewportSize.height / charHeight).floor();
    return math.max(1, fit);
  }

  /// Total number of columns [text] wraps into. `0` for empty [text].
  int get columnCount {
    if (text.isEmpty) return 0;
    return (text.length / charsPerColumn).ceil();
  }

  /// The overall content size this layout occupies. May exceed
  /// [viewportSize] if [text] doesn't fit -- this class does not clip,
  /// scroll, or paginate overflow; see the class doc's "known limitation"
  /// and `VerticalTextView`'s doc for what a real integration would need to
  /// add.
  Size get contentSize => Size(
    columnCount * columnWidth,
    text.isEmpty ? 0.0 : charsPerColumn * charHeight,
  );

  /// Column index for character [charIndex]. Column `0` is the RIGHTMOST
  /// column -- the first column read in 縦書き order -- and increasing
  /// indices move leftward.
  int columnIndexOf(int charIndex) => charIndex ~/ charsPerColumn;

  /// Row (top-to-bottom position within its column) for character
  /// [charIndex], counted from `0`.
  int rowIndexOf(int charIndex) => charIndex % charsPerColumn;

  /// The on-screen cell [Rect] for character [charIndex], in the same
  /// top-left-origin/y-down coordinate space as [viewportSize].
  ///
  /// Throws a [RangeError] if [charIndex] is not a valid index into [text].
  Rect rectForChar(int charIndex) {
    if (charIndex < 0 || charIndex >= text.length) {
      throw RangeError.range(charIndex, 0, text.length - 1, 'charIndex');
    }
    final column = columnIndexOf(charIndex);
    final row = rowIndexOf(charIndex);
    // Column 0 hugs the right edge; each following column shifts one more
    // columnWidth to the left.
    final left = viewportSize.width - (column + 1) * columnWidth;
    final top = row * charHeight;
    return Rect.fromLTWH(left, top, columnWidth, charHeight);
  }

  /// Resolves a tapped [position] -- in the same local coordinate space as
  /// [viewportSize]/[rectForChar] -- to a character index into [text].
  ///
  /// Returns `null` if [position] doesn't land on any character: past the
  /// last (leftmost) column, left/above the origin, below the last row of a
  /// column, or in the unfilled tail of a partially-filled final column.
  int? hitTest(Offset position) {
    if (text.isEmpty) return null;

    // Columns are indexed right-to-left, so convert the x coordinate into
    // "how far left of the right edge" before dividing into column steps.
    final distanceFromRight = viewportSize.width - position.dx;
    if (distanceFromRight < 0) return null;
    final column = (distanceFromRight / columnWidth).floor();
    if (column < 0 || column >= columnCount) return null;

    if (position.dy < 0) return null;
    final row = (position.dy / charHeight).floor();
    if (row < 0 || row >= charsPerColumn) return null;

    final index = column * charsPerColumn + row;
    return index < text.length ? index : null;
  }
}
