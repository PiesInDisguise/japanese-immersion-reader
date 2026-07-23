import 'package:pdfrx_engine/pdfrx_engine.dart';

/// One real (visible, non-degenerate) character on a page. `rect` is still
/// in raw PDF-space (bottom-left origin, y-up) -- callers that need a
/// top-left/y-down `SourceRect` must flip it (see
/// `lib/core/models/source_rect.dart`'s doc comment).
typedef PositionedChar = ({String char, PdfRect rect});

/// The two reading-order regimes this importer distinguishes. Mixed
/// horizontal+vertical content on a single page (e.g. a horizontal heading
/// above vertical body text) is out of scope for this pass -- the whole
/// page is classified into exactly one regime. (Flagged as unverified in
/// docs/research/r2-pdf-text.md §6 item 1; reasonable to defer given none of
/// this importer's fixtures exercise mixed-direction pages.)
enum ReadingRegime { horizontal, vertical }

/// Reconstructs true visual reading order for a page's characters.
///
/// PDFium (and therefore pdfrx_engine) linearizes `PdfPageText.fullText` /
/// `charRects` in content-stream *paint* order, not visual reading order.
/// This project's own R2 research spike proved that gap concretely
/// (docs/research/r2-pdf-text.md §3.4): a page with two vertical (縦書き)
/// columns painted right-to-left (correct reading order) extracts correctly,
/// but the *pixel-identical* page with the same two columns painted
/// left-to-right extracts with the columns' text swapped -- even though
/// every individual character's bounding box is in the geometrically correct
/// visual position. So this function ignores extraction order entirely and
/// derives reading order purely from character geometry:
///
///  - vertical pages: cluster characters into columns by x-position, order
///    columns right-to-left, then order each column's characters
///    top-to-bottom;
///  - horizontal pages: cluster characters into rows by y-position, order
///    rows top-to-bottom, then order each row's characters left-to-right.
///
/// Also filters out characters that PDFium/pdfrx synthesizes rather than
/// paints -- zero-size filler characters at run/line boundaries, and any
/// whitespace (Japanese prose has no real inter-word spaces, so a space or
/// newline here is always such a formatting artifact, never content). Left
/// unfiltered, these would either produce an invisible, zero-size tap target
/// or leak a stray character into reconstructed sentence text (see
/// docs/research/r2-pdf-text.md §2).
List<PositionedChar> reconstructReadingOrder(PdfPageText pageText) {
  final chars = _realChars(pageText);
  if (chars.isEmpty) return const [];

  return _regimeOf(pageText) == ReadingRegime.vertical
      ? _byColumnsThenTopToBottom(chars)
      : _byRowsThenLeftToRight(chars);
}

List<PositionedChar> _realChars(PdfPageText pageText) {
  final result = <PositionedChar>[];
  for (var i = 0; i < pageText.charRects.length; i++) {
    final rect = pageText.charRects[i];
    final char = pageText.fullText.substring(i, i + 1);
    // Zero-width/zero-height boxes are PDFium-generated fillers (line
    // breaks, run-gap spaces), never real glyphs. Whitespace characters
    // (even on the rare occasion one carries a non-degenerate generated-gap
    // box) are formatting artifacts in Japanese prose, not content.
    if (rect.isEmpty || char.trim().isEmpty) continue;
    result.add((char: char, rect: rect));
  }
  return result;
}

/// The page's dominant reading regime, from a character-count-weighted
/// majority vote over fragment directions.
///
/// A fragment with `unknown` direction -- observed in practice to be
/// whichever character PDFium extracts *last* on the page, an edge case
/// noted in docs/research/r2-pdf-text.md §3.3 -- inherits the nearest
/// preceding fragment's resolved direction, or, failing that (an `unknown`
/// fragment at the very start of the page), the first resolved direction
/// found anywhere on the page. A page with no resolved direction at all
/// (e.g. no text) defaults to horizontal; moot, since there are then no
/// characters to order either way.
ReadingRegime _regimeOf(PdfPageText pageText) {
  final resolved = <PdfTextDirection>[];
  PdfTextDirection? lastResolved;
  for (final fragment in pageText.fragments) {
    final direction = fragment.direction;
    if (direction != PdfTextDirection.unknown) {
      lastResolved = direction;
    }
    resolved.add(
      direction != PdfTextDirection.unknown
          ? direction
          : (lastResolved ?? PdfTextDirection.unknown),
    );
  }
  final firstResolved = resolved.firstWhere(
    (direction) => direction != PdfTextDirection.unknown,
    orElse: () => PdfTextDirection.ltr,
  );

  var verticalCount = 0;
  var horizontalCount = 0;
  for (var i = 0; i < pageText.fragments.length; i++) {
    final direction = resolved[i] == PdfTextDirection.unknown
        ? firstResolved
        : resolved[i];
    final charCount = pageText.fragments[i].charRects
        .where((rect) => rect.isNotEmpty)
        .length;
    if (direction == PdfTextDirection.vrtl) {
      verticalCount += charCount;
    } else {
      horizontalCount += charCount;
    }
  }
  return verticalCount > horizontalCount
      ? ReadingRegime.vertical
      : ReadingRegime.horizontal;
}

List<PositionedChar> _byColumnsThenTopToBottom(List<PositionedChar> chars) {
  final rightToLeft = [...chars]
    ..sort((a, b) => b.rect.center.x.compareTo(a.rect.center.x));
  final columns = _cluster(
    rightToLeft,
    position: (c) => c.rect.center.x,
    extent: (c) => c.rect.width,
  );

  final result = <PositionedChar>[];
  for (final column in columns) {
    final topToBottom = [...column]
      ..sort((a, b) => b.rect.center.y.compareTo(a.rect.center.y));
    result.addAll(topToBottom);
  }
  return result;
}

List<PositionedChar> _byRowsThenLeftToRight(List<PositionedChar> chars) {
  final topToBottom = [...chars]
    ..sort((a, b) => b.rect.center.y.compareTo(a.rect.center.y));
  final rows = _cluster(
    topToBottom,
    position: (c) => c.rect.center.y,
    extent: (c) => c.rect.height,
  );

  final result = <PositionedChar>[];
  for (final row in rows) {
    final leftToRight = [...row]
      ..sort((a, b) => a.rect.center.x.compareTo(b.rect.center.x));
    result.addAll(leftToRight);
  }
  return result;
}

/// Fraction of a group's median character extent (width for columns, height
/// for rows) that the next candidate's position must fall short of the
/// group's anchor by, before a new column/row starts.
///
/// Tuned against this importer's own fixtures (see
/// docs/research/r2-pdf-text.md §3.5 and §5): column gap ~32pt vs ~18-19pt
/// median char width; row gap ~22pt vs ~18-19pt median char height. In both
/// cases within-group jitter (differing glyph side-bearings) is at most a
/// couple of points, so 0.6x the median extent sits safely between jitter
/// and genuine column/row gaps without needing per-fixture tuning.
const _gapThresholdFactor = 0.6;

/// Greedily buckets `sortedDescending` (already sorted by descending
/// [position]) into contiguous groups (columns or rows): a new group starts
/// whenever an item's [position] falls more than [_gapThresholdFactor] of
/// the group's median [extent] behind the group's anchor (its first
/// member's position).
List<List<PositionedChar>> _cluster(
  List<PositionedChar> sortedDescending, {
  required double Function(PositionedChar) position,
  required double Function(PositionedChar) extent,
}) {
  if (sortedDescending.isEmpty) return const [];

  final threshold = _median(sortedDescending.map(extent)) * _gapThresholdFactor;
  final groups = <List<PositionedChar>>[];
  var current = <PositionedChar>[sortedDescending.first];
  var anchor = position(sortedDescending.first);

  for (var i = 1; i < sortedDescending.length; i++) {
    final item = sortedDescending[i];
    final pos = position(item);
    if (anchor - pos > threshold) {
      groups.add(current);
      current = <PositionedChar>[];
      anchor = pos;
    }
    current.add(item);
  }
  groups.add(current);
  return groups;
}

double _median(Iterable<double> values) {
  final sorted = values.toList()..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}
