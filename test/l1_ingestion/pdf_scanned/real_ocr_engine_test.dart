import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/fake_text_recognizer.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/fake_text_region_detector.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/real_ocr_engine.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/text_recognizer.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/text_region_detector.dart';

/// Only this test file needs a [TextRecognizer] that can *fail* for a
/// specific crop size (proving one bad region doesn't lose a page's other
/// regions) -- [FakeTextRecognizer] is deliberately pure-canned-output-only
/// (see its own doc comment), so this is a small, test-local exception
/// rather than a change to that shared fake.
class _RecognizerThrowingForSize implements TextRecognizer {
  const _RecognizerThrowingForSize(this._badSize, this._otherwise);

  final (int, int) _badSize;
  final TextRecognizer _otherwise;

  @override
  Future<RecognizedText> recognizeCrop(
    Uint8List cropPixels, {
    required int width,
    required int height,
    required bool vertical,
  }) {
    if ((width, height) == _badSize) {
      throw StateError('simulated recognition failure for $_badSize');
    }
    return _otherwise.recognizeCrop(
      cropPixels,
      width: width,
      height: height,
      vertical: vertical,
    );
  }
}

Uint8List _solidPage(int width, int height) => Uint8List(width * height * 4);

void main() {
  group('RealOcrEngine.recognize', () {
    test(
      'crops each detected region and attaches the recognized text/'
      'confidence to that region\'s own position (not the recognizer\'s, '
      'which only ever sees a crop)',
      () async {
        final engine = RealOcrEngine(
          detector: const FakeTextRegionDetector(
            defaultRegions: [
              DetectedTextRegion(x: 10, y: 20, width: 30, height: 15),
              DetectedTextRegion(x: 60, y: 5, width: 20, height: 10),
            ],
          ),
          recognizer: const FakeTextRecognizer(
            textForCropSize: {
              (30, 15): RecognizedText(text: 'first', confidence: 0.5),
              (20, 10): RecognizedText(text: 'second', confidence: 0.7),
            },
          ),
        );

        final regions = await engine.recognize(
          _solidPage(100, 100),
          width: 100,
          height: 100,
          vertical: false,
        );

        expect(regions, hasLength(2));
        expect(regions[0].text, 'first');
        expect(regions[0].x, 10);
        expect(regions[0].y, 20);
        expect(regions[0].width, 30);
        expect(regions[0].height, 15);
        expect(regions[0].confidence, 0.5);
        expect(regions[1].text, 'second');
        expect(regions[1].x, 60);
        expect(regions[1].y, 5);
        expect(regions[1].confidence, 0.7);
      },
    );

    test('a region cropping to nothing (entirely off-page) is skipped, '
        'other regions on the same page are unaffected', () async {
      final engine = RealOcrEngine(
        detector: const FakeTextRegionDetector(
          defaultRegions: [
            DetectedTextRegion(x: 200, y: 200, width: 30, height: 15),
            DetectedTextRegion(x: 10, y: 10, width: 20, height: 20),
          ],
        ),
        recognizer: const FakeTextRecognizer(
          textForCropSize: {
            (20, 20): RecognizedText(text: 'ok', confidence: 0.9),
          },
        ),
      );

      final regions = await engine.recognize(
        _solidPage(100, 100),
        width: 100,
        height: 100,
        vertical: false,
      );

      expect(regions, hasLength(1));
      expect(regions.single.text, 'ok');
    });

    test('a region the recognizer returns empty text for is skipped', () async {
      final engine = RealOcrEngine(
        detector: const FakeTextRegionDetector(
          defaultRegions: [DetectedTextRegion(x: 0, y: 0, width: 10, height: 10)],
        ),
        recognizer: const FakeTextRecognizer(
          textForCropSize: {(10, 10): RecognizedText(text: '', confidence: 0.9)},
        ),
      );

      final regions = await engine.recognize(
        _solidPage(50, 50),
        width: 50,
        height: 50,
        vertical: false,
      );

      expect(regions, isEmpty);
    });

    test(
      'a recognizer that throws for one region does not lose the page\'s '
      'other, good regions',
      () async {
        final engine = RealOcrEngine(
          detector: const FakeTextRegionDetector(
            defaultRegions: [
              DetectedTextRegion(x: 0, y: 0, width: 10, height: 10),
              DetectedTextRegion(x: 20, y: 20, width: 5, height: 5),
            ],
          ),
          recognizer: const _RecognizerThrowingForSize(
            (10, 10),
            FakeTextRecognizer(
              textForCropSize: {
                (5, 5): RecognizedText(text: 'survived', confidence: 0.6),
              },
            ),
          ),
        );

        final regions = await engine.recognize(
          _solidPage(50, 50),
          width: 50,
          height: 50,
          vertical: false,
        );

        expect(regions, hasLength(1));
        expect(regions.single.text, 'survived');
      },
    );

    test('no detected regions produces no OCR results', () async {
      final engine = RealOcrEngine(
        detector: const FakeTextRegionDetector(defaultRegions: []),
        recognizer: const FakeTextRecognizer(),
      );

      final regions = await engine.recognize(
        _solidPage(50, 50),
        width: 50,
        height: 50,
        vertical: false,
      );

      expect(regions, isEmpty);
    });
  });
}
