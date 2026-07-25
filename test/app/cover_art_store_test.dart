import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/cover_art_store.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late CoverArtStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cover_art_store_test_');
    store = CoverArtStore(directoryOverride: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('write persists bytes under <directoryOverride>/<documentId> and '
      'returns that path', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);

    final path = await store.write('doc-1', bytes);

    expect(path, p.join(tempDir.path, 'doc-1'));
    expect(await File(path).readAsBytes(), bytes);
  });

  test('writing twice for the same documentId overwrites, not accumulates', () async {
    await store.write('doc-1', Uint8List.fromList([1, 2, 3]));
    final path = await store.write('doc-1', Uint8List.fromList([9, 9]));

    expect(await File(path).readAsBytes(), [9, 9]);
    expect(await tempDir.list().length, 1);
  });

  test('different documentIds get independent files', () async {
    final pathA = await store.write('doc-a', Uint8List.fromList([1]));
    final pathB = await store.write('doc-b', Uint8List.fromList([2]));

    expect(pathA, isNot(pathB));
    expect(await File(pathA).readAsBytes(), [1]);
    expect(await File(pathB).readAsBytes(), [2]);
  });
}
