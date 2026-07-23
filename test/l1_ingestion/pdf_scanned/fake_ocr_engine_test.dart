import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/fake_ocr_engine.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/ocr_engine.dart';

void main() {
  group('FakeOcrEngine', () {
    test('falls back to one canned region spanning the whole page when '
        'unconfigured', () async {
      const engine = FakeOcrEngine();
      final regions = await engine.recognize(
        Uint8List(10),
        width: 30,
        height: 40,
        vertical: false,
      );
      expect(regions, hasLength(1));
      expect(regions.single.width, 30);
      expect(regions.single.height, 40);
      expect(regions.single.confidence, 0.9);
    });

    test(
      'defaultConfidence overrides the built-in fallback confidence',
      () async {
        const engine = FakeOcrEngine(defaultConfidence: 0.13);
        final regions = await engine.recognize(
          Uint8List(0),
          width: 1,
          height: 1,
          vertical: false,
        );
        expect(regions.single.confidence, 0.13);
      },
    );

    test('defaultRegions is returned verbatim when given', () async {
      const canned = [
        OcrRegionResult(
          text: '固定文',
          x: 1,
          y: 2,
          width: 3,
          height: 4,
          confidence: 0.55,
        ),
      ];
      const engine = FakeOcrEngine(defaultRegions: canned);
      final regions = await engine.recognize(
        Uint8List(0),
        width: 999,
        height: 999,
        vertical: true,
      );
      expect(regions, same(canned));
    });

    test('regionsForPageSize selects by exact (width, height)', () async {
      const smallRegions = [
        OcrRegionResult(
          text: '小',
          x: 0,
          y: 0,
          width: 1,
          height: 1,
          confidence: 0.1,
        ),
      ];
      const bigRegions = [
        OcrRegionResult(
          text: '大',
          x: 0,
          y: 0,
          width: 2,
          height: 2,
          confidence: 0.2,
        ),
      ];
      const engine = FakeOcrEngine(
        regionsForPageSize: {(10, 20): smallRegions, (100, 200): bigRegions},
        defaultRegions: [],
      );

      expect(
        await engine.recognize(
          Uint8List(0),
          width: 10,
          height: 20,
          vertical: false,
        ),
        same(smallRegions),
      );
      expect(
        await engine.recognize(
          Uint8List(0),
          width: 100,
          height: 200,
          vertical: false,
        ),
        same(bigRegions),
      );
      expect(
        await engine.recognize(
          Uint8List(0),
          width: 1,
          height: 1,
          vertical: false,
        ),
        isEmpty,
        reason: 'falls back to defaultRegions for an unrecognized size',
      );
    });
  });

  group('OcrRegionResult', () {
    test('value equality compares all fields', () {
      const a = OcrRegionResult(
        text: 't',
        x: 1,
        y: 2,
        width: 3,
        height: 4,
        confidence: 0.5,
      );
      const b = OcrRegionResult(
        text: 't',
        x: 1,
        y: 2,
        width: 3,
        height: 4,
        confidence: 0.5,
      );
      const c = OcrRegionResult(
        text: 'different',
        x: 1,
        y: 2,
        width: 3,
        height: 4,
        confidence: 0.5,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
