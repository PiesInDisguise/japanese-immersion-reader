import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/comic_text_detector.dart';

/// A solid-color BGRA8888 buffer -- deliberately a single uniform color so
/// `copyResize`'s linear interpolation can never introduce blending
/// artifacts at any sample point (every input pixel is identical, so any
/// weighted average of them is that same value again). That isolates these
/// tests to exactly what they're meant to check -- letterbox *placement*
/// (top-left anchoring, which axis gets padded) and BGRA->RGB channel
/// handling -- without also having to reason about resampling math.
Uint8List _solidBgra(
  int width,
  int height, {
  required int r,
  required int g,
  required int b,
}) {
  final bytes = Uint8List(width * height * 4);
  for (var i = 0; i < width * height; i++) {
    bytes[i * 4 + 0] = b;
    bytes[i * 4 + 1] = g;
    bytes[i * 4 + 2] = r;
    bytes[i * 4 + 3] = 255;
  }
  return bytes;
}

/// Builds a flat `blk`-shaped tensor (row-major `[1, anchors.length,
/// rowLength]`, matching `OrtValue.asFlattenedList`'s layout) from a list of
/// per-anchor rows, each `[cx, cy, w, h, obj, ...classScores]`.
List<double> _flattenAnchors(List<List<double>> anchors) =>
    anchors.expand((row) => row).toList();

void main() {
  group('ComicTextDetector.preprocess', () {
    test('landscape source: width fills exactly, padding lands on the bottom '
        '(top-left anchored, not centered)', () {
      // 100x50 -> r = min(1024/50, 1024/100) = 10.24 -> unpaddedWidth =
      // round(100*10.24) = 1024 (exact fill), unpaddedHeight =
      // round(50*10.24) = 512 (512 rows of padding below it).
      final bgra = _solidBgra(100, 50, r: 200, g: 100, b: 50);
      final result = ComicTextDetector.preprocess(bgra, width: 100, height: 50);

      expect(result.unpaddedWidth, 1024);
      expect(result.unpaddedHeight, 512);

      const planeSize =
          ComicTextDetector.inputSize * ComicTextDetector.inputSize;
      // Well inside the resized content (y < 512): real page color.
      final contentIndex = 100 * ComicTextDetector.inputSize + 500;
      expect(result.tensor[contentIndex], closeTo(200 / 255, 0.01));
      expect(result.tensor[planeSize + contentIndex], closeTo(100 / 255, 0.01));
      expect(
        result.tensor[2 * planeSize + contentIndex],
        closeTo(50 / 255, 0.01),
      );

      // Below the resized content (y >= 512): black padding.
      final paddingIndex = 600 * ComicTextDetector.inputSize + 500;
      expect(result.tensor[paddingIndex], 0.0);
      expect(result.tensor[planeSize + paddingIndex], 0.0);
      expect(result.tensor[2 * planeSize + paddingIndex], 0.0);
    });

    test('portrait source: height fills exactly, padding lands on the right '
        '(top-left anchored, not centered)', () {
      // 50x100 -> r = min(1024/100, 1024/50) = 10.24 -> unpaddedWidth =
      // round(50*10.24) = 512 (512 columns of padding to its right),
      // unpaddedHeight = round(100*10.24) = 1024 (exact fill).
      final bgra = _solidBgra(50, 100, r: 10, g: 220, b: 90);
      final result = ComicTextDetector.preprocess(bgra, width: 50, height: 100);

      expect(result.unpaddedWidth, 512);
      expect(result.unpaddedHeight, 1024);

      const planeSize =
          ComicTextDetector.inputSize * ComicTextDetector.inputSize;
      final contentIndex = 500 * ComicTextDetector.inputSize + 100;
      expect(result.tensor[contentIndex], closeTo(10 / 255, 0.01));
      expect(result.tensor[planeSize + contentIndex], closeTo(220 / 255, 0.01));
      expect(
        result.tensor[2 * planeSize + contentIndex],
        closeTo(90 / 255, 0.01),
      );

      final paddingIndex = 500 * ComicTextDetector.inputSize + 600;
      expect(result.tensor[paddingIndex], 0.0);
      expect(result.tensor[planeSize + paddingIndex], 0.0);
      expect(result.tensor[2 * planeSize + paddingIndex], 0.0);
    });

    test('tensor has the expected NCHW flat length', () {
      final bgra = _solidBgra(10, 10, r: 1, g: 2, b: 3);
      final result = ComicTextDetector.preprocess(bgra, width: 10, height: 10);
      expect(
        result.tensor.length,
        3 * ComicTextDetector.inputSize * ComicTextDetector.inputSize,
      );
    });
  });

  group('ComicTextDetector.postprocessBlkOutput', () {
    test('filters by confidence, suppresses an overlapping lower-confidence '
        'box via NMS, and keeps a separate non-overlapping box', () {
      final flat = _flattenAnchors([
        // Kept: confidence 0.9*0.9=0.81, box (75,160)-(125,240).
        [100, 200, 50, 80, 0.9, 0.9],
        // Suppressed: heavily overlaps the box above (IoU ~0.73 > 0.35)
        // and has lower confidence (0.7*0.7=0.49).
        [105, 205, 50, 80, 0.7, 0.7],
        // Kept: confidence 0.95*0.6=0.57, box (780,780)-(820,820), no
        // overlap with either box above.
        [800, 800, 40, 40, 0.95, 0.6],
        // Filtered before NMS even runs: confidence 0.1*0.1=0.01, below
        // the default 0.4 threshold.
        [500, 500, 20, 20, 0.1, 0.1],
      ]);

      final regions = ComicTextDetector.postprocessBlkOutput(
        flat,
        [1, 4, 6],
        originalWidth: 1024,
        originalHeight: 1024,
        unpaddedWidth: 1024,
        unpaddedHeight: 1024,
      );

      expect(regions, hasLength(2));
      // Sorted by descending confidence internally, so the surviving
      // higher-confidence box (0.81) comes first.
      expect(regions[0].x, closeTo(75, 1e-9));
      expect(regions[0].y, closeTo(160, 1e-9));
      expect(regions[0].width, closeTo(50, 1e-9));
      expect(regions[0].height, closeTo(80, 1e-9));
      expect(regions[1].x, closeTo(780, 1e-9));
      expect(regions[1].y, closeTo(780, 1e-9));
      expect(regions[1].width, closeTo(40, 1e-9));
      expect(regions[1].height, closeTo(40, 1e-9));
    });

    test('maps letterboxed-frame coordinates back to page pixels using '
        'independent per-axis scale factors', () {
      // scaleX = 2000/1000 = 2.0, scaleY = 500/100 = 5.0 -- deliberately
      // different so an accidental x/y swap in the un-letterbox math would
      // be caught by a wrong result on at least one axis.
      final flat = _flattenAnchors([
        [100, 20, 20, 10, 0.9, 0.9], // xyxy (90,15)-(110,25) pre-scale
      ]);

      final regions = ComicTextDetector.postprocessBlkOutput(
        flat,
        [1, 1, 6],
        originalWidth: 2000,
        originalHeight: 500,
        unpaddedWidth: 1000,
        unpaddedHeight: 100,
      );

      expect(regions, hasLength(1));
      expect(regions.single.x, closeTo(180, 1e-9)); // 90 * 2.0
      expect(regions.single.y, closeTo(75, 1e-9)); // 15 * 5.0
      expect(regions.single.width, closeTo(40, 1e-9)); // (110-90) * 2.0
      expect(regions.single.height, closeTo(50, 1e-9)); // (25-15) * 5.0
    });

    test('clamps a box that spills past the page edge to the page bounds', () {
      final flat = _flattenAnchors([
        [1010, 1010, 40, 40, 0.9, 0.9], // xyxy (990,990)-(1030,1030)
      ]);

      final regions = ComicTextDetector.postprocessBlkOutput(
        flat,
        [1, 1, 6],
        originalWidth: 1024,
        originalHeight: 1024,
        unpaddedWidth: 1024,
        unpaddedHeight: 1024,
      );

      expect(regions, hasLength(1));
      expect(regions.single.x, closeTo(990, 1e-9));
      expect(regions.single.y, closeTo(990, 1e-9));
      expect(regions.single.width, closeTo(34, 1e-9)); // 1024 - 990
      expect(regions.single.height, closeTo(34, 1e-9));
    });

    test('works with more than one class score column (nc read from shape, '
        'not hardcoded)', () {
      final flat = _flattenAnchors([
        // rowLength 8 => 3 class scores; best is index 2 (0.8).
        [400, 300, 30, 30, 0.9, 0.1, 0.2, 0.8],
      ]);

      final regions = ComicTextDetector.postprocessBlkOutput(
        flat,
        [1, 1, 8],
        originalWidth: 1024,
        originalHeight: 1024,
        unpaddedWidth: 1024,
        unpaddedHeight: 1024,
      );

      // confidence = 0.9 * 0.8 = 0.72 > 0.4 threshold.
      expect(regions, hasLength(1));
      expect(regions.single.width, closeTo(30, 1e-9));
    });

    test('an empty anchor list produces no regions', () {
      final regions = ComicTextDetector.postprocessBlkOutput(
        const [],
        [1, 0, 6],
        originalWidth: 1024,
        originalHeight: 1024,
        unpaddedWidth: 1024,
        unpaddedHeight: 1024,
      );
      expect(regions, isEmpty);
    });

    test('throws ArgumentError for a non-rank-3 shape', () {
      expect(
        () => ComicTextDetector.postprocessBlkOutput(
          const [1, 2, 3],
          [3],
          originalWidth: 100,
          originalHeight: 100,
          unpaddedWidth: 100,
          unpaddedHeight: 100,
        ),
        throwsArgumentError,
      );
    });

    test(
      'throws ArgumentError when the row length has no class-score room',
      () {
        expect(
          () => ComicTextDetector.postprocessBlkOutput(
            List.filled(5, 0.0),
            [1, 1, 5],
            originalWidth: 100,
            originalHeight: 100,
            unpaddedWidth: 100,
            unpaddedHeight: 100,
          ),
          throwsArgumentError,
        );
      },
    );
  });
}
