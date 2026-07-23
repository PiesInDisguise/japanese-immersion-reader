import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';

import '../card_mode/card_mode_screen.dart';
import '../card_mode/token_gloss_view.dart';
import '../card_mode/word_lookup_sheet.dart';
import '../vertical_text/vertical_text.dart';
import 'document_mode_controller.dart';

/// Document Mode's screen (spec §7): a standard, continuously scrollable
/// reader over the *entire* document, with the same tap/mine/undo
/// interaction layer as Card Mode overlaid per-token. See
/// [DocumentModeController]'s own scope-note doc comment for what's
/// deliberately not implemented this pass (drag-to-override the tokenizer
/// boundary; matched grammar points/LLM explanation beyond layer-1 token
/// gloss). Vertical-text rendering (also mentioned in spec §7) *is* wired up
/// this pass: each row renders horizontally or vertically per its
/// containing `Block.direction` (see `_flattenDocument`/`_SentenceRow` and
/// `_SentenceRowView`'s own doc comment) -- vertical rows delegate to
/// `VerticalSentenceView` (`lib/l3_reader_ui/vertical_text/`), which hosts
/// the same tap/long-press/double-tap semantics on top of the vertical-text
/// rendering spike.
class DocumentModeScreen extends ConsumerWidget {
  const DocumentModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(documentModeControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(asyncState)),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_carousel_outlined),
            tooltip: 'Switch to Card Mode',
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CardModeScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: asyncState.when(
          data: (state) =>
              _DocumentModeBody(key: ValueKey(state.document.id), state: state),
          loading: () => const _LoadingView(),
          error: (error, stackTrace) => _ErrorView(error: error),
        ),
      ),
    );
  }

  String _titleFor(AsyncValue<DocumentModeState> value) {
    return value.maybeWhen(
      data: (state) => state.document.title,
      orElse: () => 'Document Mode',
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

/// Mirrors `CardModeScreen`'s own `_ErrorView` exactly (same likely cause --
/// see that class's doc comment -- and same graceful, generic degradation).
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
            Text(
              "Couldn't load this document",
              style: theme.textTheme.titleMedium,
            ),
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
              onPressed: () => ref.invalidate(documentModeControllerProvider),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row in the flattened, whole-document list this screen scrolls over.
/// Chapters contribute a single header row; every sentence in every block
/// contributes its own row (never a whole block or chapter as one row), so
/// each row can be independently tokenized/tapped and independently
/// reported to [DocumentModeController.reportVisibleSentence] as it scrolls
/// by.
sealed class _Row {
  const _Row();
}

class _ChapterHeaderRow extends _Row {
  const _ChapterHeaderRow(this.chapter);
  final Chapter chapter;
}

class _SentenceRow extends _Row {
  const _SentenceRow(
    this.sentence, {
    required this.isBlockStart,
    required this.direction,
  });
  final Sentence sentence;

  /// Whether this is the first sentence of its containing block -- used
  /// only for a little extra spacing above, so paragraph/bubble/line breaks
  /// (`BlockKind`) stay visually legible in an otherwise flat sentence list.
  final bool isBlockStart;

  /// The containing `Block`'s `direction` -- carried per-row (rather than
  /// re-derived from the block later) since flattening is the one place
  /// that already walks block-by-block; see `_SentenceRowView` for how this
  /// picks horizontal vs. vertical rendering.
  final WritingDirection direction;
}

List<_Row> _flattenDocument(Document document) {
  final rows = <_Row>[];
  for (final chapter in document.chapters) {
    rows.add(_ChapterHeaderRow(chapter));
    for (final block in chapter.blocks) {
      var isBlockStart = true;
      for (final sentence in block.sentences) {
        rows.add(
          _SentenceRow(
            sentence,
            isBlockStart: isBlockStart,
            direction: block.direction,
          ),
        );
        isBlockStart = false;
      }
    }
  }
  return rows;
}

/// The scrollable body: a single [ListView.builder] over every row in
/// [_flattenDocument], plus the position-sync bookkeeping described below.
///
/// **Scroll-position approach (both directions) -- deliberately
/// approximate, not pixel-exact:** rows have no fixed height (each
/// sentence's `Wrap` wraps to however many lines its text needs), so there's
/// no way to compute an *exact* pixel offset for an arbitrary row without
/// either laying out the whole book up front (defeats the point of a lazy
/// `ListView.builder`) or a package like `scrollable_positioned_list` that
/// tracks real item extents. Neither is warranted for this pass -- the task
/// this screen implements only needs "roughly which sentence is on screen,"
/// not frame-accurate scroll restoration -- so this uses a plain
/// [ScrollController] plus a rough per-row-type estimated extent
/// (`_chapterHeaderExtent`/`_sentenceRowExtent`) to build a cumulative
/// estimated-offset table once per document load:
///   - **Initial scroll** (`state.initialSentenceId`): look up that
///     sentence's estimated cumulative offset and pass it as the
///     [ScrollController]'s `initialScrollOffset`. This can land a
///     paragraph or two off from the exact sentence in a long book (longer
///     sentences make later rows' real offsets drift from the flat
///     per-row estimate), but always lands in the right neighborhood.
///   - **Ongoing tracking**: on every scroll change, binary-search the same
///     cumulative-offset table for the current scroll offset and report
///     whichever sentence row that resolves to.
/// If a future pass needs exact restoration, `scrollable_positioned_list`
/// (which tracks real item extents and jumps/aligns exactly) is the
/// straightforward upgrade path -- deliberately not added here since a
/// plain `ScrollController` is enough for "roughly."
class _DocumentModeBody extends ConsumerStatefulWidget {
  const _DocumentModeBody({super.key, required this.state});

  final DocumentModeState state;

  @override
  ConsumerState<_DocumentModeBody> createState() => _DocumentModeBodyState();
}

class _DocumentModeBodyState extends ConsumerState<_DocumentModeBody> {
  // Rough average extents (logical pixels) used only for the scroll-offset
  // estimate described on `_DocumentModeBody` -- not real measured sizes.
  static const _sentenceRowExtent = 76.0;
  static const _chapterHeaderExtent = 96.0;

  late final List<_Row> _rows;
  late final List<double> _rowOffsets;
  late final ScrollController _scrollController;
  String? _lastReportedSentenceId;

  @override
  void initState() {
    super.initState();
    _rows = _flattenDocument(widget.state.document);

    _rowOffsets = List<double>.filled(_rows.length, 0);
    var offset = 0.0;
    for (var i = 0; i < _rows.length; i++) {
      _rowOffsets[i] = offset;
      offset += switch (_rows[i]) {
        _ChapterHeaderRow() => _chapterHeaderExtent,
        _SentenceRow() => _sentenceRowExtent,
      };
    }

    final initialIndex = _rows.indexWhere(
      (row) =>
          row is _SentenceRow &&
          row.sentence.id == widget.state.initialSentenceId,
    );
    final initialOffset = initialIndex > 0 ? _rowOffsets[initialIndex] : 0.0;
    _lastReportedSentenceId = widget.state.initialSentenceId;

    _scrollController = ScrollController(initialScrollOffset: initialOffset)
      ..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final index = _topmostRowIndexForOffset(_scrollController.offset);
    final sentenceId = _sentenceIdAtOrAfter(index);
    if (sentenceId == null || sentenceId == _lastReportedSentenceId) return;
    _lastReportedSentenceId = sentenceId;
    ref
        .read(documentModeControllerProvider.notifier)
        .reportVisibleSentence(sentenceId);
  }

  /// Binary search over the cumulative estimated-offset table (monotonic by
  /// construction) for the last row whose estimated offset is at or before
  /// [offset] -- i.e. the topmost row estimated to be visible.
  int _topmostRowIndexForOffset(double offset) {
    var lo = 0;
    var hi = _rowOffsets.length - 1;
    var result = 0;
    while (lo <= hi) {
      final mid = lo + ((hi - lo) >> 1);
      if (_rowOffsets[mid] <= offset) {
        result = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return result;
  }

  /// The first actual sentence at or after row [index] -- [index] itself
  /// may land on a chapter header row, which has no sentence of its own to
  /// report.
  String? _sentenceIdAtOrAfter(int index) {
    for (var i = index; i < _rows.length; i++) {
      final row = _rows[i];
      if (row is _SentenceRow) return row.sentence.id;
    }
    return null;
  }

  Future<void> _handleWordTap(String sentenceId, Token token) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(documentModeControllerProvider.notifier);
    final mined = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => WordLookupSheet(
        token: token,
        lookup: () => controller.lookupWord(token),
        mine: (senses) =>
            controller.mineWord(token, senses, sentenceId: sentenceId),
      ),
    );
    if (mined == true && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Added "${token.surface}" to your collection'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => ref
                .read(documentModeControllerProvider.notifier)
                .undoLastMining(),
          ),
        ),
      );
    }
  }

  Future<void> _handleWordLongPress(Token token) async {
    final messenger = ScaffoldMessenger.of(context);
    final identity = _collectionIdentity(token);
    await ref
        .read(documentModeControllerProvider.notifier)
        .removeWord(identity.dictForm, identity.reading);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Removed "${token.surface}" from your collection'),
      ),
    );
  }

  /// Double-tap (spec §7): grammar breakdown of the *containing sentence*,
  /// as a popup -- not a flip, since Document Mode has no card to flip.
  /// [tokens] are whatever the double-tapped row already fetched via
  /// `DocumentModeController.tokensFor`, so this never re-tokenizes.
  void _handleSentenceDoubleTap(List<Token> tokens) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          // TokenGlossView uses a ListView.separated internally, which
          // needs a bounded height from an ancestor -- a Dialog's child
          // otherwise sizes to content, which is unbounded for a list.
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 480),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Grammar breakdown',
                  style: Theme.of(dialogContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Flexible(child: TokenGlossView(tokens: tokens)),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _rows.length,
            itemBuilder: (context, index) {
              final row = _rows[index];
              return switch (row) {
                _ChapterHeaderRow() => _ChapterHeaderTile(chapter: row.chapter),
                _SentenceRow() => _SentenceRowView(
                  key: ValueKey(row.sentence.id),
                  sentence: row.sentence,
                  isBlockStart: row.isBlockStart,
                  direction: row.direction,
                  tokensFuture: () => ref
                      .read(documentModeControllerProvider.notifier)
                      .tokensFor(row.sentence),
                  onWordTap: (token) => _handleWordTap(row.sentence.id, token),
                  onWordLongPress: _handleWordLongPress,
                  onSentenceDoubleTap: _handleSentenceDoubleTap,
                ),
              };
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            'Tap a word to look it up  •  Long-press to remove  •  '
            'Double-tap a sentence for its grammar breakdown',
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

class _ChapterHeaderTile extends StatelessWidget {
  const _ChapterHeaderTile({required this.chapter});

  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        chapter.title ?? 'Chapter ${chapter.index + 1}',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}

/// One sentence's row: fetches its own tokens lazily (via [tokensFuture],
/// called once in [initState] -- mirrors `WordLookupSheet`'s own
/// initState-captured lookup future) rather than the whole document being
/// pre-tokenized up front, since only rows `ListView.builder` actually
/// builds (roughly the viewport plus its cache extent) ever need real
/// tokenization.
///
/// Branches purely on [direction] once tokens resolve -- everything before
/// that point (the `FutureBuilder`, the loading/error states, the outer
/// `Padding`) is identical either way, so only the actual token rendering
/// differs:
///  - **Horizontal** (the default/common case): the same per-token tappable
///    [Wrap] idea as Card Mode's `_FrontFace`, but every token here also
///    answers double-tap -- see the class-level rationale below for why
///    that's on the *same* GestureDetector as tap/long-press rather than a
///    separate one layered over the whole row.
///  - **Vertical**: delegates entirely to `VerticalSentenceView`
///    (`lib/l3_reader_ui/vertical_text/vertical_sentence_view.dart`), which
///    hosts the equivalent tap/long-press/double-tap semantics on top of
///    the vertical-text rendering spike -- see *that* class's own doc
///    comment for why its gesture layering necessarily looks different from
///    the horizontal case below (`VerticalTextView` doesn't expose a
///    composable tap recognizer the way plain per-token `Text` widgets do).
class _SentenceRowView extends StatefulWidget {
  const _SentenceRowView({
    super.key,
    required this.sentence,
    required this.isBlockStart,
    required this.direction,
    required this.tokensFuture,
    required this.onWordTap,
    required this.onWordLongPress,
    required this.onSentenceDoubleTap,
  });

  final Sentence sentence;
  final bool isBlockStart;
  final WritingDirection direction;
  final Future<List<Token>> Function() tokensFuture;
  final ValueChanged<Token> onWordTap;
  final ValueChanged<Token> onWordLongPress;
  final ValueChanged<List<Token>> onSentenceDoubleTap;

  @override
  State<_SentenceRowView> createState() => _SentenceRowViewState();
}

class _SentenceRowViewState extends State<_SentenceRowView> {
  late final Future<List<Token>> _tokensFuture;

  @override
  void initState() {
    super.initState();
    _tokensFuture = widget.tokensFuture();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, widget.isBlockStart ? 16 : 2, 16, 2),
      child: FutureBuilder<List<Token>>(
        future: _tokensFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(
              'Failed to tokenize sentence: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            );
          }
          final tokens = snapshot.data;
          if (tokens == null) {
            // No spinner: like Card Mode (see `card_mode_controller.dart`'s
            // own "tokenizing one sentence is fast enough" reasoning), the
            // untokenized surface text stays on screen and non-interactive
            // until tokens resolve, rather than flashing a loading state
            // per row while scrolling.
            return Text(
              widget.sentence.surfaceText,
              style: const TextStyle(fontSize: 20, height: 1.8),
            );
          }
          if (widget.direction == WritingDirection.vertical) {
            return VerticalSentenceView(
              tokens: tokens,
              onWordTap: widget.onWordTap,
              onWordLongPress: widget.onWordLongPress,
              onSentenceDoubleTap: widget.onSentenceDoubleTap,
            );
          }

          // A single GestureDetector per token carries onTap, onDoubleTap,
          // *and* onLongPress together (rather than, say, a separate
          // sentence-wide onDoubleTap layered over this Wrap) because
          // Flutter's gesture arena needs every recognizer that might claim
          // the same pointer sequence living together to disambiguate
          // correctly -- a parent-level onDoubleTap competing with a
          // child-level onTap over the same tap would otherwise fight over
          // the same gesture instead of cleanly falling back. Double-tap
          // always reports this row's whole `tokens` list (spec §7: the
          // *containing sentence*'s breakdown), regardless of which token
          // was actually double-tapped.
          return Wrap(
            children: [
              for (final token in tokens)
                GestureDetector(
                  onTap: () => widget.onWordTap(token),
                  onDoubleTap: () => widget.onSentenceDoubleTap(tokens),
                  onLongPress: () => widget.onWordLongPress(token),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      token.surface,
                      style: const TextStyle(fontSize: 20, height: 1.8),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Mirrors `card_mode_screen.dart`'s own `_collectionIdentity` exactly (kept
/// as a separate copy since Dart privacy is per-library/file, not
/// importable across the two screens) -- must stay in lockstep with
/// `ReaderMiningSession.mineWord`'s `token.dictForm ?? token.surface` /
/// `token.reading ?? token.surface` fallback, since long-press remove needs
/// to target the same `contentDerivedWordId` a prior tap-to-mine would have
/// created.
({String dictForm, String reading}) _collectionIdentity(Token token) => (
  dictForm: token.dictForm ?? token.surface,
  reading: token.reading ?? token.surface,
);
