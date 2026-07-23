import 'dart:io';

import 'package:japanese_immersion_reader/core/models/models.dart';

enum ImportStage { parsing, ocr, indexing, done }

class ImportProgress {
  const ImportProgress({
    required this.fraction,
    required this.stage,
    this.currentChapterIndex,
  });

  /// 0.0-1.0. For scanned-PDF/OCR imports this advances across a background
  /// job and must be safe to report from a non-UI isolate.
  final double fraction;
  final ImportStage stage;
  final int? currentChapterIndex;
}

/// Implemented once per source format (EPUB, PDF text-layer, scanned-PDF/OCR).
/// Every implementation must produce a `Document` that satisfies the shared
/// contract in `test/core/document_contract.dart`, and must derive all
/// Chapter/Block/Sentence IDs via `stableNodeId` — never invent an ad hoc
/// scheme, since Card/Document Mode position-sync and mining/SRS rows key
/// off these IDs staying stable across re-imports.
abstract class Importer {
  Future<Document> import(
    File file, {
    required void Function(ImportProgress progress) onProgress,
  });
}
