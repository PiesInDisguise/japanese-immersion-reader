// Plain `test()`, no widget tree, no real audio channel or application-
// support directory: both are seamed out via PitchAccentPlayer's own
// `playFile`/`resolveCacheDir` constructor params, backed here by an
// in-memory fake provider and a real (but temporary, test-owned) directory.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l6_audio/pitch_accent/pitch_accent_audio_provider.dart';
import 'package:japanese_immersion_reader/l6_audio/pitch_accent/pitch_accent_player.dart';

class _FakeAudioProvider implements PitchAccentAudioProvider {
  _FakeAudioProvider(this._byWord);

  final Map<String, Uint8List?> _byWord;
  int callCount = 0;

  @override
  Future<Uint8List?> fetchAudio({
    required String expression,
    required String reading,
  }) async {
    callCount++;
    return _byWord['$expression|$reading'];
  }
}

void main() {
  late Directory tempDir;
  late _FakeAudioProvider provider;
  late List<String> playedPaths;
  late PitchAccentPlayer player;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pitch_accent_test');
    playedPaths = [];
    provider = _FakeAudioProvider({
      '猫|ねこ': Uint8List.fromList([1, 2, 3, 4]),
      '無い|ない': null,
    });
    player = PitchAccentPlayer(
      provider,
      playFile: (path) async => playedPaths.add(path),
      resolveCacheDir: () async => tempDir,
    );
  });

  tearDown(() => tempDir.delete(recursive: true));

  group('PitchAccentPlayer.play', () {
    test('fetches, caches, and plays audio for a word that has it', () async {
      final played = await player.play(expression: '猫', reading: 'ねこ');

      expect(played, isTrue);
      expect(playedPaths, hasLength(1));
      expect(provider.callCount, 1);

      final cachedFile = File(playedPaths.single);
      expect(await cachedFile.exists(), isTrue);
      expect(await cachedFile.readAsBytes(), [1, 2, 3, 4]);
    });

    test('a second play() for the same word reuses the cache, no re-fetch', () async {
      await player.play(expression: '猫', reading: 'ねこ');
      await player.play(expression: '猫', reading: 'ねこ');

      expect(provider.callCount, 1);
      expect(playedPaths, hasLength(2));
      expect(playedPaths[0], playedPaths[1]);
    });

    test('returns false and plays nothing for a word with no recording', () async {
      final played = await player.play(expression: '無い', reading: 'ない');

      expect(played, isFalse);
      expect(playedPaths, isEmpty);
    });

    test(
      'a second play() for a word with no recording does not re-fetch',
      () async {
        await player.play(expression: '無い', reading: 'ない');
        await player.play(expression: '無い', reading: 'ない');

        expect(provider.callCount, 1);
      },
    );
  });
}
