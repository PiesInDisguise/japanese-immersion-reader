import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l1_ingestion/epub/epub_importer.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/card_mode_controller.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/card_mode_screen.dart';

import 'sample_content.dart';
import 'services.dart';

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

  Future<void> _importEpub() => _openDocument(() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );
    final path = result?.files.single.path;
    if (path == null) throw StateError('No file selected.');
    return EpubImporter().import(File(path), onProgress: (_) {});
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Japanese Immersion Reader')),
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
