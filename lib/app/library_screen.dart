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
/// Fetches once, on push, via a plain `Future` rather than a live stream:
/// unlike collection state (which the reader UI needs to reflect live
/// while a book is open), the Library's own contents aren't expected to
/// change while this screen itself is on screen.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  late final Future<List<DocumentRow>> _documentsFuture;

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
                leading: Icon(_iconFor(document.sourceType)),
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
