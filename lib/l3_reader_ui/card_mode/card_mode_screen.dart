import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';

import '../document_mode/document_mode_screen.dart';
import 'card_mode_controller.dart';
import 'token_gloss_view.dart';
import 'word_lookup_sheet.dart';

/// Card Mode's screen (spec §6): a vertical feed, one sentence per card,
/// built directly on [cardModeControllerProvider]. See that provider's own
/// scope-note doc comment for what's deliberately not implemented this pass
/// (drag-to-override the tokenizer boundary, grammar-point popups on the
/// flip side, and auto-add-OFF's +/- toggle).
class CardModeScreen extends ConsumerWidget {
  const CardModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(cardModeControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(asyncState)),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_agenda_outlined),
            tooltip: 'Switch to Document Mode',
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DocumentModeScreen()),
            ),
          ),
          if (asyncState.hasValue)
            IconButton(
              icon: const Icon(Icons.flip_camera_android_outlined),
              tooltip: 'Flip card',
              onPressed: () =>
                  ref.read(cardModeControllerProvider.notifier).toggleFlip(),
            ),
        ],
      ),
      body: SafeArea(
        child: asyncState.when(
          data: (state) => _CardModeBody(state: state),
          loading: () => const _LoadingView(),
          error: (error, stackTrace) => _ErrorView(error: error),
        ),
      ),
    );
  }

  String _titleFor(AsyncValue<CardModeState> value) {
    return value.maybeWhen(
      data: (state) => 'Card ${state.cardIndex + 1} of ${state.totalCards}',
      orElse: () => 'Card Mode',
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading tokenizer and dictionary…'),
        ],
      ),
    );
  }
}

/// Shown when [cardModeControllerProvider] fails to build -- most likely
/// `dictionary_paths.dart`'s placeholder resolver throwing a clear
/// [StateError] because no Sudachi dictionary is present on this device
/// yet (see that file's doc comment), but kept generic since any other
/// build-time failure should degrade the same way rather than crashing the
/// app.
class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text("Couldn't load this card", style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => ref.invalidate(cardModeControllerProvider),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardModeBody extends StatelessWidget {
  const _CardModeBody({required this.state});

  final CardModeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(child: _CardArea(state: state)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            'Swipe to turn pages  •  Tap a word to look it up  •  '
            'Long-press to remove  •  Tap the card to flip',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }
}

/// The swipeable, tappable card surface itself: front face is plain-text
/// tokens (spec §6: no underlines/tints regardless of collection state);
/// back face (`state.isFlipped`) is the token-gloss breakdown.
///
/// A [ConsumerStatefulWidget] rather than stateless because swipe detection
/// needs to accumulate drag distance across `onVerticalDragUpdate` calls
/// between one `onVerticalDragEnd`.
class _CardArea extends ConsumerStatefulWidget {
  const _CardArea({required this.state});

  final CardModeState state;

  @override
  ConsumerState<_CardArea> createState() => _CardAreaState();
}

class _CardAreaState extends ConsumerState<_CardArea> {
  // Chosen well above the touch-slop Flutter already applies before a drag
  // recognizer accepts, so a stray tap-with-jitter never reads as a swipe.
  static const _swipeThreshold = 60.0;

  double _dragAccumulator = 0;

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    _dragAccumulator += details.primaryDelta ?? 0;
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final controller = ref.read(cardModeControllerProvider.notifier);
    // Swipe up (negative dy) -> next card; swipe down (positive dy) ->
    // previous. `next`/`previous` already no-op sensibly at the ends
    // (CardModeState.hasNext/hasPrevious), so this never needs to check
    // those itself.
    if (_dragAccumulator <= -_swipeThreshold) {
      controller.next();
    } else if (_dragAccumulator >= _swipeThreshold) {
      controller.previous();
    }
    _dragAccumulator = 0;
  }

  Future<void> _handleWordTap(Token token) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(cardModeControllerProvider.notifier);
    final mined = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => WordLookupSheet(
        token: token,
        lookup: () => controller.lookupWord(token),
        mine: (senses) => controller.mineWord(token, senses),
      ),
    );
    if (mined == true && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Added "${token.surface}" to your collection'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () =>
                ref.read(cardModeControllerProvider.notifier).undoLastMining(),
          ),
        ),
      );
    }
  }

  Future<void> _handleWordLongPress(Token token) async {
    final messenger = ScaffoldMessenger.of(context);
    final identity = _collectionIdentity(token);
    await ref
        .read(cardModeControllerProvider.notifier)
        .removeWord(identity.dictForm, identity.reading);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Removed "${token.surface}" from your collection'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isFlipped = state.isFlipped;
    return GestureDetector(
      key: const Key('cardModeCardArea'),
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(cardModeControllerProvider.notifier).toggleFlip(),
      // Swipe-to-navigate is deliberately front-face-only: the back face
      // shows a scrollable token-gloss list, and a vertical drag recognizer
      // here would fight that list's own scroll gesture for the same
      // pointer. Tap-to-flip-back first, then swipe, is the escape hatch.
      onVerticalDragUpdate: isFlipped ? null : _handleVerticalDragUpdate,
      onVerticalDragEnd: isFlipped ? null : _handleVerticalDragEnd,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
                  child: child,
                ),
              ),
              child: isFlipped
                  ? TokenGlossView(
                      key: ValueKey('${state.cardIndex}-back'),
                      tokens: state.tokens,
                    )
                  : _FrontFace(
                      key: ValueKey('${state.cardIndex}-front'),
                      tokens: state.tokens,
                      onWordTap: _handleWordTap,
                      onWordLongPress: _handleWordLongPress,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Plain-text rendering of one sentence's tokens (spec §6: no
/// underlines/tints regardless of collection state, even though the data to
/// support that marking exists). Each token is independently tappable/
/// long-press-able; the surrounding space (this widget's own padding, plus
/// whatever `_CardArea`'s Card doesn't fill) is "empty card space" that
/// falls through to `_CardArea`'s own tap-to-flip handler, since these
/// per-token `GestureDetector`s only claim the pixels their own `Text`
/// occupies.
class _FrontFace extends StatelessWidget {
  const _FrontFace({
    super.key,
    required this.tokens,
    required this.onWordTap,
    required this.onWordLongPress,
  });

  final List<Token> tokens;
  final ValueChanged<Token> onWordTap;
  final ValueChanged<Token> onWordLongPress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          for (final token in tokens)
            GestureDetector(
              onTap: () => onWordTap(token),
              onLongPress: () => onWordLongPress(token),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  token.surface,
                  style: const TextStyle(fontSize: 26, height: 1.8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The collection identity a tapped [token] resolves to -- must mirror
/// `CardModeController.mineWord`'s own `token.dictForm ?? token.surface` /
/// `token.reading ?? token.surface` fallback exactly, since long-press
/// remove (`removeWord`) needs to target the very same
/// `contentDerivedWordId` a prior tap-to-mine would have created.
({String dictForm, String reading}) _collectionIdentity(Token token) => (
  dictForm: token.dictForm ?? token.surface,
  reading: token.reading ?? token.surface,
);
