// Real end-to-end verification of RealOcrEngine: the full composed
// pipeline (real ComicTextDetector region detection -> crop -> real
// MangaOcrRecognizer recognition -> assembled OcrRegionResult), not either
// model in isolation -- comic_text_detector_real_model_test.dart and
// manga_ocr_recognizer_real_model_test.dart already proved each backend
// works alone; this proves they compose correctly together (in particular,
// that ComicTextDetector's detected region coordinates crop the right part
// of the page for MangaOcrRecognizer to read).
//
// Same MethodChannel/MissingPluginException reasoning as the other two
// real-model integration tests for why this has to live under
// integration_test/, not plain `flutter_test`.
//
// Run with: flutter test integration_test/real_ocr_engine_test.dart -d windows
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/real_ocr_engine.dart';
import 'package:path/path.dart' as p;

/// Renders a real page-like image via Flutter's own text-painting pipeline
/// (mirrors comic_text_detector_real_model_test.dart's approach). A single
/// short line at this model's default confidence threshold was tried first
/// and detected *zero* regions -- a real, informative finding (see this
/// test's own git history/commit message), not a composition bug: the
/// earlier, successful detector-only test used a denser multi-line block
/// (~355x129px of a 800x681 page) that evidently crosses the confidence
/// threshold more reliably than one short line of plain, non-manga-style
/// text does. This renders a comparably dense 3-line block instead, still
/// bottom-right-anchored in a canvas much larger than the text block itself
/// (not centered), so a correctly-composed pipeline still has to use the
/// detector's actual reported position rather than happening to work by
/// feeding the recognizer the whole page.
Future<ui.Image> _renderPage(WidgetTester tester, GlobalKey boundaryKey) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: RepaintBoundary(
          key: boundaryKey,
          child: Container(
            width: 900,
            height: 500,
            color: Colors.white,
            alignment: Alignment.bottomRight,
            padding: const EdgeInsets.all(40),
            child: const Text(
              '猫が好きです\n犬も好きです\n今日は晴れです',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.black, fontSize: 32),
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'RealOcrEngine: real detector + real recognizer compose correctly on a '
    'real rendered page',
    (tester) async {
      final boundaryKey = GlobalKey();
      final image = await _renderPage(tester, boundaryKey);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final rgba = byteData!.buffer.asUint8List();
      final bgra = Uint8List(rgba.length);
      for (var i = 0; i < rgba.length; i += 4) {
        bgra[i + 0] = rgba[i + 2];
        bgra[i + 1] = rgba[i + 1];
        bgra[i + 2] = rgba[i + 0];
        bgra[i + 3] = rgba[i + 3];
      }
      final width = image.width;
      final height = image.height;
      // ignore: avoid_print
      print('Rendered test page: ${width}x$height');

      final screenshotDir = Platform.environment['IT_SCREENSHOT_DIR'];
      if (screenshotDir != null) {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          p.join(screenshotDir, 'real_ocr_engine_input.png'),
        ).writeAsBytes(png!.buffer.asUint8List());
      }

      final createStopwatch = Stopwatch()..start();
      final engine = await RealOcrEngine.create();
      createStopwatch.stop();
      // ignore: avoid_print
      print('RealOcrEngine.create() took ${createStopwatch.elapsed}');
      // No explicit teardown: OcrEngine has no lifecycle beyond recognize()
      // (see that interface's own doc comment), so RealOcrEngine doesn't
      // expose a way to reach its constituents' dispose() methods -- a
      // short-lived test process exiting afterward is an acceptable amount
      // of native-resource cleanup to skip, consistent with how the other
      // two real-model tests are scoped.

      final inferenceStopwatch = Stopwatch()..start();
      final regions = await engine.recognize(
        bgra,
        width: width,
        height: height,
        vertical: false,
      );
      inferenceStopwatch.stop();
      // ignore: avoid_print
      print(
        'recognize() took ${inferenceStopwatch.elapsed} -> '
        '${regions.length} region(s)',
      );
      for (final region in regions) {
        // ignore: avoid_print
        print(
          '  region: x=${region.x} y=${region.y} width=${region.width} '
          'height=${region.height} confidence=${region.confidence} '
          'text="${region.text}"',
        );
      }

      expect(regions, isNotEmpty);
      // The rendered phrase sits in the bottom-right quadrant of a 900x500
      // page -- a correctly-composed pipeline's detected+cropped region
      // must reflect that, not e.g. default to the whole page or the
      // top-left.
      final region = regions.first;
      expect(
        region.x + region.width / 2,
        greaterThan(width / 2),
        reason: 'expected the detected region to be right-of-center',
      );
      expect(
        region.y + region.height / 2,
        greaterThan(height / 2),
        reason: 'expected the detected region to be bottom-of-center',
      );

      // Exact match isn't guaranteed end-to-end (detector crop framing can
      // shift recognition slightly even when each backend works correctly
      // alone), but at least one recognized character should overlap the
      // rendered phrase, proving this is a real, related read rather than
      // unrelated/garbage output.
      const phrase = '猫が好きです犬も好きです今日は晴れです';
      final recognizedChars = regions.map((r) => r.text).join().runes.toSet();
      final expectedChars = phrase.runes.toSet();
      expect(
        recognizedChars.intersection(expectedChars),
        isNotEmpty,
        reason:
            'Expected at least one character in common between the '
            'rendered phrase "$phrase" and the recognized region(s) '
            '"${regions.map((r) => r.text).join(' | ')}".',
      );
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
