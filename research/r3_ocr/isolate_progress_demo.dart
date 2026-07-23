// Throwaway research spike -- NOT production code. See docs/research/r3-ocr.md
// (finding 3: background-isolate feasibility) for how this fits in.
//
// Demonstrates the concurrency shape recommended for scanned-PDF/OCR import:
// a long-lived worker Isolate processes a document chapter by chapter,
// reports fractional progress + stage back to the caller via
// SendPort/ReceivePort, survives a simulated per-chapter OCR failure without
// aborting the whole job, and can be cancelled mid-run. A periodic timer on
// the "main" isolate stands in for the Flutter UI frame ticker: if it keeps
// firing on schedule while the worker runs, the calling isolate was never
// blocked.
//
// This validates ONLY the pure-Dart isolate/progress/cancellation mechanics
// (dart:isolate is a Dart VM feature, so this needs no Flutter/pub deps and
// runs on desktop). It deliberately does NOT exercise ONNX Runtime or
// Tesseract plugin calls from inside a spawned isolate -- those are
// platform-channel-based plugins, which need `BackgroundIsolateBinaryMessenger
// .ensureInitialized()` plus a real Android/iOS device/emulator to verify
// (none was available in this research environment: `flutter devices` only
// showed Windows desktop + Chrome + Edge). That remains the top open risk --
// see r3-ocr.md.
//
// Run with:  dart run research/r3_ocr/isolate_progress_demo.dart

import 'dart:async';
import 'dart:isolate';

/// Mirrors the shape of `ImportProgress`/`ImportStage` in
/// lib/l1_ingestion/importer.dart, redeclared locally so this script has zero
/// dependency on the app package and needs no `flutter pub get` / build_runner
/// step to run.
enum Stage { parsing, ocr, indexing, done }

class Progress {
  final double fraction;
  final Stage stage;
  final int? chapterIndex;
  final String? note;
  const Progress(this.fraction, this.stage, {this.chapterIndex, this.note});
  @override
  String toString() {
    final ch = chapterIndex != null ? ' chapter $chapterIndex' : '';
    final n = note != null ? ' ($note)' : '';
    return '[${(fraction * 100).toStringAsFixed(1)}%] $stage$ch$n';
  }
}

const _totalChapters = 8;
const _flakyChapterIndex = 3; // simulates one low-confidence/failed chapter

/// Entry point run inside the spawned worker isolate.
void _ocrWorker(SendPort mainSendPort) {
  final commandPort = ReceivePort();
  mainSendPort.send(commandPort.sendPort);

  var cancelled = false;
  commandPort.listen((msg) {
    if (msg == 'cancel') cancelled = true;
  });

  Future<void> run() async {
    for (var ch = 0; ch < _totalChapters; ch++) {
      if (cancelled) {
        mainSendPort.send(
          Progress(
            ch / _totalChapters,
            Stage.ocr,
            chapterIndex: ch,
            note: 'cancelled',
          ),
        );
        mainSendPort.send('cancelled');
        return;
      }

      // Stand-in for "OCR every text region on this chapter's pages". A real
      // worker would call the ONNX/Tesseract plugin here instead of
      // Future.delayed -- see r3-ocr.md for why that call is the unverified
      // part, not this loop/progress/cancellation shell.
      try {
        await _simulateChapterOcr(ch);
      } catch (e) {
        // A single bad region/chapter must not abort the whole document.
        mainSendPort.send(
          Progress(
            ch / _totalChapters,
            Stage.ocr,
            chapterIndex: ch,
            note: 'recovered from error: $e',
          ),
        );
        continue;
      }

      mainSendPort.send(
        Progress((ch + 1) / _totalChapters, Stage.ocr, chapterIndex: ch),
      );
    }
    mainSendPort.send(const Progress(1.0, Stage.done));
    mainSendPort.send('done');
  }

  run();
}

Future<void> _simulateChapterOcr(int chapterIndex) async {
  await Future<void>.delayed(const Duration(milliseconds: 120));
  if (chapterIndex == _flakyChapterIndex) {
    throw StateError('low-confidence page, skipped');
  }
}

/// Runs one full worker isolate to completion (or cancels it partway through
/// if [cancelAfter] is given), printing progress as it arrives and counting
/// "UI heartbeat" ticks to prove the caller stayed responsive throughout.
Future<void> _runScenario({Duration? cancelAfter}) async {
  final mainReceivePort = ReceivePort();
  final done = Completer<void>();
  SendPort? workerCommandPort;

  await Isolate.spawn(_ocrWorker, mainReceivePort.sendPort);

  var uiTicks = 0;
  final uiHeartbeat = Timer.periodic(const Duration(milliseconds: 20), (_) {
    uiTicks++;
  });

  Timer? cancelTimer;
  if (cancelAfter != null) {
    cancelTimer = Timer(cancelAfter, () {
      print('--- main isolate requests cancellation ---');
      workerCommandPort?.send('cancel');
    });
  }

  mainReceivePort.listen((msg) {
    if (msg is SendPort) {
      workerCommandPort = msg;
      return;
    }
    if (msg is Progress) {
      print('progress: $msg  (ui heartbeat ticks so far: $uiTicks)');
      return;
    }
    if (msg == 'done' || msg == 'cancelled') {
      uiHeartbeat.cancel();
      cancelTimer?.cancel();
      mainReceivePort.close();
      done.complete();
    }
  });

  await done.future;
  print(
    'UI heartbeat ticked $uiTicks times while OCR ran in the background isolate '
    '-- the calling isolate was never blocked.\n',
  );
}

Future<void> main() async {
  print(
    '=== Scenario A: full run (progress + recoverable per-chapter error) ===',
  );
  await _runScenario();

  print('=== Scenario B: cancelled partway through ===');
  await _runScenario(cancelAfter: const Duration(milliseconds: 300));
}
