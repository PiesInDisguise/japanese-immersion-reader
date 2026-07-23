import 'package:flutter/widgets.dart';

import 'render_vertical_text.dart';
import 'vertical_text_layout.dart';

/// A hardcoded sample of vertical Japanese prose for this rendering spike --
/// the opening lines of Natsume Sōseki's *Wagahai wa Neko de Aru* (1905,
/// public domain), the same source text the R2 PDF-text-layer research
/// spike used for its own fixtures (see docs/research/r2-pdf-text.md §2 and
/// `assets/fixtures/synthetic_horizontal_ja.pdf`). 33 characters -- enough
/// to wrap across several columns at a normal reading font size in a
/// phone-sized viewport.
///
/// This spike has no `Document`/`Token`/`Sentence` model integration (see
/// docs/spec.md §3-4, §16): a real integration replaces this hardcoded
/// constant with text sourced from L1 ingestion.
const String sampleVerticalText =
    '吾輩は猫である。名前はまだ無い。'
    'どこで生れたかとんと見当がつかぬ。';

/// Renders [text] as top-to-bottom, right-to-left columns (縦書き) within a
/// fixed [size], and resolves taps to a character index via
/// [onCharacterTapped].
///
/// Tap handling is done by [RenderVerticalText] itself (via its own
/// [TapGestureRecognizer], not a separate `GestureDetector` widget), so the
/// character a tap resolves to can never drift from what was actually
/// painted -- see that class's doc comment for why that distinction matters.
///
/// This is a standalone rendering/hit-testing spike (docs/spec.md §4, §16),
/// deliberately narrow in scope -- worth flagging explicitly for whoever
/// does the real Document-Mode integration later:
///
///  * No dictionary lookup, no real `Document`/`Token` model integration, no
///    navigation. [text] is just a `String`; a real integration needs a
///    mapping from character index back to `Token`/`Sentence` IDs (so a
///    resolved tap can drive lookup/mining), which is out of scope here.
///  * [size] is required and is what this widget *requests* of the layout
///    system (via an internal [SizedBox]) -- but per ordinary Flutter box
///    layout rules, an incompatible ambient constraint (e.g. a tight parent
///    forcing a different size) can still force the actually-rendered size
///    to differ from it. Callers must embed this somewhere that actually
///    grants [size] (a [Center], a scroll view, or similar) -- the same
///    requirement any fixed-size content widget has. Unlike the sizing
///    itself, hit-testing is safe either way: it's resolved from
///    [RenderVerticalText]'s own real layout, not from this field, so a tap
///    always matches whatever was actually painted (see that class's doc
///    comment). [text] not fitting [size] at all is a separate, simpler
///    case: it's simply not painted past the last column that fits -- there
///    is no scrolling or pagination. A real reader would need one.
///  * Text scaling (accessibility font-size settings) is not accounted for:
///    [fontSize] sizes both the layout grid and (via [textStyle]) the
///    painted glyphs, but nothing here reads `MediaQuery`'s text scaler. A
///    real integration needs to decide how user text-scale preferences
///    interact with the fixed per-character grid.
///  * Every character occupies a uniform cell sized from [fontSize] alone,
///    not measured per-glyph -- see [VerticalTextLayout]'s doc comment.
class VerticalTextView extends StatelessWidget {
  const VerticalTextView({
    super.key,
    required this.text,
    required this.size,
    this.fontSize = 24.0,
    this.lineHeightFactor = 1.6,
    this.columnSpacingFactor = 1.6,
    this.textStyle,
    this.onCharacterTapped,
  });

  /// The source string to lay out, already in correct 縦書き reading order
  /// (see [VerticalTextLayout]'s class doc).
  final String text;

  /// The fixed viewport this view lays [text] out into. See the class doc
  /// on why this is explicit rather than derived from layout constraints.
  final Size size;

  /// Font size in logical pixels. Also drives the layout grid's cell size --
  /// see [VerticalTextLayout.fontSize].
  final double fontSize;

  /// Forwarded to [VerticalTextLayout.lineHeightFactor].
  final double lineHeightFactor;

  /// Forwarded to [VerticalTextLayout.columnSpacingFactor].
  final double columnSpacingFactor;

  /// Base style for painted glyphs. This style's `fontSize` is overridden by
  /// [fontSize] unconditionally, so the layout grid and the painted text can
  /// never disagree about character size.
  final TextStyle? textStyle;

  /// Called with a character's index into [text] when a tap resolves to one.
  /// Not called if a tap doesn't land on any character (see
  /// [VerticalTextLayout.hitTest]).
  final ValueChanged<int>? onCharacterTapped;

  /// The layout math [RenderVerticalText] computes internally *when it
  /// achieves exactly [size]* -- exposed here purely so tests (and future
  /// callers) can reason about expected character positions without pumping
  /// a widget tree. This is an informational mirror, not the mechanism real
  /// hit-testing uses (see the class doc): if the actual render object ends
  /// up a different size than [size] (see the class doc's note on ambient
  /// constraints), this getter and the real painted layout will disagree,
  /// same as [VerticalTextLayout] built with two different `viewportSize`s
  /// always would.
  VerticalTextLayout get layout => VerticalTextLayout(
    text: text,
    fontSize: fontSize,
    viewportSize: size,
    lineHeightFactor: lineHeightFactor,
    columnSpacingFactor: columnSpacingFactor,
  );

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (textStyle ?? const TextStyle()).copyWith(
      fontSize: fontSize,
    );
    return SizedBox(
      width: size.width,
      height: size.height,
      child: RawVerticalText(
        text: text,
        textStyle: effectiveStyle,
        fontSize: fontSize,
        lineHeightFactor: lineHeightFactor,
        columnSpacingFactor: columnSpacingFactor,
        onCharacterTapped: onCharacterTapped,
      ),
    );
  }
}
