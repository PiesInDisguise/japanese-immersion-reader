// Plain `test()`, not `testWidgets` -- this suite exercises pure
// HTTP/SSE-parsing logic with no Flutter widget tree involved, so it isn't
// subject to this project's known `testWidgets`+`rootBundle` hang (see the
// commit history around the grammar-point database for the full
// investigation). Real network access is never used: [http.BaseClient.send]
// is overridden with a canned in-memory response.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:japanese_immersion_reader/l2_linguistics/llm/grammar_explanation_client.dart';

/// Responds with a fixed status code and a fixed sequence of raw SSE lines
/// (already including the "data: "/"event: " framing a real Anthropic
/// response would use), regardless of what request is sent. Records the
/// single request it received for assertions.
class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient({required this.statusCode, required this.sseLines});

  final int statusCode;
  final List<String> sseLines;
  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    final bytes = utf8.encode(sseLines.map((l) => '$l\n').join());
    final stream = Stream<List<int>>.fromIterable([bytes]);
    return http.StreamedResponse(stream, statusCode);
  }

  @override
  void close() {}
}

void main() {
  group('AnthropicGrammarExplanationClient', () {
    test('sends the API key, version header, and prompt content', () async {
      final fake = _FakeHttpClient(
        statusCode: 200,
        sseLines: [
          'event: message_start',
          'data: {"type":"message_start"}',
          '',
          'event: message_stop',
          'data: {"type":"message_stop"}',
        ],
      );
      final client = AnthropicGrammarExplanationClient(
        apiKey: 'sk-test-123',
        httpClient: fake,
      );

      await client
          .streamExplanation(sentenceText: '猫が好きです。', contextText: '')
          .drain<void>();

      final sent = fake.lastRequest! as http.Request;
      expect(sent.headers['x-api-key'], 'sk-test-123');
      expect(sent.headers['anthropic-version'], isNotEmpty);
      expect(sent.body, contains('猫が好きです'));
      expect(sent.url, Uri.parse('https://api.anthropic.com/v1/messages'));
    });

    test(
      'yields cumulative text as content_block_delta events arrive',
      () async {
        final fake = _FakeHttpClient(
          statusCode: 200,
          sseLines: [
            'event: content_block_delta',
            'data: {"type":"content_block_delta","index":0,'
                '"delta":{"type":"text_delta","text":"This "}}',
            '',
            'event: content_block_delta',
            'data: {"type":"content_block_delta","index":0,'
                '"delta":{"type":"text_delta","text":"is a "}}',
            '',
            'event: content_block_delta',
            'data: {"type":"content_block_delta","index":0,'
                '"delta":{"type":"text_delta","text":"test."}}',
            '',
            'event: message_stop',
            'data: {"type":"message_stop"}',
          ],
        );
        final client = AnthropicGrammarExplanationClient(
          apiKey: 'sk-test',
          httpClient: fake,
        );

        final emissions = await client
            .streamExplanation(sentenceText: 'sentence', contextText: '')
            .toList();

        expect(emissions, ['This ', 'This is a ', 'This is a test.']);
      },
    );

    test('ignores non-content_block_delta event types', () async {
      final fake = _FakeHttpClient(
        statusCode: 200,
        sseLines: [
          'event: message_start',
          'data: {"type":"message_start","message":{"id":"msg_1"}}',
          '',
          'event: content_block_start',
          'data: {"type":"content_block_start","index":0,'
              '"content_block":{"type":"text","text":""}}',
          '',
          'event: content_block_delta',
          'data: {"type":"content_block_delta","index":0,'
              '"delta":{"type":"text_delta","text":"Hi"}}',
          '',
          'event: content_block_stop',
          'data: {"type":"content_block_stop","index":0}',
          '',
          'event: message_delta',
          'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"}}',
          '',
          'event: message_stop',
          'data: {"type":"message_stop"}',
        ],
      );
      final client = AnthropicGrammarExplanationClient(
        apiKey: 'sk-test',
        httpClient: fake,
      );

      final emissions = await client
          .streamExplanation(sentenceText: 'sentence', contextText: '')
          .toList();

      expect(emissions, ['Hi']);
    });

    test('throws with the response body on a non-200 status', () async {
      final fake = _FakeHttpClient(
        statusCode: 401,
        sseLines: ['{"type":"error","error":{"message":"invalid x-api-key"}}'],
      );
      final client = AnthropicGrammarExplanationClient(
        apiKey: 'sk-bad',
        httpClient: fake,
      );

      await expectLater(
        client
            .streamExplanation(sentenceText: 'sentence', contextText: '')
            .drain<void>(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('invalid x-api-key'),
          ),
        ),
      );
    });
  });
}
