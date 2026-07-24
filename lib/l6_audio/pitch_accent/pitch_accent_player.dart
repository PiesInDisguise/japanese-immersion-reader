import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:japanese_immersion_reader/core/ids/stable_id.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'pitch_accent_audio_provider.dart';

/// Spec §9: "pitch-accent audio via downloadable data, network only for the
/// initial download". Fetches a word's real pronunciation clip via
/// [PitchAccentAudioProvider] on first request, caches it to disk (same
/// fetch-once-then-local pattern as `ModelFetcher` in
/// `l1_ingestion/pdf_scanned/`), and plays back from that local cache on
/// every later request -- never re-fetching, whether the word had audio or
/// not (a `.missing` marker remembers "no recording exists" too, so a
/// word without audio isn't re-queried over the network every time it's
/// tapped).
class PitchAccentPlayer {
  /// [playFile] is the actual "play this local audio file" step, and
  /// [resolveCacheDir] resolves the directory audio gets cached under --
  /// both seamed out (rather than this class touching `AudioPlayer`/
  /// `path_provider`'s platform channels directly in a way tests can't
  /// intercept) so tests never open a real platform audio channel or need a
  /// real application-support directory -- same reasoning as
  /// `OcrEngineFactory` in `l1_ingestion/pdf_scanned/`. Both default to the
  /// real thing (`package:audioplayers`, `getApplicationSupportDirectory`).
  PitchAccentPlayer(
    this._provider, {
    Future<void> Function(String path)? playFile,
    Future<Directory> Function()? resolveCacheDir,
  }) : _playFile = playFile ?? _defaultPlayFile,
       _resolveCacheDir = resolveCacheDir ?? getApplicationSupportDirectory;

  final PitchAccentAudioProvider _provider;
  final Future<void> Function(String path) _playFile;
  final Future<Directory> Function() _resolveCacheDir;

  static final _sharedAudioPlayer = AudioPlayer();

  static Future<void> _defaultPlayFile(String path) async {
    await _sharedAudioPlayer.stop();
    await _sharedAudioPlayer.play(DeviceFileSource(path));
  }

  /// Plays [expression]/[reading]'s pitch-accent audio. Returns `false`
  /// (and plays nothing) if no recording exists for this word -- callers
  /// must treat that as "no audio available" rather than an error, the same
  /// "null/false means unavailable" contract `DocumentRepository` uses
  /// elsewhere in this app.
  Future<bool> play({
    required String expression,
    required String reading,
  }) async {
    final audioFile = await _audioCacheFile(
      expression: expression,
      reading: reading,
    );
    final missingMarker = File('${audioFile.path}.missing');

    if (await missingMarker.exists()) return false;

    if (!await audioFile.exists()) {
      final bytes = await _provider.fetchAudio(
        expression: expression,
        reading: reading,
      );
      if (bytes == null) {
        await missingMarker.parent.create(recursive: true);
        await missingMarker.create();
        return false;
      }
      await audioFile.parent.create(recursive: true);
      await audioFile.writeAsBytes(bytes);
    }

    await _playFile(audioFile.path);
    return true;
  }

  /// Keyed by the same content-derived id as a word's own collection entry
  /// (`contentDerivedWordId`) -- reused here purely as a stable,
  /// filesystem-safe identifier for a (dictForm, reading) pair, not because
  /// this cache has anything to do with the collection layer.
  Future<File> _audioCacheFile({
    required String expression,
    required String reading,
  }) async {
    final supportDir = await _resolveCacheDir();
    final id = contentDerivedWordId(dictForm: expression, reading: reading);
    return File(p.join(supportDir.path, 'pitch_accent_audio', '$id.mp3'));
  }
}
