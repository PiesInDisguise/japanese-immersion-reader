import 'dart:typed_data';

/// One recognized text region on a rasterized page image.
///
/// A real region-detection step (out of scope for this pass -- see
/// [ScannedPdfImporter]) would eventually produce several of these per page,
/// one per paragraph/speech-bubble/column. This pass's importer only ever
/// asks an [OcrEngine] to recognize a single whole-page region, but the
/// shape supports multiple regions per page so a later phase can add real
/// region detection without changing this interface.
///
/// Coordinates are raster pixels in the source page image's coordinate
/// space: top-left origin, y growing downward. That is OCR's natural
/// convention and already matches [SourceRect]'s documented convention
/// project-wide, so building a `SourceRect` from one of these needs no
/// axis flip -- unlike the PDF-text-layer importer, which must flip
/// PDFium's bottom-left/y-up coordinates before storing them.
class OcrRegionResult {
  const OcrRegionResult({
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
  });

  /// Recognized text for this region, in reading order. May span several
  /// sentences; the importer runs `splitIntoSentenceSpans` over it to
  /// produce one or more `Sentence`s.
  final String text;

  /// Region bounding box in source-image pixels, top-left origin, y-down.
  final double x;
  final double y;
  final double width;
  final double height;

  /// 0.0-1.0, engine-defined confidence for [text] as a whole.
  ///
  /// This is necessarily a *region*-level signal, not a per-character or
  /// per-token one: Tesseract can natively produce finer-grained
  /// (word/symbol) confidence, but Manga OCR is a generative decoder that
  /// only naturally yields a confidence per decoded character, before
  /// L2/Sudachi has split anything into tokens. Squaring that away for the
  /// two backends is real, backend-specific alignment work explicitly
  /// deferred past this pass (see docs/research/r3-ocr.md §4) -- for now,
  /// every `Token` sliced out of this region's `text` inherits this same
  /// single [confidence] value verbatim.
  final double confidence;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OcrRegionResult &&
          other.text == text &&
          other.x == x &&
          other.y == y &&
          other.width == width &&
          other.height == height &&
          other.confidence == confidence);

  @override
  int get hashCode => Object.hash(text, x, y, width, height, confidence);

  @override
  String toString() =>
      'OcrRegionResult(text: $text, x: $x, y: $y, width: $width, '
      'height: $height, confidence: $confidence)';
}

/// Recognizes text regions on a single rasterized page image.
///
/// This is the plug point real OCR backends (Manga OCR via ONNX Runtime,
/// Tesseract `jpn`/`jpn_vert`) will implement in a later phase -- see
/// docs/research/r3-ocr.md, which found real integration heavy enough
/// (Manga OCR needs a hand-ported autoregressive decode loop; neither
/// backend's isolate-safety is verified on a real device) to explicitly
/// defer past this pass. This pass ships only the interface and
/// [FakeOcrEngine], a deterministic test double, so the orchestration
/// around this plug point (background isolate hand-off, disk caching,
/// progress reporting, confidence flow-through to `Token`) is fully
/// testable now without a real model.
abstract class OcrEngine {
  /// Recognizes text in [pageImage], a page rasterized by the importer.
  ///
  /// [pageImage] is raw BGRA8888 pixel data, exactly `pdfrx_engine`'s
  /// `PdfImage.pixels` layout ([width] * [height] * 4 bytes) -- the
  /// importer hands it over unmodified rather than re-encoding it, so a
  /// real engine implementation is responsible for converting this into
  /// whatever input its model actually needs (a resized/normalized tensor
  /// for Manga OCR's ViT encoder; whatever pixel format the Tesseract
  /// plugin's channel call expects). Neither real backend accepts raw BGRA
  /// natively, so that conversion is explicitly this engine's job, not the
  /// importer's -- see docs/research/r3-ocr.md §1.1, §1.5.
  ///
  /// [vertical] tells the engine which reading direction to assume.
  /// Tesseract in particular cannot reliably detect this itself and reads
  /// vertical text horizontally if not told (r3-ocr.md §2.2). Full
  /// per-region orientation detection is out of scope for this pass; see
  /// [ScannedPdfImporter]'s doc comment for what it passes instead.
  ///
  /// The importer calls this on a background isolate (see
  /// [ScannedPdfImporter]) so implementations must not assume they are
  /// running on the root/UI isolate, and must not rely on mutable state
  /// surviving between calls -- each call may run in a fresh isolate that
  /// only received a *copy* of this engine, so any state mutated during one
  /// call is invisible both to the next call and to the caller. See
  /// [FakeOcrEngine]'s doc comment for the same constraint from the test
  /// double's side.
  Future<List<OcrRegionResult>> recognize(
    Uint8List pageImage, {
    required int width,
    required int height,
    required bool vertical,
  });
}
