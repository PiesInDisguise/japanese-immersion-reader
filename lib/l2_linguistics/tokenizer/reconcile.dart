import 'package:japanese_immersion_reader/core/models/models.dart';

/// Merges L1's position/evidence-aware placeholder tokens for one sentence
/// with a [Tokenizer]'s real (but position-blind) segmentation of that same
/// sentence's surface text, producing the sentence's final token list.
///
/// [l1Tokens] and [sudachiTokens] must be two different tokenizations of the
/// *exact same underlying text* -- `l1Tokens.map((t) => t.surface).join()`
/// must equal `sudachiTokens.map((t) => t.surface).join()` character for
/// character (this throws if it doesn't; the tokenizer must always be
/// called with the L1 sentence's own `surfaceText`, never a re-normalized
/// copy of it). Given that, every character position is covered by exactly
/// one token from each list, so the two lists' boundaries can be
/// reconciled purely by character offset, with no knowledge of what either
/// tokenizer actually did.
///
/// Per Sudachi token (the segmentation and `dictForm`/`pos`/`inflection`
/// always come from here -- that's exclusively L2's job):
/// - `reading`: an overlapping L1 token's reading (i.e. EPUB ruby) wins over
///   Sudachi's own reading, since author-supplied furigana must not be
///   regenerated (spec §4). Two different many-to-one overlaps are possible
///   here and both are handled: if *several L1 tokens* overlap one Sudachi
///   token, the greatest-overlap one is used; if *one ruby-bearing L1 token*
///   overlaps several Sudachi tokens (Sudachi split that span into more than
///   one morpheme), only the first Sudachi token to claim it gets the
///   reading -- the rest keep Sudachi's own, rather than duplicating the
///   same furigana onto every piece or fabricating a partial split. This is
///   a known, accepted imprecision, not a bug: real furigana-per-morpheme
///   attribution would need per-mora alignment data ruby markup doesn't
///   carry.
/// - `sourceRect`: the union of every overlapping L1 token's rect (handles
///   both one L1 token fully covering a Sudachi token, and a Sudachi token
///   spanning several L1 tokens), or null if none had one (EPUB).
/// - `confidence`: the *lowest* overlapping non-null confidence, so a
///   merged token can't silently hide an uncertain OCR region behind a
///   confident neighbor's score.
List<Token> reconcileSentenceTokens(
  List<Token> l1Tokens,
  List<Token> sudachiTokens,
) {
  final l1Surface = l1Tokens.map((t) => t.surface).join();
  final sudachiSurface = sudachiTokens.map((t) => t.surface).join();
  if (l1Surface != sudachiSurface) {
    throw ArgumentError(
      'reconcileSentenceTokens: L1 and tokenizer surface text must match '
      "exactly. L1: '$l1Surface' vs tokenizer: '$sudachiSurface' -- the "
      "tokenizer must always be called with the L1 sentence's own "
      'surfaceText.',
    );
  }

  final l1Spans = _spansOf(l1Tokens);

  // A single ruby-bearing L1 token can overlap *more than one* Sudachi
  // token if Sudachi splits that span into multiple morphemes -- tracked
  // here (by span identity) so the reading is attributed only once, to
  // whichever Sudachi token claims it first, rather than duplicated onto
  // every piece. Processing Sudachi tokens in their given (left-to-right)
  // order means "first" is well-defined and deterministic.
  final claimedForReading = <_Span>{};

  return [
    for (final sudachiSpan in _spansOf(sudachiTokens))
      _reconcileOne(
        sudachiSpan,
        _overlapping(l1Spans, sudachiSpan),
        claimedForReading,
      ),
  ];
}

class _Span {
  _Span(this.token, this.start, this.end);

  final Token token;
  final int start;
  final int end;
}

List<_Span> _spansOf(List<Token> tokens) {
  final spans = <_Span>[];
  var offset = 0;
  for (final token in tokens) {
    spans.add(_Span(token, offset, offset + token.surface.length));
    offset += token.surface.length;
  }
  return spans;
}

List<_Span> _overlapping(List<_Span> l1Spans, _Span sudachiSpan) {
  return l1Spans
      .where((l1) => l1.start < sudachiSpan.end && l1.end > sudachiSpan.start)
      .toList();
}

Token _reconcileOne(
  _Span sudachiSpan,
  List<_Span> overlappingL1,
  Set<_Span> claimedForReading,
) {
  final sudachi = sudachiSpan.token;
  if (overlappingL1.isEmpty) {
    // Not reachable when the surface-equality check above passed and both
    // token lists are well-formed (every character is covered by exactly
    // one span from each list) -- kept as a total, defensive fallback
    // rather than assuming that invariant always holds perfectly.
    return sudachi;
  }

  final availableForReading = overlappingL1
      .where(
        (l1) => l1.token.reading != null && !claimedForReading.contains(l1),
      )
      .toList();
  String? reading = sudachi.reading;
  if (availableForReading.isNotEmpty) {
    final chosen = _greatestOverlap(availableForReading, sudachiSpan);
    reading = chosen.token.reading;
    claimedForReading.add(chosen);
  }

  final rects = overlappingL1
      .map((l1) => l1.token.sourceRect)
      .whereType<SourceRect>()
      .toList();
  final sourceRect = rects.isEmpty ? null : _union(rects);

  final confidences = overlappingL1
      .map((l1) => l1.token.confidence)
      .whereType<double>()
      .toList();
  final confidence = confidences.isEmpty
      ? null
      : confidences.reduce((a, b) => a < b ? a : b);

  return sudachi.copyWith(
    reading: reading,
    sourceRect: sourceRect,
    confidence: confidence,
  );
}

_Span _greatestOverlap(List<_Span> candidates, _Span sudachiSpan) {
  var best = candidates.first;
  var bestOverlap = _overlapLength(best, sudachiSpan);
  for (final candidate in candidates.skip(1)) {
    final overlap = _overlapLength(candidate, sudachiSpan);
    if (overlap > bestOverlap) {
      best = candidate;
      bestOverlap = overlap;
    }
  }
  return best;
}

int _overlapLength(_Span a, _Span b) {
  final start = a.start > b.start ? a.start : b.start;
  final end = a.end < b.end ? a.end : b.end;
  return end > start ? end - start : 0;
}

SourceRect _union(List<SourceRect> rects) {
  var minX = rects.first.x;
  var minY = rects.first.y;
  var maxX = rects.first.x + rects.first.width;
  var maxY = rects.first.y + rects.first.height;
  for (final rect in rects.skip(1)) {
    if (rect.x < minX) minX = rect.x;
    if (rect.y < minY) minY = rect.y;
    if (rect.x + rect.width > maxX) maxX = rect.x + rect.width;
    if (rect.y + rect.height > maxY) maxY = rect.y + rect.height;
  }
  return SourceRect(
    pageIndex: rects.first.pageIndex,
    x: minX,
    y: minY,
    width: maxX - minX,
    height: maxY - minY,
    pageWidth: rects.first.pageWidth,
    pageHeight: rects.first.pageHeight,
  );
}
