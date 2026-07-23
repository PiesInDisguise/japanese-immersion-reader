import 'package:flutter/material.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_matcher.dart';

/// Card Mode's and Document Mode's shared tap-a-grammar-point popup (spec
/// §8 layer 2: "Each matched point is tappable and mines into the grammar
/// dictionary") -- the grammar-side mirror of `WordLookupSheet`
/// (`word_lookup_sheet.dart`), simpler in one way: a [GrammarMatch] already
/// carries everything to display (pattern/JLPT level/explanation/examples,
/// straight from the bundled grammar-point database), so there's no
/// async lookup future to wait on the way a word's dictionary senses need.
///
/// Takes [mine] as an explicit callback rather than reaching into a
/// specific mode's controller provider directly, for the same reason
/// `WordLookupSheet` does -- see that class's own doc comment.
///
/// Pops itself with `true` if the point was mined during this sheet's
/// lifetime, `null`/`false` otherwise -- same undo-toast handoff contract
/// as `WordLookupSheet`.
class GrammarPointSheet extends StatefulWidget {
  const GrammarPointSheet({super.key, required this.match, required this.mine});

  final GrammarMatch match;

  /// Mines [match]'s point. Wired by the caller -- e.g. `(match) =>
  /// controller.mineGrammarPoint(match.point)`.
  final Future<void> Function() mine;

  @override
  State<GrammarPointSheet> createState() => _GrammarPointSheetState();
}

class _GrammarPointSheetState extends State<GrammarPointSheet> {
  bool _mining = false;

  Future<void> _mine() async {
    setState(() => _mining = true);
    await widget.mine();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final point = widget.match.point;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                point.pattern,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  point.jlptLevel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Text(point.explanation, style: theme.textTheme.bodyLarge),
              if (point.examples.isNotEmpty) ...[
                const SizedBox(height: 16),
                for (final example in point.examples)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(example.japanese, style: theme.textTheme.bodyLarge),
                        Text(
                          example.english,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              FilledButton.icon(
                icon: _mining
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bookmark_add_outlined),
                label: const Text('Add to Collection'),
                onPressed: _mining ? null : _mine,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
