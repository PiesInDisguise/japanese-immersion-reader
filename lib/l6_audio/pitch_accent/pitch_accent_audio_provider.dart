import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Fetches a real audio recording for a Japanese word -- spec §9's
/// "downloadable pitch-accent data". `null` means no recording exists for
/// this word (a normal, expected outcome for obscure/rare words, not an
/// error).
abstract class PitchAccentAudioProvider {
  Future<Uint8List?> fetchAudio({
    required String expression,
    required String reading,
  });
}

/// Real implementation against `assets.languagepod101.com`'s public,
/// unauthenticated pitch-accent/pronunciation audio endpoint -- the same
/// free source many existing open-source Anki/Yomitan pitch-accent-audio
/// add-ons use as their default.
///
/// **The "not found" signature was verified empirically, not assumed**:
/// two different nonexistent-word queries against the real endpoint both
/// returned an HTTP 200 with a byte-identical 52288-byte MP3 clip -- a
/// fixed placeholder, not a 404. Naively treating "small response" as "not
/// found" would have been backwards here: that placeholder is *larger*
/// than many genuine short-word clips (e.g. 猫/ねこ's real clip is 1872
/// bytes). [_notFoundMd5] is that exact placeholder's hash.
class LanguagePod101AudioProvider implements PitchAccentAudioProvider {
  LanguagePod101AudioProvider({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const _baseUrl =
      'https://assets.languagepod101.com/dictionary/japanese/audiomp3.php';

  static const _notFoundMd5 = '7e2c2f954ef6051373ba916f000168dc';

  @override
  Future<Uint8List?> fetchAudio({
    required String expression,
    required String reading,
  }) async {
    final uri = Uri.parse(
      _baseUrl,
    ).replace(queryParameters: {'kanji': expression, 'kana': reading});
    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) return null;

    final bytes = response.bodyBytes;
    if (bytes.isEmpty) return null;
    if (md5.convert(bytes).toString() == _notFoundMd5) return null;
    return bytes;
  }
}
