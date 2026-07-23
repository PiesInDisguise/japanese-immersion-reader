import 'dart:typed_data';

/// One region's recognized text, before it's attached to any [Token]/
/// `SourceRect` -- that assembly is the composing [OcrEngine]'s job, not
/// this interface's.
class RecognizedText {
  const RecognizedText({required this.text, required this.confidence});

  /// Recognized text for the crop, in reading order.
  final String text;

  /// 0.0-1.0, engine-defined confidence for [text] as a whole. See
  /// [OcrRegionResult.confidence]'s doc comment (`ocr_engine.dart`) for why
  /// this is necessarily region/crop-level rather than per-character or
  /// per-token, and docs/research/r3-ocr.md §4 for the confidence-alignment
  /// design this still needs downstream.
  final double confidence;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecognizedText &&
          other.text == text &&
          other.confidence == confidence);

  @override
  int get hashCode => Object.hash(text, confidence);

  @override
  String toString() => 'RecognizedText(text: $text, confidence: $confidence)';
}

/// Recognizes the text within a single, already-cropped region image --
/// unlike [OcrEngine] (`ocr_engine.dart`), which operates on a whole page
/// and returns multiple regions. See [TextRegionDetector]
/// (`text_region_detector.dart`) for why detection and recognition are
/// separate interfaces rather than one.
///
/// Expected to be backed by Manga OCR via ONNX Runtime
/// (docs/research/r3-ocr.md §1) -- a generative vision-encoder/char-decoder
/// model, not a single-pass classifier, so a real implementation owns a
/// full autoregressive decode loop, character-level tokenizer, and text
/// postprocessing (whitespace/punctuation normalization, half-to-full-width
/// conversion) in addition to the ONNX Runtime session calls themselves; see
/// that research doc's §1.1 for the exact reference behavior to match.
abstract class TextRecognizer {
  /// [cropPixels] is raw BGRA8888 pixel data ([width] * [height] * 4 bytes),
  /// already cropped to one [DetectedTextRegion] -- the same raw-pixel
  /// convention [OcrEngine.recognize] and [TextRegionDetector.detect] use,
  /// so no reformatting is needed between detection, cropping, and
  /// recognition.
  ///
  /// [vertical] tells the engine which reading direction to assume, same
  /// meaning as [OcrEngine.recognize]'s own `vertical` parameter.
  Future<RecognizedText> recognizeCrop(
    Uint8List cropPixels, {
    required int width,
    required int height,
    required bool vertical,
  });
}
