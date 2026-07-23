// Real end-to-end verification of MangaOcrRecognizer: real network download
// of the ~450MB encoder+decoder ONNX weights, real `flutter_onnxruntime`
// `OrtSession`s loaded from them, and real inference against a real rendered
// Japanese-text image -- nothing mocked or faked.
//
// This has to live under `integration_test/`, not plain `flutter_test`: both
// `path_provider` (which `ModelFetcher` uses to resolve the cache directory)
// and `flutter_onnxruntime` (which `MangaOcrRecognizer` uses for the actual
// ONNX sessions) are MethodChannel-based plugins. Confirmed directly in this
// environment that both throw `MissingPluginException` under plain
// `flutter test` (no running app/engine to dispatch the channel call to) --
// there is no way to exercise real inference outside a real running app,
// which is exactly what `integration_test` provides. See
// `comic_text_detector_real_model_test.dart`'s own doc comment for the same
// reasoning applied to the sibling real ONNX backend built alongside this
// one, and `app_test.dart`'s doc comment for the same reasoning applied to
// the app overall.
//
// Run with: flutter test integration_test/manga_ocr_recognizer_real_model_test.dart -d windows
//
// First run downloads the real model files to the application support
// directory and caches them there (same fetch-on-first-use pattern as the
// Yomitan/Sudachi dictionary assets and ComicTextDetector's own model) --
// expect a real, possibly slow, one-time network download; subsequent runs
// reuse the cached files.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/manga_ocr_recognizer.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Renders a real, visible-text crop via Flutter's own text-painting/
/// rendering pipeline (a real `Text` widget captured through
/// `RenderRepaintBoundary.toImage()`) rather than a hand-built bitmap --
/// this project has no real manga-crop fixture on disk, and this sidesteps
/// needing one, per this task's own suggested fallback. Mirrors
/// `comic_text_detector_real_model_test.dart`'s established approach for
/// the same reason: OS-level window screenshotting proved unreliable in
/// this sandboxed environment, and this reads Flutter's own rendering
/// output directly instead of going through the OS window compositor.
Future<ui.Image> _renderTextCrop(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String text,
) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: Container(
              width: 240,
              height: 240,
              color: Colors.white,
              alignment: Alignment.center,
              child: Text(
                text,
                style: const TextStyle(color: Colors.black, fontSize: 30),
              ),
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
/// (this project's raw-pixel convention -- see `TextRecognizer.recognizeCrop`'s
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

/// Reports the size of each cached ONNX file, resolved the same way
/// `HttpModelFetcher` resolves them (application-support dir / manga_ocr /
/// {encoder,decoder}_model.onnx), so the test output includes real observed
/// download sizes.
Future<String> _describeCachedModelFiles() async {
  final supportDir = await getApplicationSupportDirectory();
  final dir = p.join(supportDir.path, 'manga_ocr');
  final entries = <String>[];
  for (final fileName in ['encoder_model.onnx', 'decoder_model.onnx']) {
    final file = File(p.join(dir, fileName));
    if (await file.exists()) {
      final bytes = await file.length();
      entries.add(
        '$fileName: $bytes bytes (${(bytes / 1e6).toStringAsFixed(1)} MB)',
      );
    } else {
      entries.add('$fileName: MISSING');
    }
  }
  return entries.join(', ');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'MangaOcrRecognizer: real model download + real ONNX Runtime inference '
    'on a real rendered Japanese-text crop produces plausible text',
    (tester) async {
      // --- Step 1: render a real, visible test crop. ---
      const phrase = '猫が好きです'; // "I like cats" -- short and common.
      final boundaryKey = GlobalKey();
      final image = await _renderTextCrop(tester, boundaryKey, phrase);
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      final bgra = _rgbaToBgra(byteData!.buffer.asUint8List());
      final width = image.width;
      final height = image.height;
      // ignore: avoid_print
      print(
        'Rendered test crop: ${width}x$height, ${bgra.length} bytes BGRA8888',
      );

      final screenshotDir = Platform.environment['IT_SCREENSHOT_DIR'];
      if (screenshotDir != null) {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          p.join(screenshotDir, 'manga_ocr_recognizer_input.png'),
        ).writeAsBytes(png!.buffer.asUint8List());
      }

      // --- Step 2: real model download + real session load, measured on ---
      // --- its own, separately from inference below.                    ---
      final loadStopwatch = Stopwatch()..start();
      final recognizer = await MangaOcrRecognizer.create(
        // Generous relative to the class default: this run pays real
        // (possibly first-ever, so uncached) download time, cold ONNX
        // Runtime session init, and an uncached-KV decode loop -- see
        // MangaOcrRecognizer's own doc comment on why every decode step
        // redoes attention over the whole sequence so far.
        decodeTimeout: const Duration(seconds: 120),
      );
      loadStopwatch.stop();
      addTearDown(recognizer.dispose);

      final modelSizes = await _describeCachedModelFiles();
      // ignore: avoid_print
      print(
        'MangaOcrRecognizer.create() (download-if-needed + session load) '
        'took ${loadStopwatch.elapsed}. Cached model files: $modelSizes',
      );

      // --- Step 3: real inference. ---
      final inferenceStopwatch = Stopwatch()..start();
      final result = await recognizer.recognizeCrop(
        bgra,
        width: width,
        height: height,
        vertical: false,
      );
      inferenceStopwatch.stop();
      // ignore: avoid_print
      print(
        'recognizeCrop() for rendered "$phrase" took '
        '${inferenceStopwatch.elapsed} -> "${result.text}" '
        '(confidence ${result.confidence})',
      );

      // --- Step 4: plausibility checks on real output. ---
      expect(result.text, isNotEmpty);
      expect(result.confidence, greaterThan(0.0));

      // Exact match isn't guaranteed (real OCR on real-looking rendered
      // text isn't perfect even on clean synthetic input), but a wildly
      // wrong/empty result would indicate something is actually broken.
      // Require at least one character in common with the rendered phrase
      // rather than an exact string match.
      final expectedChars = phrase.runes.toSet();
      final recognizedChars = result.text.runes.toSet();
      final overlap = expectedChars.intersection(recognizedChars);
      expect(
        overlap,
        isNotEmpty,
        reason:
            'Expected at least one character in common between the '
            'rendered phrase "$phrase" and the recognized text '
            '"${result.text}" -- got none, which would suggest recognition '
            'is producing unrelated output rather than just an imperfect '
            'read.',
      );
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
