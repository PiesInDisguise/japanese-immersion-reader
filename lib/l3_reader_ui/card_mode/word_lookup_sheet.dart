import 'package:flutter/material.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_repository.dart';

import 'definition_rendering.dart';

/// Card Mode's and Document Mode's shared tap-a-word popup (spec §6/§7/§10):
/// shows [lookup]'s results -- word, reading, meaning, spec §10's
/// default-on popup fields -- for [token], with a button to mine it via
/// [mine] (spec's auto-add-ON tap-to-mine behavior).
///
/// Takes [lookup]/[mine] as explicit callbacks rather than reaching into a
/// specific mode's controller provider directly, since Card Mode and
/// Document Mode both need this exact popup (spec §7: "same mining rules as
/// Card Mode") but differ in how they identify the mined word's source
/// sentence -- Card Mode always mines against its own single current card
/// (`CardModeController.mineWord`), while Document Mode has no single
/// "current sentence" and must be told which visible sentence contained the
/// tapped token (`DocumentModeController.mineWord`'s required `sentenceId`).
/// Each screen supplies closures over its own controller (and, for Document
/// Mode, the containing sentence) rather than this widget knowing about
/// either.
///
/// Pops itself with `true` (via [Navigator.pop]) if the word was mined
/// during this sheet's lifetime, `null`/`false` otherwise. The caller uses
/// that to decide whether to show the undo toast -- the toast itself lives
/// outside this sheet, since spec's undo toast is meant to keep working even
/// after this popup has closed.
///
/// Optional popup fields from spec §10 (example sentences, pitch accent,
/// conjugation table) aren't shown -- they're settings-gated and no
/// settings screen exists yet, matching this pass's scope.
class WordLookupSheet extends StatefulWidget {
  const WordLookupSheet({
    super.key,
    required this.token,
    required this.lookup,
    required this.mine,
  });

  final Token token;

  /// Looks up dictionary senses for [token]. Wired by the caller to
  /// whichever mode's controller is current -- e.g.
  /// `() => cardModeController.lookupWord(token)`.
  final Future<List<DictionaryLookupHit>> Function() lookup;

  /// Mines [token] with [senses] (whatever [lookup] most recently found).
  /// Wired by the caller -- e.g.
  /// `(senses) => cardModeController.mineWord(token, senses)` for Card Mode,
  /// or `(senses) => documentModeController.mineWord(token, senses,
  /// sentenceId: ...)` for Document Mode, closing over whichever sentence
  /// contains [token].
  final Future<void> Function(List<DictionaryLookupHit> senses) mine;

  @override
  State<WordLookupSheet> createState() => _WordLookupSheetState();
}

class _WordLookupSheetState extends State<WordLookupSheet> {
  late final Future<List<DictionaryLookupHit>> _lookupFuture;
  bool _mining = false;

  @override
  void initState() {
    super.initState();
    // Captured once in initState (not read again on every build) so
    // rebuilding this widget -- e.g. while `_mining` flips -- never
    // re-triggers the lookup.
    _lookupFuture = widget.lookup();
  }

  Future<void> _mine(List<DictionaryLookupHit> hits) async {
    setState(() => _mining = true);
    await widget.mine(hits);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                widget.token.surface,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              if (widget.token.reading != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    widget.token.reading!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              FutureBuilder<List<DictionaryLookupHit>>(
                future: _lookupFuture,
                builder: (context, snapshot) {
                  final ready =
                      snapshot.connectionState == ConnectionState.done;
                  if (!ready) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Dictionary lookup failed: ${snapshot.error}',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    );
                  }

                  final hits = snapshot.data ?? const [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LookupResults(hits: hits, surface: widget.token.surface),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: _mining
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.bookmark_add_outlined),
                        label: const Text('Add to Collection'),
                        onPressed: _mining ? null : () => _mine(hits),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LookupResults extends StatelessWidget {
  const _LookupResults({required this.hits, required this.surface});

  final List<DictionaryLookupHit> hits;
  final String surface;

  @override
  Widget build(BuildContext context) {
    if (hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No dictionary entry found for "$surface". You can still add it '
          'to your collection.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < hits.length; i++) ...[
          if (i > 0) const Divider(height: 24),
          _HitTile(hit: hits[i]),
        ],
      ],
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit});

  final DictionaryLookupHit hit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meanings = parseDefinitionEntries(hit.term.definitionsJson);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                hit.term.headword,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                hit.term.readingNormalized,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final meaning in meanings)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('•  $meaning', style: theme.textTheme.bodyMedium),
          ),
        const SizedBox(height: 6),
        Text(
          hit.dictionaryTitle,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
