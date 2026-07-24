import 'package:flutter/material.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_matcher.dart';
import 'package:japanese_immersion_reader/l2_linguistics/kana.dart';

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
///
/// **Layer 3, LLM explanation** *(shown below layer 1, streaming in)*: spec
/// §8's optional, network-dependent sentence explanation
/// (`ReaderMiningSession.explainSentence`) -- streams in beneath the two
/// offline layers rather than blocking them, and is omitted entirely (like
/// layer 2) when [sentence]/[checkExplanationsActive]/[explainSentence]
/// aren't all supplied, or when [checkExplanationsActive] resolves false
/// (no API key configured / toggled off in Settings).
class TokenGlossView extends StatefulWidget {
  const TokenGlossView({
    super.key,
    required this.tokens,
    this.grammarMatches = const [],
    this.onGrammarPointTap,
    this.onGrammarPointLongPress,
    this.sentence,
    this.checkExplanationsActive,
    this.explainSentence,
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

  /// The sentence [tokens] belongs to -- needed (alongside
  /// [checkExplanationsActive]/[explainSentence]) only for layer 3; leave
  /// `null` to omit that section entirely (e.g. any test that only cares
  /// about layers 1/2).
  final Sentence? sentence;

  /// `ReaderMiningSession.explanationsActive` (via whichever mode controller
  /// owns this session), checked once when [sentence] first appears so the
  /// section can stay hidden entirely rather than call in and fail when no
  /// API key is configured.
  final Future<bool> Function()? checkExplanationsActive;

  /// `ReaderMiningSession.explainSentence`-shaped call (via whichever mode
  /// controller owns this session) -- given [sentence], returns the
  /// cumulative-text-so-far stream to display.
  final Stream<String> Function(Sentence sentence)? explainSentence;

  @override
  State<TokenGlossView> createState() => _TokenGlossViewState();
}

class _TokenGlossViewState extends State<TokenGlossView> {
  bool? _active;
  Stream<String>? _stream;

  @override
  void initState() {
    super.initState();
    _maybeStartExplanation();
  }

  @override
  void didUpdateWidget(covariant TokenGlossView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sentence?.id != widget.sentence?.id) {
      _active = null;
      _stream = null;
      _maybeStartExplanation();
    }
  }

  void _maybeStartExplanation() {
    final sentence = widget.sentence;
    final checkActive = widget.checkExplanationsActive;
    final explain = widget.explainSentence;
    if (sentence == null || checkActive == null || explain == null) return;
    checkActive().then((active) {
      if (!mounted || widget.sentence?.id != sentence.id) return;
      setState(() {
        _active = active;
        if (active) _stream = explain(sentence);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (widget.grammarMatches.isNotEmpty) ...[
          _GrammarPointsSection(
            matches: widget.grammarMatches,
            onTap: widget.onGrammarPointTap,
            onLongPress: widget.onGrammarPointLongPress,
          ),
          const Divider(height: 32, thickness: 1.5),
        ],
        for (var i = 0; i < widget.tokens.length; i++) ...[
          if (i > 0) const Divider(height: 24),
          _TokenGlossRow(token: widget.tokens[i]),
        ],
        if (_active == true && _stream != null) ...[
          const Divider(height: 32, thickness: 1.5),
          _ExplanationSection(stream: _stream!),
        ],
      ],
    );
  }
}

class _ExplanationSection extends StatelessWidget {
  const _ExplanationSection({required this.stream});

  final Stream<String> stream;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GRAMMAR EXPLANATION',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<String>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  "Couldn't load an explanation: ${snapshot.error}",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                );
              }
              final text = snapshot.data;
              if (text == null || text.isEmpty) {
                return const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              return Text(text, style: theme.textTheme.bodyMedium);
            },
          ),
        ],
      ),
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
                _Field(
                  label: 'Reading',
                  value: katakanaToHiragana(token.reading!),
                ),
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
