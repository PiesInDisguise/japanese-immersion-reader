import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l1_ingestion/cover_art_extractor.dart';
import 'package:japanese_immersion_reader/l1_ingestion/unified_importer.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/card_mode_screen.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/reading_position.dart';
import 'package:japanese_immersion_reader/l5_srs/review_ui/review_deck_picker_screen.dart';

import 'library_screen.dart';
import 'remote_browse_screen.dart';
import 'sample_content.dart';
import 'services.dart';
import 'settings_screen.dart';
import 'stats/stats_screen.dart';

/// The app's entry screen: load a book (from the Library, the bundled
/// sample fixture, or a real import) and jump into Card Mode.
///
/// **Still a placeholder in spirit** (spec §5's progress % per book isn't
/// shown), but every import now persists via `DocumentRepository`, can be
/// reopened without re-picking the source file, shows a real cover
/// thumbnail where one could be extracted (`LibraryScreen`), and resumes
/// at the exact sentence the reader last left off at.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _openDocument(
    Future<Document> Function() load, {
    Future<void> Function(Document document)? afterSave,
  }) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await seedSampleDictionaryIfEmpty(ref.read(appDatabaseProvider));
      final document = await load();
      ref.read(currentDocumentProvider.notifier).set(document);
      // Mining only ever stores a sentence's id (spec §11's sourceRefs), not
      // its text -- persisting the document here is what lets a review card
      // resolve that id back to real content later (spec §12's "original
      // source sentence built in as context"), long after this in-memory
      // Document is gone. See DocumentRepository's own doc comment.
      await ref.read(documentRepositoryProvider).save(document);
      if (afterSave != null) await afterSave(document);

      // Spec §5: resume where a prior session left off. Read AFTER save()
      // so this document's row is guaranteed to exist -- both this read and
      // any later write for this session go through
      // currentSentencePositionProvider (see reading_position.dart), which
      // Card/Document Mode's controllers already read as their starting
      // position on first build.
      final lastSentenceId = await ref
          .read(documentRepositoryProvider)
          .lastSentenceId(document.id);
      ref.read(currentSentencePositionProvider.notifier).set(lastSentenceId);

      if (mounted) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CardModeScreen()));
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// The Library's own "tap to reopen" flow: pushes [LibraryScreen], which
  /// pops with the tapped document's id (or `null` if the user backed out
  /// without picking one), then reuses [_openDocument] unchanged --
  /// reopening a previously-imported book funnels through exactly the same
  /// pipeline (seed dictionary, set `currentDocumentProvider`, re-`save`,
  /// push `CardModeScreen`) a fresh import does, just with
  /// `DocumentRepository.loadDocument` standing in for an `Importer`.
  Future<void> _openLibrary() async {
    final documentId = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const LibraryScreen()));
    if (documentId == null) return;
    await _openDocument(() async {
      final document = await ref
          .read(documentRepositoryProvider)
          .loadDocument(documentId);
      if (document == null) {
        throw StateError('That book is no longer available.');
      }
      return document;
    });
  }

  Future<void> _loadSample() => _openDocument(loadSampleBook);

  Future<void> _loadSampleVerticalPdf() => _openDocument(loadSampleVerticalPdf);

  /// One button for every sideloaded source format: [importAnyFile] inspects
  /// the picked file's extension and, for a `.pdf`, its actual text-layer
  /// content, to route to [EpubImporter]/[PdfTextImporter]/
  /// [ScannedPdfImporter] automatically -- the reader never has to know or
  /// pick which importer a given file needs.
  ///
  /// Real OCR (docs/research/r3-ocr.md, r6-manga-text-detection.md): if the
  /// picked file turns out to be a scanned PDF, `RealOcrEngine.create` (the
  /// default `ocrEngineFactory`) downloads and loads both real ONNX models
  /// (comic-text-detector region detection + Manga OCR recognition) on first
  /// use -- ~550MB combined, so that first import can take a while with only
  /// the bare spinner below for feedback (no per-step progress UI exists yet,
  /// matching every other import button on this placeholder screen -- see
  /// class doc comment). Subsequent imports reuse the cached models.
  /// The picker itself runs *before* [_openDocument] (not inside its `load`
  /// callback) so backing out of it -- a normal, expected action, not an
  /// error -- just quietly does nothing, mirroring [_openLibrary]'s own
  /// "nothing picked -> return" handling instead of surfacing a scary
  /// "No file selected" error box.
  Future<void> _importBook() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub', 'pdf'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    final importedFile = File(path);
    await _openDocument(
      () => importAnyFile(importedFile, onProgress: (_) {}),
      afterSave: (document) => _extractAndStoreCover(document, importedFile),
    );
  }

  /// Spec §5's remote book sources: [RemoteBrowseScreen] handles connecting
  /// to/listing/downloading from a WebDAV or OPDS source and pops with the
  /// downloaded local file -- this hands it to the same [importAnyFile]
  /// routing the sideload button uses, including scanned-PDF detection.
  /// Same "back out -> do nothing" reasoning as [_importBook].
  Future<void> _importFromRemote() async {
    final file = await Navigator.of(
      context,
    ).push<File>(MaterialPageRoute(builder: (_) => const RemoteBrowseScreen()));
    if (file == null) return;
    await _openDocument(
      () => importAnyFile(file, onProgress: (_) {}),
      afterSave: (document) => _extractAndStoreCover(document, file),
    );
  }

  /// Best-effort Library cover-art extraction (see `extractCoverArt`'s own
  /// doc comment) -- only possible right here, where a real source [File]
  /// still exists; a Library reopen loads from the database with no file to
  /// re-extract from, and the bundled samples are in-memory `Document`s
  /// with no file at all. Only sets the cover if [document] doesn't already
  /// have a user-picked one (`setAutoExtractedCoverIfAbsent`), and swallows
  /// every failure -- a missing/broken cover must never surface as an
  /// import error.
  Future<void> _extractAndStoreCover(Document document, File? file) async {
    if (file == null) return;
    final bytes = await extractCoverArt(file);
    if (bytes == null) return;
    final path = await ref
        .read(coverArtStoreProvider)
        .write(document.id, bytes);
    await ref
        .read(documentRepositoryProvider)
        .setAutoExtractedCoverIfAbsent(document.id, path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Japanese Immersion Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading) const CircularProgressIndicator(),
            if (!_loading) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.collections_bookmark_outlined),
                label: const Text('Library'),
                onPressed: _openLibrary,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadSample,
                child: const Text('Load Sample Book'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _importBook,
                child: const Text('Import Book...'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _importFromRemote,
                child: const Text('Browse Remote Source...'),
              ),
              const SizedBox(height: 12),
              // Not a polished library entry -- like the rest of this
              // placeholder screen (see class doc comment) -- just a
              // genuinely reachable way to manually verify Document Mode's
              // vertical-text (縦書き) rendering end-to-end, since no real
              // scanned/authored vertical PDF fixture exists yet (see
              // `sample_content.dart`'s own doc comment on
              // `loadSampleVerticalPdf`).
              TextButton(
                onPressed: _loadSampleVerticalPdf,
                child: const Text('Load Sample Vertical PDF'),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.style_outlined),
                label: const Text('Review'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ReviewDeckPickerScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.bar_chart_outlined),
                label: const Text('Stats'),
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const StatsScreen())),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
