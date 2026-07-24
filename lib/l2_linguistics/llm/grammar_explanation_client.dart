import 'dart:convert';

import 'package:http/http.dart' as http;

/// Streams a natural-language grammar explanation for one sentence (spec §8
/// layer 3), given its surrounding context. Implementations own the actual
/// network/prompt mechanics; callers (see `reader_mining_session.dart`) own
/// deciding *whether* to call this at all (an API key configured, the
/// feature toggled on -- see `app/settings_repository.dart`) and the
/// permanent by-content cache that makes this "paid for once" per spec.
///
/// A `Stream<String>` of *cumulative* text-so-far (not per-chunk deltas) --
/// each emission is the full explanation as received up to that point, so a
/// caller can just display the latest emission directly without needing its
/// own accumulation logic.
abstract class GrammarExplanationClient {
  Stream<String> streamExplanation({
    required String sentenceText,
    required String contextText,
  });
}

/// Real implementation calling Anthropic's Messages API directly with the
/// user's own API key (spec §2: "BYO", no hosted proxy -- this project never
/// sees or stores anyone's key but the user's own, and never relays through
/// any server this project runs).
class AnthropicGrammarExplanationClient implements GrammarExplanationClient {
  AnthropicGrammarExplanationClient({
    required this.apiKey,
    this.model = defaultModel,
    this.maxTokens = 400,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// A small, fast model is the right choice here: this runs once per
  /// sentence a reader actually opens (not proactively for a whole
  /// chapter), and the permanent cache (spec §8) means even a mediocre
  /// explanation only gets regenerated if the cache is cleared -- cost and
  /// latency matter more than this specific task needing the strongest
  /// available model.
  static const defaultModel = 'claude-haiku-4-5-20251001';

  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _anthropicVersion = '2023-06-01';

  final String apiKey;
  final String model;
  final int maxTokens;
  final http.Client _httpClient;

  @override
  Stream<String> streamExplanation({
    required String sentenceText,
    required String contextText,
  }) async* {
    final request = http.Request('POST', Uri.parse(_apiUrl))
      ..headers['x-api-key'] = apiKey
      ..headers['anthropic-version'] = _anthropicVersion
      ..headers['content-type'] = 'application/json'
      ..body = jsonEncode({
        'model': model,
        'max_tokens': maxTokens,
        'stream': true,
        'messages': [
          {'role': 'user', 'content': _buildPrompt(sentenceText, contextText)},
        ],
      });

    final response = await _httpClient.send(request);
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw StateError(
        'AnthropicGrammarExplanationClient: API returned '
        '${response.statusCode}: $body',
      );
    }

    final buffer = StringBuffer();
    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      // Every real payload line is prefixed "data: "; blank lines and
      // "event: <name>" lines (Anthropic sends both per SSE event) are not
      // JSON and must be skipped rather than fed to jsonDecode.
      if (!line.startsWith('data: ')) continue;
      final payload = line.substring('data: '.length);

      final event = jsonDecode(payload) as Map<String, dynamic>;
      if (event['type'] != 'content_block_delta') continue;
      final delta = event['delta'] as Map<String, dynamic>;
      if (delta['type'] != 'text_delta') continue;
      buffer.write(delta['text'] as String);
      yield buffer.toString();
    }
  }

  static String _buildPrompt(String sentenceText, String contextText) {
    final contextSection = contextText.isEmpty
        ? ''
        : 'Surrounding context, for resolving ambiguity (do not explain '
              'this part):\n$contextText\n\n';
    return '$contextSection'
        'Sentence to explain:\n$sentenceText\n\n'
        'You are helping a Japanese-language learner reading a light novel. '
        'In 2-4 sentences, explain what is grammatically interesting or '
        'potentially confusing about this specific sentence -- word order, '
        'omitted subjects/objects, ambiguous particles, idiomatic '
        'expressions, or nuance the surrounding context resolves. Do not '
        'give a full translation or a word-by-word breakdown (the reader '
        'already has that); focus on the grammar itself.';
  }
}
