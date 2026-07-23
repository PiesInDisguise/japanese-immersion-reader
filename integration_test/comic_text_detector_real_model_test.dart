// Real end-to-end verification of ComicTextDetector: real network download
// of the ~90MB pretrained ONNX weights, a real `flutter_onnxruntime`
// `OrtSession` loaded from them, and real inference against a real rendered
// page image -- nothing mocked or faked.
//
// This has to live under `integration_test/`, not plain `flutter_test`:
// both `path_provider` (which `ModelFetcher` uses to resolve the cache
// directory) and `flutter_onnxruntime` (which `ComicTextDetector` uses for
// the actual ONNX session) are MethodChannel-based plugins. Confirmed
// directly in this environment that both throw `MissingPluginException`
// under plain `flutter test` (no running app/engine to dispatch the channel
// call to) -- there is no way to exercise real inference outside a real
// running app, which is exactly what `integration_test` provides (see
// `app_test.dart`'s own doc comment for the same reasoning applied to a
// different real backend).
//
// Run with: flutter test integration_test/comic_text_detector_real_model_test.dart -d windows
//
// First run downloads the real model to the application support directory
// and caches it there (same fetch-on-first-use pattern as the Yomitan/
// Sudachi dictionary assets) -- expect a real, possibly slow, one-time
// network download; subsequent runs reuse the cached file.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/comic_text_detector.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/model_fetcher.dart';
import 'package:path/path.dart' as p;

/// Renders a real, visible-text page via Flutter's own text-painting/
/// rendering pipeline (a real `Text` widget tree captured through
/// `RenderRepaintBoundary.toImage()`) rather than a hand-built bitmap --
/// this project has no manga/comic page fixture on disk, and this sidesteps
/// needing one, per this task's own suggested fallback. Uses the same
/// `RenderRepaintBoundary.toImage()` approach `app_test.dart` already
/// established works reliably in this sandboxed environment (unlike OS-level
/// window screenshotting, which that file's own comment notes proved
/// unreliable here).
Future<ui.Image> _renderTestPage(
  WidgetTester tester,
  GlobalKey boundaryKey,
) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: RepaintBoundary(
          key: boundaryKey,
          child: Container(
            width: 800,
            height: 1200,
            color: Colors.white,
            padding: const EdgeInsets.all(48),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Text(
                  '吾輩は猫である。名前はまだ無い。',
                  style: TextStyle(color: Colors.black, fontSize: 34),
                ),
                SizedBox(height: 80),
                Text(
                  'どこで生れたかとんと見当がつかぬ。',
                  style: TextStyle(color: Colors.black, fontSize: 34),
                ),
                SizedBox(height: 80),
                Text(
                  '何でも薄暗いじめじめした所で\nニャーニャー泣いていた事だけは\n記憶している。',
                  style: TextStyle(color: Colors.black, fontSize: 30),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final boundary =
      boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  return boundary.toImage(pixelRatio: 1.0);
}

/// dart:ui's `rawRgba` gives premultiplied-alpha RGBA8888; every pixel this
/// test paints is fully opaque (white background, opaque black text), so
/// premultiplication is a no-op and a straight byte-order swap to BGRA8888
/// (this project's own raw-pixel convention, see `TextRegionDetector.detect`'s
/// doc comment) is all that's needed.
Uint8List _rgbaToBgra(Uint8List rgba) {
  final bgra = Uint8List(rgba.length);
  for (var i = 0; i < rgba.length; i += 4) {
    bgra[i + 0] = rgba[i + 2];
    bgra[i + 1] = rgba[i + 1];
    bgra[i + 2] = rgba[i + 0];
    bgra[i + 3] = rgba[i + 3];
  }
  return bgra;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'ComicTextDetector: real model download + real ONNX Runtime inference '
    'on a real rendered Japanese-text page produces plausible text-block '
    'boxes',
    (tester) async {
      // --- Step 1: render a real test page with real, visible text. ---
      final boundaryKey = GlobalKey();
      final image = await _renderTestPage(tester, boundaryKey);
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      final bgra = _rgbaToBgra(byteData!.buffer.asUint8List());
      final width = image.width;
      final height = image.height;
      // ignore: avoid_print
      print(
        'Rendered test page: ${width}x$height, ${bgra.length} bytes BGRA8888',
      );

      final screenshotDir = Platform.environment['IT_SCREENSHOT_DIR'];
      if (screenshotDir != null) {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          p.join(screenshotDir, 'comic_text_detector_input.png'),
        ).writeAsBytes(png!.buffer.asUint8List());
      }

      // --- Step 2: real download, measured and reported on its own -- ---
      // --- separately from session creation + inference below.       ---
      const fetcher = HttpModelFetcher();
      final downloadStopwatch = Stopwatch()..start();
      final modelFile = await fetcher.ensureDownloaded(
        url: ComicTextDetector.modelUrl,
        subDir: ComicTextDetector.modelSubDir,
        fileName: ComicTextDetector.modelFileName,
      );
      downloadStopwatch.stop();
      final modelSizeBytes = await modelFile.length();
      // ignore: avoid_print
      print(
        'Model ready at ${modelFile.path}: $modelSizeBytes bytes '
        '(ensureDownloaded took ${downloadStopwatch.elapsedMilliseconds}ms -- '
        'near-instant on a cache hit, real network time on a fresh cache)',
      );
      expect(
        modelSizeBytes,
        94669756,
        reason:
            'the real downloaded file must match the size independently '
            'confirmed via a HEAD request against the release asset',
      );

      // --- Step 3: real session creation + real inference. ---
      final detector = ComicTextDetector(modelFetcher: fetcher);
      addTearDown(detector.dispose);

      final inferenceStopwatch = Stopwatch()..start();
      final regions = await detector.detect(bgra, width: width, height: height);
      inferenceStopwatch.stop();

      // ignore: avoid_print
      print(
        'ComicTextDetector.detect: ${regions.length} region(s) in '
        '${inferenceStopwatch.elapsedMilliseconds}ms on a ${width}x$height '
        'page',
      );
      for (final r in regions) {
        // ignore: avoid_print
        print(
          '  region: x=${r.x.toStringAsFixed(1)} '
          'y=${r.y.toStringAsFixed(1)} '
          'width=${r.width.toStringAsFixed(1)} '
          'height=${r.height.toStringAsFixed(1)}',
        );
      }

      // --- Step 4: plausibility checks on real output. ---
      expect(
        regions,
        isNotEmpty,
        reason:
            'expected at least one detected text block on a page with '
            'clearly visible text',
      );
      for (final r in regions) {
        expect(r.width, greaterThan(0));
        expect(r.height, greaterThan(0));
        expect(r.x, greaterThanOrEqualTo(0));
        expect(r.y, greaterThanOrEqualTo(0));
        expect(r.x + r.width, lessThanOrEqualTo(width + 0.5));
        expect(r.y + r.height, lessThanOrEqualTo(height + 0.5));
        // Not the entire page (that would suggest a whole-page fallback
        // box, not real per-block detection) and not a speck.
        expect(
          r.width * r.height,
          lessThan(width * height * 0.9),
          reason: 'a detected block should not span nearly the whole page',
        );
        expect(r.width, greaterThan(15));
        expect(r.height, greaterThan(15));
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
