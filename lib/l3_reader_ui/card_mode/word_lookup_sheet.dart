import 'package:flutter/material.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_repository.dart';
import 'package:japanese_immersion_reader/l2_linguistics/kana.dart';

import 'definition_rendering.dart';

/// Shows [WordLookupSheet] as a small popup anchored toward the upper part
/// of the screen, rather than a full-height modal bottom sheet -- so it
/// doesn't cover most of the reading surface behind it. Both Card Mode's and
/// Document Mode's `_handleWordTap` call this instead of constructing
/// [WordLookupSheet]/`showModalBottomSheet` directly, so the popup's size
/// and position stay in one place. Returns `true` if the word was mined at
/// any point during this popup's lifetime, regardless of what actually
/// closed the popup.
Future<bool> showWordLookupPopup({
  required BuildContext context,
  required Token token,
  required Future<List<DictionaryLookupHit>> Function() lookup,
  required Future<void> Function(List<DictionaryLookupHit> senses) mine,
  Future<bool> Function()? checkTtsActive,
  Future<void> Function(String text)? speak,
  Future<bool> Function()? checkPitchAccentActive,
  Future<bool> Function({required String expression, required String reading})?
  playPitchAccentAudio,
  bool autoMine = false,
}) async {
  // Whether the word got mined survives independently of *how* the dialog
  // closes -- pressing "Add to Collection" pops immediately (see `_mine`),
  // but `autoMine` deliberately does not (see `_autoMine`'s own doc
  // comment), so the dialog might instead close via a barrier tap/Esc/back,
  // none of which carry a `true` pop result themselves.
  var mined = false;
  await showDialog<void>(
    context: context,
    builder: (_) => Align(
      alignment: const Alignment(0, -0.3),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 420),
          child: WordLookupSheet(
            token: token,
            lookup: lookup,
            mine: mine,
            checkTtsActive: checkTtsActive,
            speak: speak,
            checkPitchAccentActive: checkPitchAccentActive,
            playPitchAccentAudio: playPitchAccentAudio,
            autoMine: autoMine,
            onMined: () => mined = true,
          ),
        ),
      ),
    ),
  );
  return mined;
}

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
/// Calls [onMined] the moment a mine actually happens, and (for a manual
/// "Add to Collection" tap only, not `autoMine`) also closes the sheet --
/// see [showWordLookupPopup], which turns that callback into its own return
/// value regardless of how the sheet ends up closing. The caller uses that
/// to decide whether to show the undo toast -- the toast itself lives
/// outside this sheet, since spec's undo toast is meant to keep working even
/// after this popup has closed.
///
/// Spec §10's example-sentences/conjugation-table optional popup fields
/// aren't shown -- no settings toggle exists for them yet. Spec §9's audio
/// fields (TTS, pitch-accent recording) *are* wired, via
/// [checkTtsActive]/[speak]/[checkPitchAccentActive]/[playPitchAccentAudio]
/// -- all optional so any caller that doesn't pass them just gets no audio
/// buttons, matching how [TokenGlossView]'s layer-3 params work.
class WordLookupSheet extends StatefulWidget {
  const WordLookupSheet({
    super.key,
    required this.token,
    required this.lookup,
    required this.mine,
    this.checkTtsActive,
    this.speak,
    this.checkPitchAccentActive,
    this.playPitchAccentAudio,
    this.autoMine = false,
    this.onMined,
  });

  final Token token;

  /// Spec §6's "Auto-add ON": when true, [mine] fires automatically as soon
  /// as [lookup] resolves -- the same effect as the user pressing "Add to
  /// Collection" themselves, without the extra tap. Defaults to `false`,
  /// matching this app's existing tap-then-explicit-add flow.
  final bool autoMine;

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

  /// Fired the moment a mine actually happens (manual button press or
  /// `autoMine`), regardless of whether that closes the sheet -- lets
  /// [showWordLookupPopup] know whether to report a mine happened even when
  /// `autoMine` mines without closing (see that method's own doc comment).
  final VoidCallback? onMined;

  /// `ReaderMiningSession.ttsActive` (via whichever mode controller owns
  /// this session), checked once at open so the speaker button can be
  /// omitted entirely when TTS is off, rather than shown and silently
  /// doing nothing.
  final Future<bool> Function()? checkTtsActive;

  /// `ReaderMiningSession.speak` -- given the text to speak (this sheet
  /// always passes [token]'s own surface).
  final Future<void> Function(String text)? speak;

  /// `ReaderMiningSession.pitchAccentAudioActive` -- same "check once at
  /// open" reasoning as [checkTtsActive].
  final Future<bool> Function()? checkPitchAccentActive;

  /// `ReaderMiningSession.playPitchAccentAudio`.
  final Future<bool> Function({
    required String expression,
    required String reading,
  })?
  playPitchAccentAudio;

  @override
  State<WordLookupSheet> createState() => _WordLookupSheetState();
}

class _WordLookupSheetState extends State<WordLookupSheet> {
  late final Future<List<DictionaryLookupHit>> _lookupFuture;
  bool _mining = false;
  bool _mined = false;
  bool _ttsActive = false;
  bool _pitchAccentActive = false;
  bool _playingPitchAccent = false;

  @override
  void initState() {
    super.initState();
    // Captured once in initState (not read again on every build) so
    // rebuilding this widget -- e.g. while `_mining` flips -- never
    // re-triggers the lookup.
    _lookupFuture = widget.lookup();
    _initAudioAvailability();
    if (widget.autoMine) {
      // Fires once, as soon as the lookup this sheet already started
      // resolves -- but via `_autoMine`, not `_mine`: unlike a manual "Add
      // to Collection" tap, this isn't a user action that should also close
      // the sheet. Auto-add's whole point is the user still gets to read
      // the definition; only mining itself should happen automatically.
      _lookupFuture.then((hits) {
        if (mounted) _autoMine(hits);
      });
    }
  }

  Future<void> _initAudioAvailability() async {
    final ttsActive = widget.checkTtsActive == null
        ? false
        : await widget.checkTtsActive!();
    final pitchAccentActive = widget.checkPitchAccentActive == null
        ? false
        : await widget.checkPitchAccentActive!();
    if (!mounted) return;
    setState(() {
      _ttsActive = ttsActive;
      _pitchAccentActive = pitchAccentActive;
    });
  }

  /// The "Add to Collection" button's handler -- an explicit user action,
  /// so (unlike [_autoMine]) closing the sheet immediately afterward is the
  /// expected, wanted behavior.
  Future<void> _mine(List<DictionaryLookupHit> hits) async {
    setState(() => _mining = true);
    await widget.mine(hits);
    widget.onMined?.call();
    if (mounted) Navigator.of(context).pop();
  }

  /// Spec §6's "Auto-add ON": mines [hits] without closing the sheet --
  /// the user tapped a word to see its definition, and auto-add shouldn't
  /// take that away by immediately dismissing the popup the moment mining
  /// finishes (which, for a fast local lookup, could be near-instant). The
  /// sheet stays open until the user dismisses it themselves; the "Add to
  /// Collection" button just reflects the already-mined state meanwhile
  /// (see `build`'s use of [_mined]).
  Future<void> _autoMine(List<DictionaryLookupHit> hits) async {
    setState(() => _mining = true);
    await widget.mine(hits);
    widget.onMined?.call();
    if (mounted) {
      setState(() {
        _mining = false;
        _mined = true;
      });
    }
  }

  Future<void> _speakWord() => widget.speak!(widget.token.surface);

  Future<void> _playPitchAccent() async {
    setState(() => _playingPitchAccent = true);
    final played = await widget.playPitchAccentAudio!(
      expression: widget.token.dictForm ?? widget.token.surface,
      reading: widget.token.reading ?? widget.token.surface,
    );
    if (!mounted) return;
    setState(() => _playingPitchAccent = false);
    if (!played) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pitch-accent recording found for this word.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.token.surface,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (widget.token.reading != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  katakanaToHiragana(widget.token.reading!),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_ttsActive || _pitchAccentActive)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_ttsActive)
                    IconButton(
                      icon: const Icon(Icons.volume_up_outlined),
                      tooltip: 'Speak',
                      onPressed: _speakWord,
                    ),
                  if (_pitchAccentActive)
                    IconButton(
                      icon: _playingPitchAccent
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.graphic_eq),
                      tooltip: 'Play pitch-accent recording',
                      onPressed: _playingPitchAccent ? null : _playPitchAccent,
                    ),
                ],
              ),
            const SizedBox(height: 16),
            FutureBuilder<List<DictionaryLookupHit>>(
              future: _lookupFuture,
              builder: (context, snapshot) {
                final ready = snapshot.connectionState == ConnectionState.done;
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _mined
                                  ? Icons.bookmark_added
                                  : Icons.bookmark_add_outlined,
                            ),
                      label: Text(
                        _mined ? 'Added to Collection' : 'Add to Collection',
                      ),
                      onPressed: (_mining || _mined) ? null : () => _mine(hits),
                    ),
                  ],
                );
              },
            ),
          ],
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
