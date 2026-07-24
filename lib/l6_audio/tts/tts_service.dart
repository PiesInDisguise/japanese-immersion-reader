import 'package:flutter_tts/flutter_tts.dart';

/// Spec §9's on-device TTS, "for words and full sentences" -- a single
/// [speak] method serves both (the caller decides whether the text it
/// passes is one word or a whole sentence; the service itself has no
/// separate word/sentence mode).
abstract class TtsService {
  /// Whether a Japanese voice is actually available on this device --
  /// checked so callers (Settings, the reader UI) can hide/disable
  /// playback controls gracefully rather than calling [speak] and having it
  /// silently do nothing (real risk on Windows, where a ja-JP voice isn't
  /// installed by default on every machine).
  Future<bool> isAvailable();

  /// Speaks [text] aloud, replacing whatever this service was already
  /// speaking (implementations should stop any in-progress utterance
  /// first, mirroring "tap a different word mid-utterance" cutting off the
  /// previous one rather than queuing).
  Future<void> speak(String text);

  Future<void> stop();
}

/// Real implementation wrapping `package:flutter_tts` (confirmed real
/// Windows support via UWP voices, not just Android/iOS -- see the
/// package's own README/source before this was depended on). Configured
/// for Japanese once at construction; every [speak] call replaces
/// in-progress speech rather than queuing, matching a reader tapping a new
/// word before the previous one finishes.
class FlutterTtsService implements TtsService {
  FlutterTtsService([FlutterTts? tts]) : _tts = tts ?? FlutterTts() {
    _tts.setLanguage(_japaneseLocale);
  }

  static const _japaneseLocale = 'ja-JP';

  final FlutterTts _tts;

  @override
  Future<bool> isAvailable() async {
    final result = await _tts.isLanguageAvailable(_japaneseLocale);
    return result == true || result == 1;
  }

  @override
  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}
