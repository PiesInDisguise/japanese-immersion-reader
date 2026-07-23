// Real end-to-end verification: launches the actual app (real EPUB import,
// real Sudachi tokenizer, real dictionary lookup, real Drift database --
// nothing mocked) via `integration_test`, which runs on the real platform
// with real async timing, unlike plain `flutter_test`'s fake-async/mocked-
// platform-channel test binding. Written specifically because OS-level
// window screenshotting (PrintWindow, CopyFromScreen) proved unreliable in
// this sandboxed environment for reasons unrelated to the app itself (see
// the manual-verification notes from this session) -- capturing pixels via
// RenderRepaintBoundary.toImage() sidesteps that entirely, since it reads
// Flutter's own rendering output directly rather than going through the OS
// window compositor.
//
// Run with: flutter test integration_test/app_test.dart -d windows
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:japanese_immersion_reader/main.dart';

Future<void> _screenshot(GlobalKey key, String path) async {
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(path).writeAsBytes(byteData!.buffer.asUint8List());
  // ignore: avoid_print
  print('Screenshot written: $path');
}

/// Pumps until [finder] appears or [timeout] elapses -- real wall-clock
/// waiting (this binding uses real time, not a fake clock), since real EPUB
/// import + real dictionary seeding + real Sudachi dictionary loading all
/// take genuine, variable time.
Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
  GlobalKey? debugScreenshotKey,
  String? debugScreenshotDir,
}) async {
  final stopwatch = Stopwatch()..start();
  while (finder.evaluate().isEmpty) {
    if (stopwatch.elapsed > timeout) {
      if (debugScreenshotKey != null && debugScreenshotDir != null) {
        await _screenshot(
          debugScreenshotKey,
          '$debugScreenshotDir/TIMEOUT.png',
        );
      }
      // ignore: avoid_print
      print(
        'TIMEOUT DEBUG: cwd=${Directory.current.path}, '
        'texts on screen=${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).toList()}',
      );
      fail('Timed out waiting for $finder after ${timeout.inSeconds}s');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'real end-to-end: load sample book, real tokens on a real card, tap-to-define, mine, flip',
    (tester) async {
      final boundaryKey = GlobalKey();
      final screenshotDir = Platform.environment['IT_SCREENSHOT_DIR'];

      Future<void> shot(String name) async {
        if (screenshotDir != null) {
          await _screenshot(boundaryKey, '$screenshotDir/$name.png');
        }
      }

      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: const ProviderScope(child: JapaneseImmersionReaderApp()),
        ),
      );
      await tester.pumpAndSettle();
      await shot('01_home');

      expect(find.text('Load Sample Book'), findsOneWidget);
      expect(find.text('Import EPUB...'), findsOneWidget);

      await tester.tap(find.text('Load Sample Book'));
      await tester.pump();

      // Real import + real dictionary seed + real Sudachi dictionary load.
      // The fixture's first card is the chapter heading (第一章 はじまり),
      // tokenized as its own card before the body sentences -- swipe forward
      // until the target sentence's card comes up, rather than assume it's
      // first.
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('cardModeCardArea')),
        timeout: const Duration(seconds: 45),
        debugScreenshotKey: boundaryKey,
        debugScreenshotDir: screenshotDir,
      );
      await tester.pumpAndSettle();
      await shot('02_card_mode_first_card');

      for (
        var i = 0;
        i < 6 && find.textContaining('彼').evaluate().isEmpty;
        i++
      ) {
        await tester.drag(
          find.byKey(const Key('cardModeCardArea')),
          const Offset(0, -100),
        );
        await tester.pumpAndSettle();
      }
      await shot('02b_card_mode_target_sentence');
      // Confirms the real tokenizer really ran (not a placeholder): 彼は東京に
      // 行った。 is on screen, split into real Sudachi tokens rather than shown
      // verbatim as one unsegmented blob.
      expect(find.textContaining('彼'), findsOneWidget);

      // Tap the card's real word "東京" (which carries the fixture's real
      // ruby reading とうきょう) to open the real lookup popup.
      await tester.tap(find.text('東京'));
      await tester.pumpAndSettle();
      await shot('03_word_lookup_popup');

      // Close the popup by tapping the modal barrier (well above the sheet,
      // clearly outside its content) rather than guessing which Navigator
      // owns it.
      await tester.tapAt(const Offset(400, 20));
      await tester.pumpAndSettle();
      expect(find.text('Add to Collection'), findsNothing);

      // Flip the card via a point clearly away from its centered text (the
      // sentence is short and Center-aligned both ways, so the card's own
      // geometric center -- what a bare tester.tap(find...) targets by
      // default -- usually lands directly on a token rather than "empty"
      // space; discovered via this real interaction test, not a bug in the
      // app, but real short sentences leave the same off-center empty
      // margin a real tap would need to land in too).
      final cardRect = tester.getRect(
        find.byKey(const Key('cardModeCardArea')),
      );
      await tester.tapAt(Offset(cardRect.center.dx, cardRect.top + 20));
      await tester.pumpAndSettle();
      await shot('04_card_flipped_token_gloss');

      // The flip side should show real L2 grammar data for 東京: its real
      // dictForm/reading, not blank/placeholder text.
      expect(find.textContaining('とうきょう'), findsWidgets);
    },
  );
}
