import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'review_controller.dart';

/// Spec §12's review deck screen: one due card at a time, recognition-style
/// (front, then reveal the back + source-sentence context), rated via the
/// four standard FSRS grades.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(reviewControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_titleFor(asyncState))),
      body: SafeArea(
        child: asyncState.when(
          data: (state) => _ReviewBody(state: state),
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
    return value.maybeWhen(
      data: (state) => state.isComplete
          ? 'Review'
          : 'Review (${state.remaining} left)',
      orElse: () => 'Review',
    );
  }
}

class _ReviewBody extends ConsumerWidget {
  const _ReviewBody({required this.state});

  final ReviewQueueState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.cards.isEmpty || state.isComplete) {
      return const _EmptyState();
    }

    final card = state.current!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      if (card.contextSentence != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          card.contextSentence!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.outline,
                          ),
                          textAlign: TextAlign.center,
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
              onPressed: () =>
                  ref.read(reviewControllerProvider.notifier).reveal(),
              child: const Text('Show answer'),
            )
          else
            _RatingButtons(
              onRate: (rating) =>
                  ref.read(reviewControllerProvider.notifier).rate(rating),
            ),
        ],
      ),
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
