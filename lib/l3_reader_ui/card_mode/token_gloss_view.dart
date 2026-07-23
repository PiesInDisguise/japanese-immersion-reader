import 'package:flutter/material.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';

/// Card Mode's flip side (spec §6, spec §8 layer 1): every token's full
/// Sudachi analysis -- surface, dictionary form, reading, part of speech,
/// and inflection chain -- laid out one row per token.
///
/// Only layer 1 of spec §8's three-layer grammar breakdown is available
/// this pass: matched grammar points (layer 2) and the LLM explanation
/// (layer 3) need a grammar-point database that doesn't exist yet (see
/// `card_mode_controller.dart`'s scope note). A future pass would likely
/// add those as extra sections per row (or below the list) rather than
/// restructuring this widget.
class TokenGlossView extends StatelessWidget {
  const TokenGlossView({super.key, required this.tokens});

  final List<Token> tokens;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tokens.length,
      separatorBuilder: (context, index) => const Divider(height: 24),
      itemBuilder: (context, index) => _TokenGlossRow(token: tokens[index]),
    );
  }
}

class _TokenGlossRow extends StatelessWidget {
  const _TokenGlossRow({required this.token});

  final Token token;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
