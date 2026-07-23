/// A half-open `[start, end)` character range into some source text,
/// identifying one L1-level sentence span.
class SentenceSpan {
  const SentenceSpan(this.start, this.end);

  final int start;
  final int end;
}

const _terminators = {'。', '！', '？', '…', '‥', '.', '!', '?'};

// Explicit \u{} escapes deliberately, not literal glyphs: several of these
// look near-identical in an editor, and a copy-paste slip previously put
// the same codepoint in twice in an earlier version of this file, which
// `const Set` silently can't represent (duplicate-element compile error).
const _openBrackets = {
  '\u{300C}', // 「 CJK left corner bracket
  '\u{300E}', // 『 CJK left white corner bracket
  '\u{0028}', // ( left parenthesis
  '\u{FF08}', // （ fullwidth left parenthesis
};

const _closeBrackets = {
  '\u{300D}', // 」 CJK right corner bracket
  '\u{300F}', // 』 CJK right white corner bracket
  '\u{0029}', // ) right parenthesis
  '\u{FF09}', // ） fullwidth right parenthesis
};

// Quote glyphs that use the same character for open and close (so they
// can't be depth-tracked unambiguously) are rare in Japanese prose, which
// conventionally uses the bracket pairs above instead. Treated as a lighter
// "still part of the sentence that just ended" trailing skip rather than
// full depth-tracking.
const _trailingQuoteMarks = {
  '\u{201D}', // " right double quotation mark
  '\u{2019}', // ' right single quotation mark
  '\u{0022}', // " straight double quote
};

/// Coarse, mechanical L1 sentence-boundary splitting: cuts after a
/// terminator (。！？…, plus ASCII .!?), but only when it's not nested
/// inside an open 「」/『』/() bracket — so quoted dialogue followed by an
/// attribution clause (e.g. `「大丈夫？」と彼女に聞いた。`) stays one sentence,
/// since the ？ is inside the quote and only the final 。 is at bracket
/// depth 0. This is deliberately NOT linguistic — it exists so L1 importers
/// can produce `Sentence` nodes with stable IDs at all. Card Mode's
/// clause-level splitting (spec §6, driven by Sudachi in L2) is a separate,
/// later, presentation-time concern layered on top of whatever sentences
/// this produces; it does not change where L1 draws these boundaries.
///
/// Returns spans covering the entire input with no gaps (any trailing
/// unterminated text becomes a final span), and never an empty span for
/// non-empty input. Returns `[]` for empty or whitespace-only input.
List<SentenceSpan> splitIntoSentenceSpans(String text) {
  final spans = <SentenceSpan>[];
  var start = 0;
  var depth = 0;
  var i = 0;

  while (i < text.length) {
    final char = text[i];
    if (_openBrackets.contains(char)) {
      depth++;
      i++;
    } else if (_closeBrackets.contains(char)) {
      if (depth > 0) depth--;
      i++;
    } else if (depth == 0 && _terminators.contains(char)) {
      var end = i + 1;
      while (end < text.length &&
          (_closeBrackets.contains(text[end]) ||
              _trailingQuoteMarks.contains(text[end]))) {
        end++;
      }
      spans.add(SentenceSpan(start, end));
      start = end;
      i = end;
    } else {
      i++;
    }
  }

  if (start < text.length) {
    spans.add(SentenceSpan(start, text.length));
  }

  return spans
      .where((s) => text.substring(s.start, s.end).trim().isNotEmpty)
      .toList(growable: false);
}
