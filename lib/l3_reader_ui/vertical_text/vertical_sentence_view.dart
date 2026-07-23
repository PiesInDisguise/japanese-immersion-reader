import 'package:flutter/material.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';

import 'token_span_index.dart';
import 'vertical_text_layout.dart';
import 'vertical_text_view.dart';

/// Renders one sentence's real, tokenized content vertically (縦書き) --
/// `VerticalTextView` hardened for real `Sentence`/`Token` data, with the
/// same tap/long-press/double-tap semantics Document Mode's horizontal
/// `_SentenceRowView` already has (`document_mode_screen.dart`): tap a token
/// to look it up, long-press a token to remove it from the collection,
/// double-tap anywhere in the sentence for a grammar breakdown of the whole
/// thing. [tokens] should be a sentence's real, already-reconciled tokens
/// (e.g. from `DocumentModeController.tokensFor`), in order.
///
/// **Sizing: why this doesn't just take a fixed viewport.** `VerticalTextView`
/// simply doesn't paint text past whatever `size` it's given (see its own
/// doc comment) -- fine for a spike, unacceptable for a real reader, which
/// must never silently drop characters. Rather than picking a fixed width
/// and risking exactly that, this widget only fixes the *height* of one
/// column (`columnHeight`) and lets `VerticalTextLayout.contentSize` say how
/// wide the sentence actually needs to be (more columns for a longer
/// sentence) -- then honors that width in full via a horizontally-scrolling
/// `SingleChildScrollView` rather than clipping it. This is the vertical
/// analogue of `_SentenceRowView`'s horizontal `Wrap`, which sizes itself to
/// content and lets the *outer* `ListView.builder` scroll -- but 縦書き's
/// natural growth axis (more columns = wider) runs perpendicular to that
/// outer list's own scroll axis (vertical, across rows), not parallel to it
/// the way a `Wrap`'s height growth is, so relying on the outer list alone
/// cannot expose overflow along *this* axis. Hence the extra, row-local
/// horizontal scroll view: the outer list still scrolls vertically across
/// sentences exactly as before, while a single wide vertical sentence gets
/// its own horizontal scroll for its columns. `reverse: true` on that inner
/// scroll view starts it at the *right* edge (where column 0 -- the start of
/// 縦書き reading order -- always sits), so the sentence's beginning is what's
/// initially in view, not its end.
///
/// This sizing strategy also matters for hit-testing, not just visuals --
/// see the gesture-layering doc comment below.
///
/// **Gesture layering -- deliberately different from
/// `_SentenceRowView`'s single shared `GestureDetector`, and worth spelling
/// out why:**
///
/// `_SentenceRowView` puts tap/double-tap/long-press on *one*
/// `GestureDetector` per token, because with plain `Text` widgets that's the
/// only way for Flutter's gesture arena to see every recognizer that might
/// claim the same pointer sequence and disambiguate between them. That
/// option isn't available here: `VerticalTextView` paints every character
/// itself (`RenderVerticalText` is a leaf render object, no child widgets
/// per glyph) and deliberately owns its *own* `TapGestureRecognizer`
/// internally rather than exposing one a `GestureDetector` could merge with
/// (see `render_vertical_text.dart`'s doc comment: an earlier version tried
/// a separate `GestureDetector` for taps too, and it drifted from what was
/// actually painted whenever ambient constraints didn't match the widget's
/// declared size). So single-character tap resolution has to stay exactly
/// where it already lives -- `VerticalTextView.onCharacterTapped` -- since
/// that is the *only* hit-testing path guaranteed to agree with what
/// `RenderVerticalText` actually painted.
///
/// Double-tap and long-press, `VerticalTextView` has no equivalent hook for
/// at all, so this widget wraps it in its own `GestureDetector` for exactly
/// those two, leaving single-tap alone. This is *not* the same
/// "one-GestureDetector-per-pointer-sequence" shape `_SentenceRowView` uses,
/// but Flutter's gesture arena resolves competing recognizers by which
/// pointer they're attached to, not by tree position: a descendant's own
/// recognizer (`RenderVerticalText`'s internal tap recognizer) and an
/// ancestor `GestureDetector`'s recognizers all see the same
/// `PointerDownEvent` via hit-testing and enter the *same* arena for that
/// pointer, the same way, say, a `ListView`'s own drag recognizer and a
/// descendant's `onTap` already coexist correctly today. Concretely: a
/// `DoubleTapGestureRecognizer` anywhere in an arena holds that arena open
/// past the ordinary tap-resolution point until `kDoubleTapTimeout` elapses
/// or a second tap confirms it -- so a lone tap here is delayed by exactly
/// the same window `_SentenceRowView`'s own tests already have to pump past,
/// even though the competing recognizers live on two different widgets
/// instead of one. A `LongPressGestureRecognizer` that wins via its own
/// timeout gets the same priority over the still-pending tap recognizer
/// that it would if they were siblings. None of this is a hopeful hack --
/// it's what the arena is *for* -- but it does mean this widget's own
/// tap/double-tap/long-press tests need the same "pump past the timeout"
/// care `document_mode_screen_test.dart` documents for the horizontal case.
///
/// Long-press *does* need to know which character was pressed (unlike
/// double-tap, which always reports the whole sentence regardless of
/// position, mirroring `_SentenceRowView`'s own
/// `onSentenceDoubleTap`). Resolving that position reuses
/// `VerticalTextView.layout` -- the same "mirrors the *declared* size, not
/// necessarily what was actually painted" accessor that widget's own doc
/// comment flags -- rather than hand-building a second, possibly-different
/// `VerticalTextLayout`. That's safe here specifically *because* of the
/// sizing strategy above: this widget always constructs `VerticalTextView`
/// with `size` set to the exact `contentSize` this same `build()` call
/// already computed, and the surrounding `SizedBox` (tight height) plus
/// horizontally-scrolling `SingleChildScrollView` (unbounded width in the
/// scroll direction) together guarantee the ambient constraints actually
/// grant that size in full -- so "declared" and "actually painted" cannot
/// diverge here. If this widget is ever re-embedded somewhere that doesn't
/// provide that guarantee, long-press resolution would silently drift from
/// tap resolution, exactly the class of risk `render_vertical_text.dart`
/// flags for its own earlier, less careful version -- worth re-checking
/// first if this widget's wrapping ever changes.
class VerticalSentenceView extends StatelessWidget {
  const VerticalSentenceView({
    super.key,
    required this.tokens,
    required this.onWordTap,
    required this.onWordLongPress,
    required this.onSentenceDoubleTap,
    this.columnHeight = 360.0,
    this.fontSize = 20.0,
    this.lineHeightFactor = 1.5,
    this.columnSpacingFactor = 1.5,
  });

  /// The sentence's real tokens, in order. Never empty in practice (see
  /// `Sentence`'s own doc comment), but an empty list degrades to rendering
  /// nothing rather than crashing.
  final List<Token> tokens;

  /// Tap a token -> look it up (mirrors `_SentenceRowView.onWordTap`).
  final ValueChanged<Token> onWordTap;

  /// Long-press a token -> remove it from the collection (mirrors
  /// `_SentenceRowView.onWordLongPress`).
  final ValueChanged<Token> onWordLongPress;

  /// Double-tap anywhere in the sentence -> grammar breakdown of every
  /// token in [tokens] (mirrors `_SentenceRowView.onSentenceDoubleTap`).
  final ValueChanged<List<Token>> onSentenceDoubleTap;

  /// How tall one column of text is, in logical pixels -- the one sizing
  /// input this widget picks for itself (see the class doc's "why this
  /// doesn't just take a fixed viewport"); everything else (how many
  /// columns, how wide) follows from [VerticalTextLayout.contentSize].
  /// Default gives 12 characters per column at the default [fontSize]/
  /// [lineHeightFactor] -- a reasonable middle ground, not a tuned value.
  final double columnHeight;

  /// Forwarded to `VerticalTextView.fontSize`. Defaults to 20 to match
  /// `_SentenceRowView`'s own token `TextStyle(fontSize: 20)`, so horizontal
  /// and vertical rows in the same document read at a consistent size.
  final double fontSize;

  /// Forwarded to `VerticalTextView.lineHeightFactor`. 1.5 (not the
  /// underlying spike's own default of 1.6) specifically because it's
  /// exactly representable as a double -- matching
  /// `vertical_text_view_test.dart`'s own fixture choice -- so this widget's
  /// column-height math never has floating-point round-off to worry about.
  final double lineHeightFactor;

  /// Forwarded to `VerticalTextView.columnSpacingFactor`. See
  /// [lineHeightFactor] for why 1.5.
  final double columnSpacingFactor;

  String get _text => tokens.map((t) => t.surface).join();

  @override
  Widget build(BuildContext context) {
    final text = _text;
    if (text.isEmpty) return const SizedBox.shrink();

    final tokenSpans = TokenSpanIndex(tokens);

    // contentSize depends only on `columnHeight` (via charsPerColumn) and
    // fontSize/lineHeightFactor/columnSpacingFactor -- never on the width
    // passed here -- see VerticalTextLayout.contentSize's own doc comment.
    // Reusing `columnHeight` for both dimensions of this probe is just a
    // convenient placeholder; the width is never read.
    final contentSize = VerticalTextLayout(
      text: text,
      fontSize: fontSize,
      viewportSize: Size(columnHeight, columnHeight),
      lineHeightFactor: lineHeightFactor,
      columnSpacingFactor: columnSpacingFactor,
    ).contentSize;

    // Explicit onSurface color: RenderVerticalText paints raw TextPainters
    // straight from this style (see render_vertical_text.dart), never going
    // through a Text/RichText widget that would otherwise pick up
    // DefaultTextStyle's theme-aware color for free the way
    // _SentenceRowView's plain Text tokens do.
    final theme = Theme.of(context);
    final verticalText = VerticalTextView(
      text: text,
      size: contentSize,
      fontSize: fontSize,
      lineHeightFactor: lineHeightFactor,
      columnSpacingFactor: columnSpacingFactor,
      textStyle: TextStyle(color: theme.colorScheme.onSurface),
      onCharacterTapped: (charIndex) =>
          onWordTap(tokens[tokenSpans.tokenIndexForCharIndex(charIndex)]),
    );

    void handleLongPressStart(LongPressStartDetails details) {
      final charIndex = verticalText.layout.hitTest(details.localPosition);
      if (charIndex == null) return;
      onWordLongPress(tokens[tokenSpans.tokenIndexForCharIndex(charIndex)]);
    }

    return SizedBox(
      height: contentSize.height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: GestureDetector(
          onDoubleTap: () => onSentenceDoubleTap(tokens),
          onLongPressStart: handleLongPressStart,
          child: verticalText,
        ),
      ),
    );
  }
}
