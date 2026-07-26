import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/app/services.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';

import 'review_screen.dart';

/// Entry point into spec §12's review flow: a Library-style grid of
/// review decks -- one "All" tile (every due word/grammar point,
/// regardless of book) plus one tile per imported book, each showing that
/// book's own cover art (mirroring `LibraryScreen`'s own cover-thumbnail
/// rendering) and how many of its own words/grammar points are due right
/// now. Tapping a tile jumps straight into [ReviewScreen] scoped
/// accordingly -- there's no second "pick a deck type" step, since a
/// book's tile *is* its deck.
///
/// Every book always appears, even with nothing due (grayed out /
/// untappable) -- consistent with the Library screen itself always
/// listing every book regardless of reading progress, rather than a grid
/// that shrinks and grows as review catches up.
class ReviewDeckPickerScreen extends ConsumerStatefulWidget {
  const ReviewDeckPickerScreen({super.key});

  @override
  ConsumerState<ReviewDeckPickerScreen> createState() =>
      _ReviewDeckPickerScreenState();
}

class _DeckPickerData {
  const _DeckPickerData({required this.documents, required this.dueCounts});

  final List<DocumentRow> documents;

  /// Due count per deck -- keyed by document id for book decks, plus one
  /// entry under [_allDeckKey] for the "All" tile.
  final Map<String, int> dueCounts;
}

const _allDeckKey = '__all__';

class _ReviewDeckPickerScreenState
    extends ConsumerState<ReviewDeckPickerScreen> {
  late Future<_DeckPickerData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_DeckPickerData> _load() async {
    final documentRepository = ref.read(documentRepositoryProvider);
    final wordRepository = ref.read(wordCollectionRepositoryProvider);
    final grammarRepository = ref.read(grammarCollectionRepositoryProvider);
    final now = DateTime.now().toUtc();

    final documents = await documentRepository.listDocuments();

    final dueCounts = <String, int>{
      _allDeckKey:
          (await wordRepository.due(now: now)).length +
          (await grammarRepository.due(now: now)).length,
    };
    for (final document in documents) {
      dueCounts[document.id] =
          (await wordRepository.dueForWork(document.id, now: now)).length +
          (await grammarRepository.dueForWork(document.id, now: now)).length;
    }

    return _DeckPickerData(documents: documents, dueCounts: dueCounts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: FutureBuilder<_DeckPickerData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          final data = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              childAspectRatio: 0.62,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            // +1 for the leading "All" tile.
            itemCount: data.documents.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _DeckTile(
                  title: 'All',
                  dueCount: data.dueCounts[_allDeckKey] ?? 0,
                  cover: const _AllDeckIcon(),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReviewScreen()),
                  ),
                );
              }
              final document = data.documents[index - 1];
              final dueCount = data.dueCounts[document.id] ?? 0;
              return _DeckTile(
                title: document.title,
                dueCount: dueCount,
                cover: _CoverThumbnail(document: document),
                onTap: dueCount == 0
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReviewScreen(
                            workId: document.id,
                            deckTitle: document.title,
                          ),
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}

/// One grid tile: cover (or the "All" icon) + title + a due-count badge,
/// grayed out and untappable when [onTap] is `null` (nothing due).
class _DeckTile extends StatelessWidget {
  const _DeckTile({
    required this.title,
    required this.dueCount,
    required this.cover,
    required this.onTap,
  });

  final String title;
  final int dueCount;
  final Widget cover;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: cover),
                  if (dueCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _DueBadge(count: dueCount),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  const _DueBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// The "All" tile's generic (non-cover) art -- a bordered box matching
/// [_CoverThumbnail]'s own shape/border so both tile kinds sit flush in the
/// same grid.
class _AllDeckIcon extends StatelessWidget {
  const _AllDeckIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: Icon(Icons.all_inclusive, size: 40)),
    );
  }
}

/// Mirrors `LibraryScreen._buildCoverThumbnail` exactly (real cover image
/// when [document] has one, else a bordered per-source-type placeholder
/// icon) -- duplicated rather than shared/extracted, since both are small,
/// self-contained, and this screen has no other reason to depend on
/// `library_screen.dart`.
class _CoverThumbnail extends StatelessWidget {
  const _CoverThumbnail({required this.document});

  final DocumentRow document;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final borderRadius = BorderRadius.circular(12);
        final border = Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 2,
        );
        final placeholder = DecoratedBox(
          decoration: BoxDecoration(border: border, borderRadius: borderRadius),
          child: Center(child: Icon(_iconFor(document.sourceType), size: 40)),
        );

        final path = document.coverImagePath;
        if (path == null) return placeholder;
        return ClipRRect(
          borderRadius: borderRadius,
          child: DecoratedBox(
            decoration: BoxDecoration(border: border),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => placeholder,
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(String sourceType) {
    return switch (DocumentSourceType.values.byName(sourceType)) {
      DocumentSourceType.epub => Icons.menu_book_outlined,
      DocumentSourceType.pdfText => Icons.picture_as_pdf_outlined,
      DocumentSourceType.pdfScanned => Icons.document_scanner_outlined,
    };
  }
}
