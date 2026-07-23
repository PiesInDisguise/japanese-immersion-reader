import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/fake_text_region_detector.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/text_region_detector.dart';

void main() {
  group('FakeTextRegionDetector', () {
    test('falls back to one region spanning the whole page when '
        'unconfigured', () async {
      const detector = FakeTextRegionDetector();
      final regions = await detector.detect(
        Uint8List(10),
        width: 30,
        height: 40,
      );
      expect(regions, hasLength(1));
      expect(regions.single.x, 0);
      expect(regions.single.y, 0);
      expect(regions.single.width, 30);
      expect(regions.single.height, 40);
    });

    test('defaultRegions is returned verbatim when given', () async {
      const canned = [DetectedTextRegion(x: 1, y: 2, width: 3, height: 4)];
      const detector = FakeTextRegionDetector(defaultRegions: canned);
      final regions = await detector.detect(
        Uint8List(0),
        width: 999,
        height: 999,
      );
      expect(regions, same(canned));
    });

    test('regionsForPageSize selects by exact (width, height)', () async {
      const smallRegions = [
        DetectedTextRegion(x: 0, y: 0, width: 1, height: 1),
      ];
      const bigRegions = [DetectedTextRegion(x: 0, y: 0, width: 2, height: 2)];
      const detector = FakeTextRegionDetector(
        regionsForPageSize: {(10, 20): smallRegions, (100, 200): bigRegions},
        defaultRegions: [],
      );

      expect(
        await detector.detect(Uint8List(0), width: 10, height: 20),
        same(smallRegions),
      );
      expect(
        await detector.detect(Uint8List(0), width: 100, height: 200),
        same(bigRegions),
      );
      expect(
        await detector.detect(Uint8List(0), width: 1, height: 1),
        isEmpty,
        reason: 'falls back to defaultRegions for an unrecognized size',
      );
    });

    test('output does not depend on call order or count (pure function of '
        'arguments, no hidden mutable state)', () async {
      const detector = FakeTextRegionDetector();
      final first = await detector.detect(Uint8List(0), width: 5, height: 6);
      final second = await detector.detect(Uint8List(0), width: 5, height: 6);
      final third = await detector.detect(Uint8List(0), width: 5, height: 6);
      expect(first, equals(second));
      expect(second, equals(third));
    });
  });

  group('DetectedTextRegion', () {
    test('value equality compares all fields', () {
      const a = DetectedTextRegion(x: 1, y: 2, width: 3, height: 4);
      const b = DetectedTextRegion(x: 1, y: 2, width: 3, height: 4);
      const c = DetectedTextRegion(x: 1, y: 2, width: 3, height: 999);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
