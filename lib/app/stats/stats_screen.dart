import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stats_controller.dart';

/// Spec §15's progress/stats screen: reading streak, a heatmap of recent
/// reading activity, words/grammar-points-mined counts, comprehension %
/// for whatever document is currently open, and total time read.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(statsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(statsControllerProvider),
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (state) => _StatsBody(state: state),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.state});

  final StatsState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department_outlined,
                label: 'Day streak',
                value: '${state.currentStreakDays}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.schedule_outlined,
                label: 'Time read',
                value: _formatDuration(state.totalSecondsRead),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.bookmark_added_outlined,
                label: 'Words mined',
                value: '${state.wordsMinedCount}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.rule_outlined,
                label: 'Grammar points',
                value: '${state.grammarPointsMinedCount}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: Icons.percent_outlined,
          label: 'Comprehension (current book)',
          value: state.comprehensionPercent == null
              ? 'Open a book to see this'
              : '${(state.comprehensionPercent! * 100).round()}%',
        ),
        const SizedBox(height: 24),
        Text(
          'Last ${StatsController.heatmapDays} days',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _HeatmapGrid(heatmap: state.heatmap, days: StatsController.heatmapDays),
      ],
    );
  }

  static String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours == 0 && minutes == 0) return '${totalSeconds}s';
    if (hours == 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineSmall),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple flowing (not calendar-weekday-aligned) grid of the last [days]
/// days, darkest for the most active. A GitHub-style grid strictly aligned
/// to weekdays/weeks would look more like a "real" heatmap, but this is a
/// deliberately simpler stand-in that still shows the same information --
/// see the class doc comment on `StatsController` for the broader "keep
/// this pass's stats screen bounded in scope" reasoning.
class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({required this.heatmap, required this.days});

  final Map<DateTime, int> heatmap;
  final int days;

  /// An hour of reading in one day is treated as "fully saturated" --
  /// there's no meaningful upper bound on daily reading time otherwise, and
  /// this keeps a single very long session from making every other day
  /// look empty by comparison.
  static const _fullIntensitySeconds = 3600;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = days - 1; i >= 0; i--)
          _buildCell(theme, today.subtract(Duration(days: i))),
      ],
    );
  }

  Widget _buildCell(ThemeData theme, DateTime day) {
    final seconds = heatmap[day] ?? 0;
    final intensity = (seconds / _fullIntensitySeconds).clamp(0.0, 1.0);
    final color = intensity == 0
        ? theme.colorScheme.surfaceContainerHighest
        : Color.lerp(
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primary,
            intensity,
          )!;
    return Tooltip(
      message: '${day.year}-${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}: '
          '${(seconds / 60).round()} min',
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
