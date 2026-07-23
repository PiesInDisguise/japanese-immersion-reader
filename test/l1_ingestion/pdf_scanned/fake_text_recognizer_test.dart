import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/fake_text_recognizer.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/text_recognizer.dart';

void main() {
  group('FakeTextRecognizer', () {
    test('falls back to a canned テスト result when unconfigured', () async {
      const recognizer = FakeTextRecognizer();
      final result = await recognizer.recognizeCrop(
        Uint8List(10),
        width: 30,
        height: 40,
        vertical: false,
      );
      expect(result.text, 'テスト');
      expect(result.confidence, 0.9);
    });

    test('defaultText/defaultConfidence override the built-in fallback', () async {
      const recognizer = FakeTextRecognizer(
        defaultText: '固定',
        defaultConfidence: 0.13,
      );
      final result = await recognizer.recognizeCrop(
        Uint8List(0),
        width: 1,
        height: 1,
        vertical: false,
      );
      expect(result.text, '固定');
      expect(result.confidence, 0.13);
    });

    test('textForCropSize selects by exact (width, height)', () async {
      const small = RecognizedText(text: '小', confidence: 0.1);
      const big = RecognizedText(text: '大', confidence: 0.2);
      const recognizer = FakeTextRecognizer(
        textForCropSize: {(10, 20): small, (100, 200): big},
        defaultText: 'デフォルト',
      );

      expect(
        await recognizer.recognizeCrop(
          Uint8List(0),
          width: 10,
          height: 20,
          vertical: false,
        ),
        same(small),
      );
      expect(
        await recognizer.recognizeCrop(
          Uint8List(0),
          width: 100,
          height: 200,
          vertical: true,
        ),
        same(big),
      );
      final fallback = await recognizer.recognizeCrop(
        Uint8List(0),
        width: 1,
        height: 1,
        vertical: false,
      );
      expect(
        fallback.text,
        'デフォルト',
        reason: 'falls back to defaultText for an unrecognized size',
      );
    });

    test(
      'output is a pure function of arguments, not calling order or count '
      '(see class doc comment on why: real callers may invoke this across '
      'an isolate boundary that only ever sees copies)',
      () async {
        const recognizer = FakeTextRecognizer();
        final first = await recognizer.recognizeCrop(
          Uint8List(0),
          width: 5,
          height: 5,
          vertical: false,
        );
        final second = await recognizer.recognizeCrop(
          Uint8List(0),
          width: 5,
          height: 5,
          vertical: false,
        );
        expect(first, equals(second));
      },
    );
  });
}
