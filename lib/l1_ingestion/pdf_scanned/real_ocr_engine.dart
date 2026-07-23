import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'comic_text_detector.dart';
import 'manga_ocr_recognizer.dart';
import 'ocr_engine.dart';
import 'text_recognizer.dart';
import 'text_region_detector.dart';

/// The real [OcrEngine]: composes a [TextRegionDetector] (real detection
/// model: [ComicTextDetector]) and a [TextRecognizer] (real recognition
/// model: [MangaOcrRecognizer]) to fulfill [OcrEngine.recognize]'s existing
/// page-in/regions-out contract, exactly as that interface's own doc
/// comment already anticipated: "a real implementation composing detection
/// + recognition internally."
///
/// For each page: detect regions, crop each one out of the page image, and
/// recognize each crop independently. A crop that fails to recognize (or
/// crop) is skipped rather than aborting the whole page -- the same
/// per-page resilience philosophy `ScannedPdfImporter` already applies one
/// level up (one bad page doesn't abort a whole document), applied one
/// level down (one bad region doesn't lose a page's other, good regions).
///
/// For real usage, construct via [create], not the bare constructor --
/// [MangaOcrRecognizer]'s own setup is real async work (model download +
/// ONNX session creation). [create] itself is the [OcrEngineFactory]
/// `ScannedPdfImporter` should be given (e.g.
/// `ScannedPdfImporter(RealOcrEngine.create)`), so that work happens once,
/// inside `OcrWorker`'s worker isolate -- see that class's own doc comment
/// for why it must happen there and not before.
///
/// The bare constructor takes an already-built [TextRegionDetector]/
/// [TextRecognizer] directly -- used by [create] itself, and by tests that
/// need to inject fakes (`FakeTextRegionDetector`/`FakeTextRecognizer`)
/// rather than pay for real models just to exercise this class's own
/// crop/compose/skip-bad-region logic.
class RealOcrEngine implements OcrEngine {
  // Not `this._detector`/`this._recognizer` initializing formals: the
  // public constructor parameter names (`detector`/`recognizer`) are
  // deliberately not private, so callers outside this library -- e.g.
  // `real_ocr_engine_test.dart` -- can use them as named arguments.
  RealOcrEngine({required TextRegionDetector detector, required TextRecognizer recognizer})
    : _detector = detector, // ignore: prefer_initializing_formals
      _recognizer = recognizer; // ignore: prefer_initializing_formals

  final TextRegionDetector _detector;
  final TextRecognizer _recognizer;

  /// Builds a ready [RealOcrEngine]: a [ComicTextDetector] (lazy -- its own
  /// ONNX session loads on first [detect] call, not here) and a real,
  /// eagerly-initialized [MangaOcrRecognizer] (see that class's own doc
  /// comment for why it loads eagerly instead).
  static Future<OcrEngine> create() async {
    final detector = ComicTextDetector();
    final recognizer = await MangaOcrRecognizer.create();
    return RealOcrEngine(detector: detector, recognizer: recognizer);
  }

  @override
  Future<List<OcrRegionResult>> recognize(
    Uint8List pageImage, {
    required int width,
    required int height,
    required bool vertical,
  }) async {
    final regions = await _detector.detect(pageImage, width: width, height: height);

    final results = <OcrRegionResult>[];
    for (final region in regions) {
      try {
        final crop = _cropRegion(
          pageImage,
          pageWidth: width,
          pageHeight: height,
          region: region,
        );
        if (crop == null) continue;

        final recognized = await _recognizer.recognizeCrop(
          crop.pixels,
          width: crop.width,
          height: crop.height,
          vertical: vertical,
        );
        if (recognized.text.isEmpty) continue;

        results.add(
          OcrRegionResult(
            text: recognized.text,
            x: region.x,
            y: region.y,
            width: region.width,
            height: region.height,
            confidence: recognized.confidence,
          ),
        );
      } catch (_) {
        // One bad region must not lose the rest of this page's regions --
        // see class doc comment.
        continue;
      }
    }
    return results;
  }

  /// Crops [region] out of [pageImage] (raw BGRA8888, `pageWidth *
  /// pageHeight * 4` bytes -- same convention every raw-pixel interface in
  /// this project uses), returning `null` for a region that, after rounding
  /// and clamping to the page's actual bounds, has no real extent left (an
  /// edge case defended against rather than assumed away, even though
  /// [ComicTextDetector]'s own postprocessing already clamps/drops
  /// degenerate boxes -- a differently-behaved [TextRegionDetector]
  /// implementation is not guaranteed to).
  ({Uint8List pixels, int width, int height})? _cropRegion(
    Uint8List pageImage, {
    required int pageWidth,
    required int pageHeight,
    required DetectedTextRegion region,
  }) {
    final x = region.x.round().clamp(0, pageWidth);
    final y = region.y.round().clamp(0, pageHeight);
    final right = (region.x + region.width).round().clamp(0, pageWidth);
    final bottom = (region.y + region.height).round().clamp(0, pageHeight);
    final width = right - x;
    final height = bottom - y;
    if (width <= 0 || height <= 0) return null;

    final page = img.Image.fromBytes(
      width: pageWidth,
      height: pageHeight,
      bytes: pageImage.buffer,
      bytesOffset: pageImage.offsetInBytes,
      order: img.ChannelOrder.bgra,
      numChannels: 4,
    );
    final cropped = img.copyCrop(page, x: x, y: y, width: width, height: height);
    final pixels = cropped.getBytes(order: img.ChannelOrder.bgra);
    return (pixels: pixels, width: width, height: height);
  }
}
