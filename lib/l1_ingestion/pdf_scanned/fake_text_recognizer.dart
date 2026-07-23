import 'dart:typed_data';

import 'text_recognizer.dart';

/// Deterministic [TextRecognizer] test double: no real ONNX inference,
/// canned output only, so code that composes a [TextRecognizer] (e.g. a
/// future detector+recognizer-backed `OcrEngine`) is testable without
/// downloading or running the real ~450MB Manga OCR model -- see
/// docs/research/r3-ocr.md and `MangaOcrRecognizer`
/// (`manga_ocr_recognizer.dart`) for the real implementation this stands in
/// for.
///
/// Output is a pure function of each call's own arguments -- **never** of
/// hidden mutable state -- mirroring [FakeOcrEngine]'s doc comment
/// (`fake_ocr_engine.dart`) and for the same reason: a real caller of a
/// [TextRecognizer] is expected to eventually invoke it across an isolate
/// boundary (see `ScannedPdfImporter`'s doc comment on `Isolate.run` sending
/// a *copy* of its injected engine per call), which only ever receives
/// copies -- a "return the Nth canned response" fake keyed off an internal
/// counter would silently never advance past response zero, since each
/// call's mutation would land only on that call's own throwaway copy.
/// Keying canned responses off [width]/[height] instead sidesteps this
/// entirely, since those genuinely arrive fresh with every call.
class FakeTextRecognizer implements TextRecognizer {
  /// [textForCropSize], if given, selects canned output by the calling
  /// crop's exact `(width, height)` in pixels -- the only per-call
  /// information available to key off without inspecting pixel content
  /// (which callers are free to leave as meaningless synthetic bytes; see
  /// class doc comment). Falls back to [defaultText]/[defaultConfidence]
  /// for any size not present in the map.
  const FakeTextRecognizer({
    this.textForCropSize,
    this.defaultText = 'テスト',
    this.defaultConfidence = 0.9,
  });

  final Map<(int, int), RecognizedText>? textForCropSize;
  final String defaultText;
  final double defaultConfidence;

  @override
  Future<RecognizedText> recognizeCrop(
    Uint8List cropPixels, {
    required int width,
    required int height,
    required bool vertical,
  }) async {
    final bySize = textForCropSize?[(width, height)];
    if (bySize != null) return bySize;
    return RecognizedText(text: defaultText, confidence: defaultConfidence);
  }
}
