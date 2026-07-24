// Plain `test()` -- mocks flutter_tts's platform MethodChannel directly
// (the standard technique for testing a Flutter plugin wrapper) rather than
// touching a real TTS engine. `TestWidgetsFlutterBinding.ensureInitialized()`
// is needed for the mock-channel machinery itself, but this suite never
// loads a real asset/widget tree, so it isn't the testWidgets+rootBundle
// combination previously found to hang.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:japanese_immersion_reader/l6_audio/tts/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_tts');
  final calls = <MethodCall>[];
  dynamic Function(MethodCall)? handler;

  setUp(() {
    calls.clear();
    handler = (call) => null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return handler!(call);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('FlutterTtsService', () {
    test('sets the Japanese locale on construction', () {
      FlutterTtsService(FlutterTts());
      expect(calls.single.method, 'setLanguage');
      expect(calls.single.arguments, 'ja-JP');
    });

    test('speak() stops any in-progress utterance before speaking', () async {
      final service = FlutterTtsService(FlutterTts());
      calls.clear();

      await service.speak('こんにちは');

      expect(calls.map((c) => c.method), ['stop', 'speak']);
      expect(calls.last.arguments, 'こんにちは');
    });

    test('isAvailable() reflects a true platform response', () async {
      final service = FlutterTtsService(FlutterTts());
      handler = (call) => call.method == 'isLanguageAvailable' ? true : null;

      expect(await service.isAvailable(), isTrue);
    });

    test('isAvailable() reflects a false platform response', () async {
      final service = FlutterTtsService(FlutterTts());
      handler = (call) => call.method == 'isLanguageAvailable' ? false : null;

      expect(await service.isAvailable(), isFalse);
    });

    test('stop() forwards to the platform channel', () async {
      final service = FlutterTtsService(FlutterTts());
      calls.clear();

      await service.stop();

      expect(calls.single.method, 'stop');
    });
  });
}
