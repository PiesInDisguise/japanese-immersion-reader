import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';

import 'services.dart';

/// Every previously-imported book, so the reader doesn't have to re-pick/
/// re-import the same file just to keep reading it. Pops itself with the
/// tapped document's id (via [Navigator.pop]) rather than navigating
/// onward itself -- mirrors `RemoteBrowseScreen`'s own "pop with a picked
/// value" pattern -- so `HomeScreen` stays the single place that knows how
/// to turn a `Document` into an open reading session.
///
/// Each row shows a real cover thumbnail where one was auto-extracted at
/// import time (or previously user-picked), falling back to a
/// per-source-type placeholder icon otherwise -- tapping that thumbnail
/// lets the user pick their own custom image (see [_pickCustomCover]).
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

          return ListView.separated(
            itemCount: documents.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final document = documents[index];
              return ListTile(
                leading: InkWell(
                  onTap: () => _pickCustomCover(document),
                  child: _buildCoverThumbnail(document),
                ),
                title: Text(document.title),
                subtitle: Text(_formatDate(document.updatedAt)),
                onTap: () => Navigator.of(context).pop(document.id),
              );
            },
          );
        },
      ),
    );
  }

  /// A real cover image if [document] has one (auto-extracted at import
  /// time, or previously picked by the user), else the per-source-type
  /// placeholder icon. `errorBuilder` -- not a synchronous `existsSync()`
  /// pre-check -- is the built-in mechanism `Image.file` already provides
  /// for "the cover file is missing," e.g. if it was deleted from disk
  /// outside the app.
  Widget _buildCoverThumbnail(DocumentRow document) {
    final placeholder = Icon(_iconFor(document.sourceType));
    final path = document.coverImagePath;
    if (path == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.file(
        File(path),
        width: 40,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }

  /// Tapping a book's cover thumbnail/placeholder (the user's confirmed
  /// choice of where this affordance should live, over a long-press menu or
  /// a separate edit icon) lets them pick their own image, which then
  /// overrides any auto-extracted cover -- `updateCoverImagePath` always
  /// wins unconditionally, unlike import-time auto-extraction's
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

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${pad(local.month)}-${pad(local.day)}';
  }
}
