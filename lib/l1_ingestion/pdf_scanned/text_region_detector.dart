import 'dart:typed_data';

/// One detected text region on a page, in source-image pixel space
/// (top-left origin, y-down -- matching [OcrRegionResult]'s own documented
/// convention, so building one from this needs no axis flip).
///
/// Axis-aligned only for this pass: real text-detection models (including
/// comic-text-detector, see docs/research/r6-manga-text-detection.md §2)
/// can produce rotated quadrilaterals for angled text (stylized SFX, skewed
/// scans), but light-novel/manga body text -- this project's actual target
/// -- is essentially always axis-aligned even when vertical (a vertical
/// column reads top-to-bottom, but the column itself isn't tilted).
/// Perspective-correcting crops for rotated regions are deliberately out of
/// scope; a detector implementation should reduce a rotated result to its
/// axis-aligned bounding extent rather than fail.
class DetectedTextRegion {
  const DetectedTextRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DetectedTextRegion &&
          other.x == x &&
          other.y == y &&
          other.width == width &&
          other.height == height);

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() =>
      'DetectedTextRegion(x: $x, y: $y, width: $width, height: $height)';
}

/// Finds text regions (speech bubbles, paragraphs, columns) on a rasterized
/// page image, replacing the whole-page-is-one-region stub `ScannedPdfImporter`
/// uses today. See docs/research/r6-manga-text-detection.md for the model
/// this is expected to be backed by (comic-text-detector, ONNX, real
/// pretrained weights already available -- no training/export needed).
///
/// Deliberately a separate interface from [OcrEngine]
/// (`ocr_engine.dart`) rather than folding detection into it: detection and
/// recognition are different models with different inputs (whole page vs.
/// one crop) and different output shapes, and `OcrEngine.recognize`'s
/// existing page-in/regions-out contract already anticipates a real
/// implementation composing a detector step + a recognizer step internally
/// (see that interface's own doc comment) -- this is that detector step,
/// built as its own pluggable piece so it can be developed, tested, and
/// reasoned about independently of whichever [TextRecognizer]
/// (`text_recognizer.dart`) ends up paired with it.
abstract class TextRegionDetector {
  /// [pageImage] is raw BGRA8888 pixel data, exactly `pdfrx_engine`'s
  /// `PdfImage.pixels` layout ([width] * [height] * 4 bytes) -- the same
  /// convention [OcrEngine.recognize] already documents, so a real page
  /// rasterization doesn't need reformatting before reaching either
  /// interface.
  Future<List<DetectedTextRegion>> detect(
    Uint8List pageImage, {
    required int width,
    required int height,
  });
}
