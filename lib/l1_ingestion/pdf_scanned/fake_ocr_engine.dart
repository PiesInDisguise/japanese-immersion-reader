import 'dart:typed_data';

import 'ocr_engine.dart';

/// Deterministic [OcrEngine] test double: no real OCR model, canned output
/// only, so [ScannedPdfImporter]'s orchestration (isolate hand-off, disk
/// cache, progress reporting, confidence flow-through to `Token`) is
/// testable without a real backend -- see docs/research/r3-ocr.md for why
/// wiring a real backend is deferred past this pass.
///
/// Output is a pure function of each call's own arguments -- **never** of
/// hidden mutable call-count state -- because [ScannedPdfImporter] invokes
/// [recognize] via `Isolate.run`, which sends a *copy* of this engine into a
/// fresh, short-lived isolate for every single call. Any field this engine
/// mutated during one call would be mutated only on that call's throwaway
/// copy; the next call (and the caller back on the calling isolate) would
/// never see it. A "return the Nth canned response" fake keyed off an
/// internal counter would silently never advance past response zero. Keying
/// canned responses off [width]/[height] instead sidesteps this entirely,
/// since those genuinely arrive fresh with every call.
class FakeOcrEngine implements OcrEngine {
  /// [regionsForPageSize], if given, selects canned output by the calling
  /// page's exact `(width, height)` in pixels -- the only per-call
  /// information available to key off without inspecting pixel content
  /// (which callers are free to leave as meaningless synthetic bytes; see
  /// class doc comment). Falls back to [defaultRegions] for any size not
  /// present in the map, and to a single canned region spanning the whole
  /// page if neither is given.
  const FakeOcrEngine({
    this.regionsForPageSize,
    this.defaultRegions,
    this.defaultConfidence = 0.9,
  });

  final Map<(int, int), List<OcrRegionResult>>? regionsForPageSize;
  final List<OcrRegionResult>? defaultRegions;

  /// Confidence used by the built-in fallback canned region (i.e. when
  /// neither [regionsForPageSize] nor [defaultRegions] supplies one).
  final double defaultConfidence;

  @override
  Future<List<OcrRegionResult>> recognize(
    Uint8List pageImage, {
    required int width,
    required int height,
    required bool vertical,
  }) async {
    final bySize = regionsForPageSize?[(width, height)];
    if (bySize != null) return bySize;
    final defaults = defaultRegions;
    if (defaults != null) return defaults;
    return [
      OcrRegionResult(
        text: 'テスト',
        x: 0,
        y: 0,
        width: width.toDouble(),
        height: height.toDouble(),
        confidence: defaultConfidence,
      ),
    ];
  }
}
