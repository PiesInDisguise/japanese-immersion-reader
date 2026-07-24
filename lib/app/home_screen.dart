import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l1_ingestion/epub/epub_importer.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/real_ocr_engine.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/scanned_pdf_importer.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_text/pdf_text_importer.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/card_mode_controller.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/card_mode_screen.dart';
import 'package:japanese_immersion_reader/l5_srs/review_ui/review_screen.dart';
import 'package:path/path.dart' as p;

import 'remote_browse_screen.dart';
import 'sample_content.dart';
import 'services.dart';
import 'settings_screen.dart';

/// The app's entry screen: load a book (the bundled sample fixture, or a
/// real EPUB via the system file picker) and jump into Card Mode.
///
/// **Placeholder, like the rest of `lib/app/`**: there's no Library view
/// (spec §5 -- imported works, cover art, progress%) yet, so this is a
/// straight-to-reading flow rather than a real library. Every import here
/// is in-memory only for this session; nothing is persisted to
/// `AppDatabase`'s `documents`/`chapters`/`sentences` tables yet (that
/// repository layer doesn't exist -- see the Phase 1 plan note about it
/// being deferred until something actually needs to call it. Something
/// now does, but building it is separate work from Card Mode itself).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _openDocument(Future<Document> Function() load) async {
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

  Future<void> _loadSample() => _openDocument(loadSampleBook);

  Future<void> _loadSampleVerticalPdf() =>
      _openDocument(loadSampleVerticalPdf);

  Future<void> _importEpub() => _openDocument(() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );
    final path = result?.files.single.path;
    if (path == null) throw StateError('No file selected.');
    return EpubImporter().import(File(path), onProgress: (_) {});
  });

  Future<void> _importPdf() => _openDocument(() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = result?.files.single.path;
    if (path == null) throw StateError('No file selected.');
    return PdfTextImporter().import(File(path), onProgress: (_) {});
  });

  /// Real OCR (docs/research/r3-ocr.md, r6-manga-text-detection.md):
  /// [RealOcrEngine.create] downloads and loads both real ONNX models
  /// (comic-text-detector region detection + Manga OCR recognition) on
  /// first use -- ~550MB combined, so the first import via this button can
  /// take a while with only the bare spinner below for feedback (no
  /// per-step progress UI exists yet, matching every other import button on
  /// this placeholder screen -- see class doc comment). Subsequent imports
  /// reuse the cached models.
  Future<void> _importScannedPdf() => _openDocument(() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = result?.files.single.path;
    if (path == null) throw StateError('No file selected.');
    return ScannedPdfImporter(
      RealOcrEngine.create,
    ).import(File(path), onProgress: (_) {});
  });

  /// Spec §5's remote book sources: [RemoteBrowseScreen] handles connecting
  /// to/listing/downloading from a WebDAV or OPDS source and pops with the
  /// downloaded local file -- this just picks the right importer by
  /// extension, same as a sideloaded file would get. Scanned/image-only
  /// PDFs aren't auto-detected here (a remote PDF is imported as
  /// text-layer, matching the "Import PDF..." button); use the sideload
  /// flow for a scanned PDF that needs OCR.
  Future<void> _importFromRemote() => _openDocument(() async {
    final file = await Navigator.of(
      context,
    ).push<File>(MaterialPageRoute(builder: (_) => const RemoteBrowseScreen()));
    if (file == null) throw StateError('No book selected.');
    final extension = p.extension(file.path).toLowerCase();
    return switch (extension) {
      '.epub' => EpubImporter().import(file, onProgress: (_) {}),
      '.pdf' => PdfTextImporter().import(file, onProgress: (_) {}),
      _ => throw StateError('Unsupported remote file type: $extension'),
    };
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Japanese Immersion Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading) const CircularProgressIndicator(),
            if (!_loading) ...[
              ElevatedButton(
                onPressed: _loadSample,
                child: const Text('Load Sample Book'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _importEpub,
                child: const Text('Import EPUB...'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _importPdf,
                child: const Text('Import PDF...'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _importScannedPdf,
                child: const Text('Import Scanned PDF (OCR)...'),
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
                  MaterialPageRoute(builder: (_) => const ReviewScreen()),
                ),
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
