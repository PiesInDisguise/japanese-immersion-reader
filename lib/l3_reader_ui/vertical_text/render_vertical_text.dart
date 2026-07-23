import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'vertical_text_layout.dart';

/// Paints text as top-to-bottom, right-to-left columns (縦書き) and resolves
/// taps to a character index using the exact same [VerticalTextLayout] it
/// just painted with -- so hit-testing can never drift from what's actually
/// on screen.
///
/// A leaf render object (no children) -- Flutter has no built-in vertical
/// writing-mode support, which is exactly why this spike exists (see
/// docs/spec.md §4/§16). Prefer `VerticalTextView` (in `vertical_text_view.dart`)
/// over using this directly; it wraps this render object with explicit
/// sizing.
///
/// **Why this owns a [TapGestureRecognizer] directly, instead of a
/// [GestureDetector] widget wrapping it:** an earlier version of this spike
/// used a `GestureDetector` around this render object, with the tap handler
/// building its own separate [VerticalTextLayout] from the *widget's*
/// declared size. That drifted from what this render object actually
/// painted whenever the real layout constraints it received didn't match
/// the widget's declared size (e.g. an ambient tight/incompatible parent
/// constraint -- a real, easy-to-hit case, not a corner case: it's exactly
/// what happens if this widget is ever placed under something that forces
/// its own size, and it's precisely the kind of thing that only shows up as
/// mis-registered taps in manual QA, not a test failure -- the same shape of
/// risk `lib/core/models/source_rect.dart`'s coordinate-convention doc
/// comment and docs/research/r2-pdf-text.md's y-origin finding both flag).
/// Owning the recognizer here and resolving hits against [_layout] (the
/// literal same value [paint] used) makes that class of drift structurally
/// impossible rather than relying on two call sites agreeing. This mirrors
/// how `RenderEditable` (`package:flutter/src/rendering/editable.dart`)
/// manages its own `TapGestureRecognizer`/`LongPressGestureRecognizer` for
/// the same reason: tight coordination between text layout and gestures.
///
/// Always sized exactly to its incoming [BoxConstraints] (expected to be
/// bounded, ideally tight -- `VerticalTextView` wraps this in a [SizedBox]
/// to guarantee that). Text that doesn't fit within that size is simply not
/// painted past the last column that fits; this spike does not scroll or
/// paginate overflow (see `VerticalTextView`'s doc comment for why that's
/// out of scope here).
class RenderVerticalText extends RenderBox {
  RenderVerticalText({
    required this._text,
    required this._textStyle,
    required this._fontSize,
    required this._lineHeightFactor,
    required this._columnSpacingFactor,
    this._onCharacterTapped,
  }) {
    _tap = TapGestureRecognizer(debugOwner: this)..onTapUp = _handleTapUp;
  }

  String _text;
  String get text => _text;
  set text(String value) {
    if (_text == value) return;
    _text = value;
    markNeedsLayout();
  }

  TextStyle _textStyle;
  TextStyle get textStyle => _textStyle;
  set textStyle(TextStyle value) {
    if (_textStyle == value) return;
    _textStyle = value;
    // Style alone doesn't change the grid -- fontSize (below) is the
    // separate knob that does -- so this only needs a repaint.
    markNeedsPaint();
  }

  double _fontSize;
  double get fontSize => _fontSize;
  set fontSize(double value) {
    if (_fontSize == value) return;
    _fontSize = value;
    markNeedsLayout();
  }

  double _lineHeightFactor;
  double get lineHeightFactor => _lineHeightFactor;
  set lineHeightFactor(double value) {
    if (_lineHeightFactor == value) return;
    _lineHeightFactor = value;
    markNeedsLayout();
  }

  double _columnSpacingFactor;
  double get columnSpacingFactor => _columnSpacingFactor;
  set columnSpacingFactor(double value) {
    if (_columnSpacingFactor == value) return;
    _columnSpacingFactor = value;
    markNeedsLayout();
  }

  /// Called with a character's index into [text] when a tap resolves to
  /// one; see [_handleTapUp].
  ValueChanged<int>? _onCharacterTapped;
  set onCharacterTapped(ValueChanged<int>? value) => _onCharacterTapped = value;

  late final TapGestureRecognizer _tap;

  /// The layout computed by the most recent [performLayout]; used by both
  /// [paint] and [_handleTapUp]. Rebuilt from scratch on every layout pass
  /// -- cheap immutable arithmetic, no need to diff against the previous
  /// value.
  VerticalTextLayout? _layout;

  /// One [TextPainter] per character, index-aligned with [_layout]'s text,
  /// built alongside it in [performLayout] and reused across repeated
  /// [paint] calls (e.g. from an ancestor repainting for unrelated reasons)
  /// rather than reallocated every frame.
  List<TextPainter>? _textPainters;

  VerticalTextLayout _layoutFor(BoxConstraints constraints) =>
      VerticalTextLayout(
        text: _text,
        fontSize: _fontSize,
        viewportSize: constraints.biggest,
        lineHeightFactor: _lineHeightFactor,
        columnSpacingFactor: _columnSpacingFactor,
      );

  void _disposeTextPainters() {
    final painters = _textPainters;
    if (painters == null) return;
    for (final painter in painters) {
      painter.dispose();
    }
    _textPainters = null;
  }

  void _handleTapUp(TapUpDetails details) {
    final index = _layout?.hitTest(details.localPosition);
    if (index != null) {
      _onCharacterTapped?.call(index);
    }
  }

  @override
  void performLayout() {
    assert(
      constraints.hasBoundedWidth && constraints.hasBoundedHeight,
      'RenderVerticalText requires bounded constraints so it knows how many '
      'characters fit per column; wrap it in a SizedBox (VerticalTextView '
      'does this for you).',
    );
    final layout = _layoutFor(constraints);
    _layout = layout;

    _disposeTextPainters();
    _textPainters = [
      for (var i = 0; i < _text.length; i++)
        TextPainter(
          text: TextSpan(text: _text[i], style: _textStyle),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];

    size = constraints.constrain(layout.viewportSize);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
      return constraints.smallest;
    }
    return constraints.constrain(_layoutFor(constraints).viewportSize);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final layout = _layout;
    final painters = _textPainters;
    if (layout == null || painters == null) return;
    for (var i = 0; i < painters.length; i++) {
      final painter = painters[i];
      final rect = layout.rectForChar(i).shift(offset);
      // Center each glyph within its cell.
      final dx = rect.left + (rect.width - painter.width) / 2;
      final dy = rect.top + (rect.height - painter.height) / 2;
      painter.paint(context.canvas, Offset(dx, dy));
    }
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      _tap.addPointer(event);
    }
  }

  @override
  void dispose() {
    _tap.dispose();
    _disposeTextPainters();
    super.dispose();
  }
}

/// The [LeafRenderObjectWidget] that plugs [RenderVerticalText] into the
/// widget tree. An internal building block -- public only because
/// `vertical_text_view.dart` needs to construct it from another file; it is
/// deliberately not re-exported from `vertical_text.dart`'s public barrel.
/// External callers should use `VerticalTextView`, which wraps this with
/// explicit sizing.
class RawVerticalText extends LeafRenderObjectWidget {
  const RawVerticalText({
    super.key,
    required this.text,
    required this.textStyle,
    required this.fontSize,
    required this.lineHeightFactor,
    required this.columnSpacingFactor,
    this.onCharacterTapped,
  });

  final String text;
  final TextStyle textStyle;
  final double fontSize;
  final double lineHeightFactor;
  final double columnSpacingFactor;
  final ValueChanged<int>? onCharacterTapped;

  @override
  RenderVerticalText createRenderObject(BuildContext context) {
    return RenderVerticalText(
      text: text,
      textStyle: textStyle,
      fontSize: fontSize,
      lineHeightFactor: lineHeightFactor,
      columnSpacingFactor: columnSpacingFactor,
      onCharacterTapped: onCharacterTapped,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderVerticalText renderObject,
  ) {
    renderObject
      ..text = text
      ..textStyle = textStyle
      ..fontSize = fontSize
      ..lineHeightFactor = lineHeightFactor
      ..columnSpacingFactor = columnSpacingFactor
      ..onCharacterTapped = onCharacterTapped;
  }
}
