// R4 research spike: prove that Dart can call sudachi.rs through
// flutter_rust_bridge-generated bindings and get back real morphological
// analysis (surface form, dictionary form, reading, part of speech).
//
// This is a plain Dart CLI, not a Flutter app -- see
// docs/research/r4-tokenizer.md for why, and what a real Flutter
// integration would additionally need.
//
// Run from this directory (research/r4_tokenizer/dart_spike):
//   dart run bin/main.dart

import 'package:r4_tokenizer_dart_spike/src/rust/frb_generated.dart';
import 'package:r4_tokenizer_dart_spike/src/rust/api.dart';

Future<void> main() async {
  await RustLib.init();

  const sentences = ['こんにちは世界', '食べさせられた'];

  for (final text in sentences) {
    print('\n=== $text ===');
    final tokens = await tokenize(text: text);
    for (final t in tokens) {
      print(
        'surface=${t.surface}\tdictForm=${t.dictForm}\treading=${t.reading}\tpos=${t.pos}',
      );
    }
  }

  RustLib.dispose();
}
