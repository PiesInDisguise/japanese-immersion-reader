import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'ocr_engine.dart';

/// Constructs an [OcrEngine]. Called exactly once, *inside* the worker
/// isolate [OcrWorker] spawns -- see that class's doc comment for why this
/// is a factory rather than a ready instance.
typedef OcrEngineFactory = OcrEngine Function();

/// A single long-lived background isolate holding one real [OcrEngine]
/// instance for the lifetime of one import, replacing the previous
/// per-page `Isolate.run` approach (still visible in git history), which
/// spawned a *fresh* isolate and sent a fresh *copy* of the engine on every
/// single page. That was harmless for a stateless fake, but wrong for a
/// real engine wrapping loaded ONNX Runtime sessions: re-sending one per
/// page either wouldn't survive serialization at all, or would mean
/// reloading a multi-hundred-MB model on every page of a scan -- both
/// serious problems for the real Manga OCR / comic-text-detector engines
/// this project is integrating. See `ocr_worker_test.dart` for a concrete
/// test proving an engine instance now genuinely persists and is reused
/// across calls (a stateful counter keeps incrementing), which the old
/// per-call-fresh-copy approach could never have shown even for a
/// deliberately stateful fake.
///
/// [OcrEngineFactory] rather than a ready [OcrEngine] instance specifically
/// so construction -- which for a real engine means loading ONNX sessions,
/// potentially after a first-run model download -- happens on the worker
/// isolate, not the caller's, and happens exactly once.
class OcrWorker {
  OcrWorker._(this._isolate, this._commands);

  final Isolate _isolate;
  final SendPort _commands;

  /// Spawns the worker and waits for it to finish constructing its engine
  /// (i.e. [factory] has already returned inside the worker isolate) before
  /// resolving -- so a caller never sends work to an isolate that isn't
  /// ready yet.
  static Future<OcrWorker> spawn(OcrEngineFactory factory) async {
    final ready = ReceivePort();
    final isolate = await Isolate.spawn(_entryPoint, (factory, ready.sendPort));
    final commands = await ready.first as SendPort;
    ready.close();
    return OcrWorker._(isolate, commands);
  }

  /// Recognizes text on one page via this worker's single,
  /// already-constructed [OcrEngine] instance. Each call opens its own
  /// one-shot reply [ReceivePort] rather than multiplexing a request ID
  /// over one shared response stream -- simpler, and correct as long as
  /// [ScannedPdfImporter] only ever awaits one page at a time (true today;
  /// worth revisiting if a future pass parallelizes page OCR within one
  /// import).
  Future<List<OcrRegionResult>> recognize(
    Uint8List pageImage, {
    required int width,
    required int height,
    required bool vertical,
  }) async {
    final reply = ReceivePort();
    _commands.send((pageImage, width, height, vertical, reply.sendPort));
    final (regions, error) =
        await reply.first as (List<OcrRegionResult>?, String?);
    reply.close();
    if (error != null) {
      throw StateError('OcrWorker: engine.recognize failed: $error');
    }
    return regions!;
  }

  /// Terminates the worker isolate. Must be called once per import (not per
  /// page) when done with it, or the isolate -- and whatever the engine
  /// loaded into it (e.g. ONNX sessions) -- leaks for the app's lifetime.
  void dispose() => _isolate.kill(priority: Isolate.immediate);

  static void _entryPoint((OcrEngineFactory, SendPort) args) {
    final (factory, readyPort) = args;
    final engine = factory();
    final commands = ReceivePort();
    readyPort.send(commands.sendPort);
    commands.listen((message) async {
      final (
        Uint8List pageImage,
        int width,
        int height,
        bool vertical,
        SendPort replyPort,
      ) = message as (Uint8List, int, int, bool, SendPort);
      try {
        final regions = await engine.recognize(
          pageImage,
          width: width,
          height: height,
          vertical: vertical,
        );
        replyPort.send((regions, null));
      } catch (e) {
        replyPort.send((null, e.toString()));
      }
    });
  }
}
