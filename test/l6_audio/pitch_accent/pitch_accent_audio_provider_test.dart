// Plain `test()`, no widget tree, no real network call: http.Client.send is
// overridden with a canned in-memory response, same pattern as
// grammar_explanation_client_test.dart.
//
// fixtures/not_found_placeholder.mp3 is the *real* placeholder captured
// directly from the live assets.languagepod101.com endpoint during
// development (two different nonexistent-word queries against the real
// endpoint both returned this exact byte-identical 52288-byte file) -- not
// a synthetic stand-in. Its md5 is the production class's own
// `_notFoundMd5` constant.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:japanese_immersion_reader/l6_audio/pitch_accent/pitch_accent_audio_provider.dart';

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient({required this.statusCode, required this.bytes});

  final int statusCode;
  final Uint8List bytes;
  Uri? lastRequestedUri;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequestedUri = request.url;
    return http.StreamedResponse(
      Stream.value(bytes),
      statusCode,
      contentLength: bytes.length,
    );
  }

  @override
  void close() {}
}

void main() {
  group('LanguagePod101AudioProvider', () {
    test('returns the response bytes for a real word', () async {
      final realAudioBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final fake = _FakeHttpClient(statusCode: 200, bytes: realAudioBytes);
      final provider = LanguagePod101AudioProvider(httpClient: fake);

      final result = await provider.fetchAudio(
        expression: '猫',
        reading: 'ねこ',
      );

      expect(result, realAudioBytes);
      expect(fake.lastRequestedUri!.queryParameters['kanji'], '猫');
      expect(fake.lastRequestedUri!.queryParameters['kana'], 'ねこ');
    });

    test('returns null on a non-200 status', () async {
      final fake = _FakeHttpClient(
        statusCode: 404,
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      final provider = LanguagePod101AudioProvider(httpClient: fake);

      expect(
        await provider.fetchAudio(expression: 'x', reading: 'x'),
        isNull,
      );
    });

    test('returns null for an empty response body', () async {
      final fake = _FakeHttpClient(statusCode: 200, bytes: Uint8List(0));
      final provider = LanguagePod101AudioProvider(httpClient: fake);

      expect(
        await provider.fetchAudio(expression: 'x', reading: 'x'),
        isNull,
      );
    });

    test(
      'recognizes the real captured not-found placeholder clip and returns '
      'null, even though it is larger than a real short-word clip',
      () async {
        final placeholderBytes = await File(
          'test/l6_audio/pitch_accent/fixtures/not_found_placeholder.mp3',
        ).readAsBytes();
        final fake = _FakeHttpClient(
          statusCode: 200,
          bytes: placeholderBytes,
        );
        final provider = LanguagePod101AudioProvider(httpClient: fake);

        expect(
          await provider.fetchAudio(expression: 'x', reading: 'x'),
          isNull,
        );
      },
    );
  });
}
