import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/ocr_engine.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/ocr_worker.dart';

/// A deliberately *stateful* engine -- the opposite of `FakeOcrEngine`'s own
/// documented constraint -- specifically to prove [OcrWorker] constructs one
/// engine instance and reuses it across calls, rather than the old
/// per-page-`Isolate.run` approach's fresh-copy-per-call behavior (under
/// which a counter like this could never have advanced past 1, since every
/// call would see its own copy starting from the constructor's initial
/// state).
class _CountingOcrEngine implements OcrEngine {
  int _callCount = 0;

  @override
  Future<List<OcrRegionResult>> recognize(
    Uint8List pageImage, {
    required int width,
    required int height,
    required bool vertical,
  }) async {
    _callCount++;
    return [
      OcrRegionResult(
        text: 'call-$_callCount',
        x: 0,
        y: 0,
        width: width.toDouble(),
        height: height.toDouble(),
        confidence: 1.0,
      ),
    ];
  }
}

class _ThrowingOcrEngine implements OcrEngine {
  @override
  Future<List<OcrRegionResult>> recognize(
    Uint8List pageImage, {
    required int width,
    required int height,
    required bool vertical,
  }) async {
    throw StateError('boom');
  }
}

void main() {
  test(
    'recognize() round-trips real arguments and results across the isolate '
    'boundary',
    () async {
      final worker = await OcrWorker.spawn(_CountingOcrEngine.new);
      try {
        final pixels = Uint8List.fromList(
          List<int>.generate(16, (i) => i),
        ); // 2x2 BGRA8888
        final regions = await worker.recognize(
          pixels,
          width: 2,
          height: 2,
          vertical: true,
        );
        expect(regions, hasLength(1));
        expect(regions.single.width, 2);
        expect(regions.single.height, 2);
      } finally {
        worker.dispose();
      }
    },
  );

  test(
    'the SAME engine instance persists across multiple calls -- proves this '
    'is a long-lived worker, not a fresh isolate+copy per call',
    () async {
      final worker = await OcrWorker.spawn(_CountingOcrEngine.new);
      try {
        final pixels = Uint8List(4);
        final first = await worker.recognize(
          pixels,
          width: 1,
          height: 1,
          vertical: false,
        );
        final second = await worker.recognize(
          pixels,
          width: 1,
          height: 1,
          vertical: false,
        );
        final third = await worker.recognize(
          pixels,
          width: 1,
          height: 1,
          vertical: false,
        );

        expect(first.single.text, 'call-1');
        expect(second.single.text, 'call-2');
        expect(third.single.text, 'call-3');
      } finally {
        worker.dispose();
      }
    },
  );

  test(
    'an async factory (e.g. a real engine awaiting model download + ONNX '
    'session creation) is awaited before spawn() resolves',
    () async {
      final worker = await OcrWorker.spawn(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return _CountingOcrEngine();
      });
      try {
        final regions = await worker.recognize(
          Uint8List(4),
          width: 1,
          height: 1,
          vertical: false,
        );
        expect(regions.single.text, 'call-1');
      } finally {
        worker.dispose();
      }
    },
  );

  test(
    'spawn() rethrows a factory that fails to construct, rather than '
    'surfacing it confusingly on the first recognize() call',
    () async {
      await expectLater(
        OcrWorker.spawn(() => throw StateError('model download failed')),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('an engine that throws surfaces as a StateError to the caller, '
      'without crashing the worker', () async {
    final worker = await OcrWorker.spawn(_ThrowingOcrEngine.new);
    try {
      await expectLater(
        worker.recognize(Uint8List(4), width: 1, height: 1, vertical: false),
        throwsA(isA<StateError>()),
      );
    } finally {
      worker.dispose();
    }
  });
}
