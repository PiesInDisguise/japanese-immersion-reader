/// Broad category of the source media a sighting came from. Deliberately
/// distinct from `DocumentSourceType` (`lib/core/models/document.dart`:
/// `epub`/`pdfText`/`pdfScanned`), which describes *ingestion format* -- an
/// orthogonal axis from what spec §11's `sourceRefs.mediaType` needs, which
/// is meant to eventually distinguish light-novel vs. manga vs.
/// video-subtitle *content*. For example, a manga page and a scanned novel
/// page could both ingest as `pdfScanned`/OCR, but are very different
/// "media types" for a review card's "first seen in..." context (spec
/// §11). Reusing `DocumentSourceType` here would conflate those two axes.
///
/// V1 (spec §17) only ever produces light novels, so [lightNovel] is the
/// only variant reachable today; the other two are declared now so adding
/// manga/subtitle sources later needs no schema migration (spec §11's
/// explicit promise) or changes to this enum.
enum CollectionMediaType { lightNovel, manga, videoSubtitle }

/// Spec §11's `sourceRefs[]` entry: `{ workId, sentenceId, mediaType }`.
/// `workId` is a `Documents.id`; `sentenceId` a `Sentences.id` -- both plain
/// strings here (rather than richer references to those rows) since a
/// mining call only ever has the ids on hand from the reading UI, not full
/// rows.
class SourceRef {
  const SourceRef({
    required this.workId,
    required this.sentenceId,
    required this.mediaType,
  });

  final String workId;
  final String sentenceId;
  final CollectionMediaType mediaType;
}
