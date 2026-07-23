import 'package:flutter/material.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_matcher.dart';

/// Card Mode's flip side (spec §6) and Document Mode's double-tap grammar
/// popup (spec §7): spec §8's three-layer grammar breakdown, minus layer 3
/// (the LLM explanation -- a later phase, network-dependent, meant to
/// stream in beneath these two offline layers rather than block them).
///
/// **Layer 1, token gloss** *(always shown)*: every token's full Sudachi
/// analysis -- surface, dictionary form, reading, part of speech, and
/// inflection chain -- one row per token.
///
/// **Layer 2, matched grammar points** *(shown above layer 1 when any
/// matched)*: spec §8's curated grammar-point database, matched against
/// this sentence (see `ReaderMiningSession.matchGrammar` /
/// `grammar_matcher.dart`). Each matched point is its own tappable card --
/// tap opens `GrammarPointSheet` to mine it, long-press removes it,
/// mirroring word tap/long-press semantics exactly (spec §8: "tappable and
/// mines into the grammar dictionary"). Omitted entirely (no empty
/// section/divider) when nothing matched, which is the common case for any
/// database covering only ~200 patterns against arbitrary prose.
class TokenGlossView extends StatelessWidget {
  const TokenGlossView({
    super.key,
    required this.tokens,
    this.grammarMatches = const [],
    this.onGrammarPointTap,
    this.onGrammarPointLongPress,
  });

  final List<Token> tokens;

  /// Spec §8 layer 2's matches for this gloss's sentence. Empty (the
  /// default) renders identically to before layer 2 existed -- callers that
  /// haven't wired grammar matching yet (if any remain) don't need to
  /// change anything.
  final List<GrammarMatch> grammarMatches;

  /// Tap a matched grammar point -> open its mine-it popup. Only meaningful
  /// (and only ever called) when [grammarMatches] is non-empty; `null` is
  /// fine if a caller genuinely never passes matches.
  final ValueChanged<GrammarMatch>? onGrammarPointTap;

  /// Long-press a matched grammar point -> remove it from the collection.
  final ValueChanged<GrammarMatch>? onGrammarPointLongPress;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (grammarMatches.isNotEmpty) ...[
          _GrammarPointsSection(
            matches: grammarMatches,
            onTap: onGrammarPointTap,
            onLongPress: onGrammarPointLongPress,
          ),
          const Divider(height: 32, thickness: 1.5),
        ],
        for (var i = 0; i < tokens.length; i++) ...[
          if (i > 0) const Divider(height: 24),
          _TokenGlossRow(token: tokens[i]),
        ],
      ],
    );
  }
}

class _GrammarPointsSection extends StatelessWidget {
  const _GrammarPointsSection({
    required this.matches,
    required this.onTap,
    required this.onLongPress,
  });

  final List<GrammarMatch> matches;
  final ValueChanged<GrammarMatch>? onTap;
  final ValueChanged<GrammarMatch>? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GRAMMAR POINTS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final match in matches)
                _GrammarPointChip(
                  match: match,
                  onTap: onTap == null ? null : () => onTap!(match),
                  onLongPress: onLongPress == null
                      ? null
                      : () => onLongPress!(match),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrammarPointChip extends StatelessWidget {
  const _GrammarPointChip({
    required this.match,
    required this.onTap,
    required this.onLongPress,
  });

  final GrammarMatch match;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                match.point.pattern,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                match.point.jlptLevel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TokenGlossRow extends StatelessWidget {
  const _TokenGlossRow({required this.token});

  final Token token;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(token.surface, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 20,
            runSpacing: 6,
            children: [
              if (token.dictForm != null && token.dictForm != token.surface)
                _Field(label: 'Dictionary form', value: token.dictForm!),
              if (token.reading != null)
                _Field(label: 'Reading', value: token.reading!),
              if (token.pos != null)
                _Field(label: 'Part of speech', value: token.pos!),
              if (token.inflection != null)
                _Field(label: 'Inflection', value: token.inflection!),
            ],
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
            letterSpacing: 0.5,
          ),
        ),
        Text(value, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
