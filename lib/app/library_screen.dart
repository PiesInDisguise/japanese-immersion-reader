import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';

import 'services.dart';

/// Every previously-imported book, as a shelf of cover cards, so the reader
/// doesn't have to re-pick/re-import the same file just to keep reading it.
/// Pops itself with the tapped document's id (via [Navigator.pop]) rather
/// than navigating onward itself -- mirrors `RemoteBrowseScreen`'s own "pop
/// with a picked value" pattern -- so `HomeScreen` stays the single place
/// that knows how to turn a `Document` into an open reading session.
///
/// Each card shows a real cover thumbnail where one was auto-extracted at
/// import time (or previously user-picked), falling back to a bordered
/// per-source-type placeholder icon otherwise, with the title below. Tap a
/// card to open that book; long-press it to pick a custom cover image (see
/// [_pickCustomCover]) -- tap is the card's primary, most-discoverable
/// action once the cover fills the whole card (unlike the previous
/// row-based layout, where the cover was a small leading icon and tapping
/// it specifically to customize didn't compete with opening the book).
///
/// Fetches once, on push, via a plain `Future` rather than a live stream:
/// unlike collection state (which the reader UI needs to reflect live
/// while a book is open), the Library's own contents aren't expected to
/// change while this screen itself is on screen -- a custom-cover pick is
/// the one deliberate exception, which manually refreshes it in place.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  // Not `late final` -- a custom-cover pick (see `_pickCustomCover`) needs
  // to reassign this to refresh the list while this screen is still open, a
  // deliberate one-off exception to this screen's own "fetch once, no live
  // stream" doc comment (that reasoning is about *other* screens' actions,
  // not a direct user action taken right here).
  late Future<List<DocumentRow>> _documentsFuture;

  @override
  void initState() {
    super.initState();
    _documentsFuture = ref.read(documentRepositoryProvider).listDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: FutureBuilder<List<DocumentRow>>(
        future: _documentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          final documents = snapshot.data ?? const [];
          if (documents.isEmpty) {
            return const Center(
              child: Text('No books yet -- import one to get started.'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              childAspectRatio: 0.62,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              // Tapping anywhere on the card (cover or title) opens the
              // book -- the primary, most-discoverable action once a card
              // is dominated by its cover art. Long-pressing specifically
              // on the cover picks a custom image instead; a plain
              // GestureDetector there (rather than a second InkWell) is
              // enough since the outer InkWell's own splash already covers
              // the whole card visually.
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).pop(document.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onLongPress: () => _pickCustomCover(document),
                        child: _buildCoverThumbnail(document),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      document.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// A real cover image if [document] has one (auto-extracted at import
  /// time, or previously picked by the user), filling the whole card, else
  /// a bordered placeholder box with the per-source-type icon centered in
  /// it. `errorBuilder` -- not a synchronous `existsSync()` pre-check -- is
  /// the built-in mechanism `Image.file` already provides for "the cover
  /// file is missing," e.g. if it was deleted from disk outside the app.
  Widget _buildCoverThumbnail(DocumentRow document) {
    final borderRadius = BorderRadius.circular(12);
    final border = Border.all(
      color: Theme.of(context).colorScheme.outline,
      width: 2,
    );
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(border: border, borderRadius: borderRadius),
      child: Center(
        child: Icon(_iconFor(document.sourceType), size: 40),
      ),
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
  }

  /// Long-pressing a card's cover lets the user pick their own image, which
  /// then overrides any auto-extracted cover -- `updateCoverImagePath`
  /// always wins unconditionally, unlike import-time auto-extraction's
  /// `setAutoExtractedCoverIfAbsent`. Refreshes [_documentsFuture] so the
  /// new cover shows immediately without leaving and reopening this screen.
  Future<void> _pickCustomCover(DocumentRow document) async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final bytes = await File(path).readAsBytes();
    final storedPath = await ref
        .read(coverArtStoreProvider)
        .write(document.id, bytes);
    await ref
        .read(documentRepositoryProvider)
        .updateCoverImagePath(document.id, storedPath);
    if (!mounted) return;
    setState(() {
      _documentsFuture = ref.read(documentRepositoryProvider).listDocuments();
    });
  }

  IconData _iconFor(String sourceType) {
    return switch (DocumentSourceType.values.byName(sourceType)) {
      DocumentSourceType.epub => Icons.menu_book_outlined,
      DocumentSourceType.pdfText => Icons.picture_as_pdf_outlined,
      DocumentSourceType.pdfScanned => Icons.document_scanner_outlined,
    };
  }
}
