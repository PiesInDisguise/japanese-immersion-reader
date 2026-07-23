import 'dart:typed_data';

import 'text_region_detector.dart';

/// Deterministic [TextRegionDetector] test double: no real model, canned
/// output only -- mirrors [FakeOcrEngine]'s (`fake_ocr_engine.dart`) style and
/// its reasoning applies here verbatim, so see that class's doc comment for
/// the full explanation. Short version: output is a pure function of each
/// call's own arguments, **never** hidden mutable call-count state, because
/// a real detector composed alongside a real [OcrEngine] (`ocr_engine.dart`)
/// is expected to eventually run the same way `ScannedPdfImporter` already
/// runs OCR -- on a background isolate via `Isolate.run`, which sends a
/// *copy* of whatever's injected into a fresh isolate per call. A "return the
/// Nth canned response" fake keyed off an internal counter would silently
/// never advance past response zero in that world; keying off
/// [width]/[height] instead sidesteps this entirely, since those genuinely
/// arrive fresh with every call.
class FakeTextRegionDetector implements TextRegionDetector {
  /// [regionsForPageSize], if given, selects canned output by the calling
  /// page's exact `(width, height)` in pixels -- the only per-call
  /// information available to key off without inspecting pixel content
  /// (which callers are free to leave as meaningless synthetic bytes; see
  /// class doc comment). Falls back to [defaultRegions] for any size not
  /// present in the map, and to a single region spanning the whole page --
  /// matching `ScannedPdfImporter`'s current whole-page-is-one-region stub,
  /// so this fake's own default behaves like "detection not wired up yet" --
  /// if neither is given.
  const FakeTextRegionDetector({this.regionsForPageSize, this.defaultRegions});

  final Map<(int, int), List<DetectedTextRegion>>? regionsForPageSize;
  final List<DetectedTextRegion>? defaultRegions;

  @override
  Future<List<DetectedTextRegion>> detect(
    Uint8List pageImage, {
    required int width,
    required int height,
  }) async {
    final bySize = regionsForPageSize?[(width, height)];
    if (bySize != null) return bySize;
    final defaults = defaultRegions;
    if (defaults != null) return defaults;
    return [
      DetectedTextRegion(
        x: 0,
        y: 0,
        width: width.toDouble(),
        height: height.toDouble(),
      ),
    ];
  }
}
