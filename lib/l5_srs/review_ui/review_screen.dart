import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/app/services.dart';
import 'package:japanese_immersion_reader/app/settings_repository.dart';

import 'review_controller.dart';

/// Spec §12's review deck screen: one due card at a time, recognition-style
/// (front, then reveal the back + source-sentence context), rated via the
/// four standard FSRS grades -- by tapping a button, a keyboard digit
/// (1=Again/2=Hard/3=Good/4=Easy), or (per-direction-toggleable, see
/// `AppSettings.reviewSwipeUpEnabled` and friends) a swipe.
class ReviewScreen extends ConsumerWidget {
  /// [workId] is `null` for spec's "All" deck, or a document id to scope
  /// this session to just that book -- see [reviewControllerProvider]'s own
  /// doc comment. [deckTitle] is purely cosmetic (the app bar's base label,
  /// e.g. a book's title) and doesn't affect which deck loads; omit it to
  /// fall back to the plain "Review" label [ReviewDeckPickerScreen]'s own
  /// "All" tile uses.
  const ReviewScreen({super.key, this.workId, this.deckTitle});

  final String? workId;
  final String? deckTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(reviewControllerProvider(workId));
    final settings =
        ref.watch(appSettingsProvider).value ?? AppSettings.defaults;

    return Scaffold(
      appBar: AppBar(title: Text(_titleFor(asyncState))),
      body: SafeArea(
        child: asyncState.when(
          data: (state) =>
              _ReviewBody(workId: workId, state: state, settings: settings),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('$error', textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }

  String _titleFor(AsyncValue<ReviewQueueState> value) {
    final base = deckTitle ?? 'Review';
    return value.maybeWhen(
      data: (state) =>
          state.isComplete ? base : '$base (${state.remaining} left)',
      orElse: () => base,
    );
  }
}

/// Which direction a swipe/keyboard press maps to -- a fixed mapping (not
/// user-configurable; only whether each swipe direction is *live* at all is,
/// via [AppSettings.reviewSwipeUpEnabled] and its three siblings).
enum _SwipeDirection { up, down, left, right }

Rating _ratingForSwipe(_SwipeDirection direction) => switch (direction) {
  _SwipeDirection.up => Rating.easy,
  _SwipeDirection.right => Rating.good,
  _SwipeDirection.left => Rating.hard,
  _SwipeDirection.down => Rating.again,
};

class _ReviewBody extends ConsumerStatefulWidget {
  const _ReviewBody({
    required this.workId,
    required this.state,
    required this.settings,
  });

  final String? workId;
  final ReviewQueueState state;
  final AppSettings settings;

  @override
  ConsumerState<_ReviewBody> createState() => _ReviewBodyState();
}

class _ReviewBodyState extends ConsumerState<_ReviewBody> {
  // Same swipe-threshold reasoning as Card Mode's `_CardAreaState` -- well
  // above Flutter's own touch-slop, so a tap-with-jitter never reads as a
  // swipe.
  static const _swipeThreshold = 60.0;

  double _dragDx = 0;
  double _dragDy = 0;
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _rate(Rating rating) =>
      ref.read(reviewControllerProvider(widget.workId).notifier).rate(rating);

  bool _directionEnabled(_SwipeDirection direction) => switch (direction) {
    _SwipeDirection.up => widget.settings.reviewSwipeUpEnabled,
    _SwipeDirection.down => widget.settings.reviewSwipeDownEnabled,
    _SwipeDirection.left => widget.settings.reviewSwipeLeftEnabled,
    _SwipeDirection.right => widget.settings.reviewSwipeRightEnabled,
  };

  void _handlePanUpdate(DragUpdateDetails details) {
    _dragDx += details.delta.dx;
    _dragDy += details.delta.dy;
  }

  void _handlePanEnd(DragEndDetails details) {
    final dx = _dragDx;
    final dy = _dragDy;
    _dragDx = 0;
    _dragDy = 0;
    if (!widget.state.isRevealed) return;

    final absDx = dx.abs();
    final absDy = dy.abs();
    if (absDx < _swipeThreshold && absDy < _swipeThreshold) return;

    // Whichever axis moved further decides the direction -- a swipe is
    // rarely purely horizontal or vertical, so this picks the one the user
    // clearly meant rather than requiring an exact axis-aligned drag.
    final direction = absDx > absDy
        ? (dx > 0 ? _SwipeDirection.right : _SwipeDirection.left)
        : (dy > 0 ? _SwipeDirection.down : _SwipeDirection.up);
    if (!_directionEnabled(direction)) return;
    _rate(_ratingForSwipe(direction));
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !widget.state.isRevealed) {
      return KeyEventResult.ignored;
    }
    final rating = switch (event.logicalKey) {
      LogicalKeyboardKey.digit1 || LogicalKeyboardKey.numpad1 => Rating.again,
      LogicalKeyboardKey.digit2 || LogicalKeyboardKey.numpad2 => Rating.hard,
      LogicalKeyboardKey.digit3 || LogicalKeyboardKey.numpad3 => Rating.good,
      LogicalKeyboardKey.digit4 || LogicalKeyboardKey.numpad4 => Rating.easy,
      _ => null,
    };
    if (rating == null) return KeyEventResult.ignored;
    _rate(rating);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state.cards.isEmpty || state.isComplete) {
      return const _EmptyState();
    }

    final card = state.current!;
    final theme = Theme.of(context);

    // Spec's "show sentence on front" setting only ever applies to word
    // cards with a real context sentence -- grammar cards have no single
    // matching span to show/highlight (see `ReviewCard.frontHighlightStart`'s
    // own doc comment), so they always fall back to the plain pattern text.
    final showSentenceOnFront =
        widget.settings.reviewShowSentenceOnFront &&
        card.kind == ReviewCardKind.word &&
        card.contextSentence != null;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showSentenceOnFront)
                          _HighlightedSentence(
                            sentence: card.contextSentence!,
                            highlightStart: card.frontHighlightStart,
                            highlightEnd: card.frontHighlightEnd,
                            style: theme.textTheme.headlineSmall,
                          )
                        else
                          Text(
                            card.front,
                            style: theme.textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                        if (state.isRevealed) ...[
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            card.back,
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          // Not repeated here when it's already shown
                          // (highlighted) up on the front -- showing the
                          // exact same sentence twice on one card is just
                          // noise.
                          if (card.contextSentence != null &&
                              !showSentenceOnFront) ...[
                            const SizedBox(height: 20),
                            _OriginalSentenceSection(
                              sentence: card.contextSentence!,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (!state.isRevealed)
                FilledButton(
                  onPressed: () => ref
                      .read(reviewControllerProvider(widget.workId).notifier)
                      .reveal(),
                  child: const Text('Show answer'),
                )
              else
                _RatingButtons(onRate: _rate),
            ],
          ),
        ),
      ),
    );
  }
}

/// The reveal-side original-sentence display -- a proper section (label +
/// prominent body text), not the small italic/muted caption this used to
/// be, which was too easy to overlook entirely.
class _OriginalSentenceSection extends StatelessWidget {
  const _OriginalSentenceSection({required this.sentence});

  final String sentence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'ORIGINAL SENTENCE',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          sentence,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Renders [sentence] with `[highlightStart, highlightEnd)` styled as the
/// reviewed word, when both are non-null -- otherwise just the plain
/// sentence text (the "couldn't relocate the word" fallback
/// `ReviewController.build` documents).
class _HighlightedSentence extends StatelessWidget {
  const _HighlightedSentence({
    required this.sentence,
    required this.highlightStart,
    required this.highlightEnd,
    required this.style,
  });

  final String sentence;
  final int? highlightStart;
  final int? highlightEnd;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final start = highlightStart;
    final end = highlightEnd;
    if (start == null || end == null) {
      return Text(sentence, style: style, textAlign: TextAlign.center);
    }
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: sentence.substring(0, start)),
          TextSpan(
            text: sentence.substring(start, end),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
              decorationColor: theme.colorScheme.primary,
            ),
          ),
          TextSpan(text: sentence.substring(end)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _RatingButtons extends StatelessWidget {
  const _RatingButtons({required this.onRate});

  final ValueChanged<Rating> onRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => onRate(Rating.again),
            child: const Text('Again'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => onRate(Rating.hard),
            child: const Text('Hard'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            onPressed: () => onRate(Rating.good),
            child: const Text('Good'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            onPressed: () => onRate(Rating.easy),
            child: const Text('Easy'),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('All caught up!', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Nothing is due for review right now.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
