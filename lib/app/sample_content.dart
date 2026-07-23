import 'dart:io';

import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/l1_ingestion/epub/epub_importer.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_text/pdf_text_importer.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_importer.dart';

import 'package:japanese_immersion_reader/core/models/models.dart';

/// Seeds the dictionary-lookup fixture used across this project's own test
/// suite (`test/l2_linguistics/dictionary/fixture_generator.dart`) into
/// [db], if no dictionary is installed yet.
///
/// **Placeholder, like `dictionary_paths.dart`**: there's no dictionary
/// *import UI* yet (spec §10), so without this there'd be nothing to look
/// up when manually exercising Card Mode. Uses this project's own test
/// fixture rather than a real Yomitan dictionary specifically so every word
/// it makes look-up-able is known, original content (not third-party
/// dictionary data) -- see that generator's own doc comment for why. Real
/// dictionary import (a file picker + `DictionaryImporter`, no different in
/// principle from [loadSampleBook] below) is future UI work.
Future<void> seedSampleDictionaryIfEmpty(AppDatabase db) async {
  final existing = await db.select(db.dictionaries).get();
  if (existing.isNotEmpty) return;

  final fixture = File('assets/fixtures/yomitan_sample_dictionary.zip');
  if (!await fixture.exists()) return;

  await DictionaryImporter(db).import(fixture);
}

/// Loads the same ruby-annotated EPUB fixture
/// `test/l1_ingestion/epub/epub_importer_test.dart` itself tests against,
/// so Card Mode has something real (multiple sentences, real furigana) to
/// display without a file-picker-based import flow existing yet.
Future<Document> loadSampleBook() {
  return EpubImporter().import(
    File('assets/fixtures/epub_ruby_forms.epub'),
    onProgress: (_) {},
  );
}

/// Loads one of the synthetic vertical-writing-mode (縦書き) PDF fixtures
/// `test/l1_ingestion/pdf_text/pdf_text_importer_test.dart` itself tests
/// against, via [PdfTextImporter], so Document Mode's vertical-text
/// rendering (`lib/l3_reader_ui/vertical_text/`) has something real -- real
/// per-character geometry and a real `Block.direction ==
/// WritingDirection.vertical`, reconstructed by
/// `l1_ingestion/pdf_text/reading_order.dart` -- to render end-to-end for
/// manual/test verification, without a real scanned or authored
/// vertical-writing-mode PDF existing yet (that fixture gap is a separately
/// flagged, deferred research risk -- see docs/research/r2-pdf-text.md §6).
Future<Document> loadSampleVerticalPdf() {
  return PdfTextImporter().import(
    File('assets/fixtures/synthetic_vertical_sim_ja.pdf'),
    onProgress: (_) {},
  );
}
