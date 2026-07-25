import 'package:japanese_immersion_reader/core/models/models.dart';

/// Maps a UTF-16 code-unit index into a sentence's flattened surface text
/// (`tokens.map((t) => t.surface).join()`, i.e. `Sentence.surfaceText`) back
/// to the index, into [tokens], of whichever token's surface span contains
/// it.
///
/// This is the missing piece `VerticalTextView`/`VerticalTextLayout` (see
/// `vertical_text_layout.dart`'s doc comment) explicitly punts on: it only
/// ever hands back a raw character index into the flat `String` it was
/// given, with no notion of `Token`/`Sentence` at all. `Token`
/// (`core/models/token.dart`) has no stable `id` field to map a char index
/// to directly, so the most specific identity available is a *list index*
/// into the exact same `tokens` list the caller already has in hand (e.g.
/// from `DocumentModeController.tokensFor`) -- good enough, since all a
/// resolved tap/long-press needs is "which `Token` object", and the caller
/// already holds that list for the current render pass; nothing here needs
/// to survive across re-tokenization or persist anywhere.
///
/// Built once per `tokens` list, as a prefix sum over each token's
/// `surface.length`, and reused across however many taps land on the same
/// sentence, rather than rescanning the whole list on every tap.
class TokenSpanIndex {
  TokenSpanIndex(this.tokens) : _starts = _buildStarts(tokens);

  final List<Token> tokens;

  /// `_starts[i]` is the char index -- into the flattened, joined surface
  /// text -- where `tokens[i]`'s surface begins. Strictly non-decreasing;
  /// strictly increasing as long as no token has an empty surface (the
  /// normal case for every real tokenizer/importer in this codebase).
  final List<int> _starts;

  static List<int> _buildStarts(List<Token> tokens) {
    final starts = List<int>.filled(tokens.length, 0, growable: false);
    var offset = 0;
    for (var i = 0; i < tokens.length; i++) {
      starts[i] = offset;
      offset += tokens[i].surface.length;
    }
    return starts;
  }

  /// The index into [tokens] whose surface span contains [charIndex].
  ///
  /// [charIndex] is expected to be a valid index into [tokens]' own joined
  /// surface text -- in practice, always straight from a
  /// `VerticalTextLayout.hitTest`/`rectForChar` call made against exactly
  /// this [tokens] list's joined surface (see `VerticalSentenceView`, the
  /// one caller of this class), which only ever produces in-range indices
  /// (`hitTest` returns `null`, not an out-of-range int, for a miss -- see
  /// its own doc comment). Throws [RangeError] if [charIndex] nonetheless
  /// falls outside every token's span -- a caller bug (e.g. passing an
  /// index derived from a *different* string than these tokens' own joined
  /// surface), not a normal "the user tapped empty space" case.
  int tokenIndexForCharIndex(int charIndex) {
    final lastIndex = tokens.length - 1;
    if (tokens.isEmpty || charIndex < 0) {
      throw RangeError.value(charIndex, 'charIndex', 'no token at this index');
    }

    // Binary search for the last start <= charIndex.
    var lo = 0;
    var hi = lastIndex;
    var candidate = -1;
    while (lo <= hi) {
      final mid = lo + ((hi - lo) >> 1);
      if (_starts[mid] <= charIndex) {
        candidate = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }

    if (candidate == -1) {
      throw RangeError.value(charIndex, 'charIndex', 'no token at this index');
    }
    final spanEnd = _starts[candidate] + tokens[candidate].surface.length;
    if (charIndex >= spanEnd) {
      throw RangeError.value(charIndex, 'charIndex', 'no token at this index');
    }
    return candidate;
  }

  /// The reverse of [tokenIndexForCharIndex]: the half-open char-index range
  /// `[start, end)`, into the same flattened surface text, that
  /// `tokens[tokenIndex]` occupies. Used by the word-highlighting feature
  /// (`VerticalSentenceView`) to turn "this token is a collected word" into
  /// the set of char indices `RenderVerticalText` should paint a highlight
  /// background behind.
  (int start, int end) charRangeForToken(int tokenIndex) {
    final start = _starts[tokenIndex];
    return (start, start + tokens[tokenIndex].surface.length);
  }
}
