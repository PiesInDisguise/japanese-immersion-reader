// Shared setup for tests that exercise the *real* compiled Sudachi native
// library (as opposed to a fake/mock) -- see docs/research/r4-tokenizer.md
// and lib/l2_linguistics/tokenizer/sudachi_tokenizer.dart.
//
// Not a `_test.dart` file itself -- it has no tests of its own, only
// helpers imported by sudachi_tokenizer_test.dart and
// sudachi_reconcile_integration_test.dart.

import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:japanese_immersion_reader/l2_linguistics/tokenizer/rust/frb_generated.dart';
import 'package:japanese_immersion_reader/l2_linguistics/tokenizer/sudachi_tokenizer.dart';
import 'package:path/path.dart' as p;

/// Directory containing the R4 research spike's already-downloaded
/// dictionary and its support files (char.def/unk.def/rewrite.def) --
/// reused here rather than committing a second ~118MB copy of the
/// dictionary (see research/r4_tokenizer/spike_rs/resources/.gitignore).
///
/// This research-owned path is for test setup only. Production code (see
/// `SudachiTokenizer.create`) always takes the dictionary/resource paths
/// as caller-supplied parameters and never hardcodes this path -- real
/// dictionary delivery (bundling/download) is a follow-up, see
/// docs/research/r4-tokenizer.md §3 and §6.
String get _researchResourceDir => p.join(
  Directory.current.path,
  'research',
  'r4_tokenizer',
  'spike_rs',
  'resources',
);

String get _researchDictionaryPath =>
    p.join(_researchResourceDir, 'system_small.dic');

/// Whether the research dictionary this test setup reuses is present on
/// disk. False in a fresh checkout that never ran the R4 spike's fetch
/// step (docs/research/r4-tokenizer.md Appendix) -- callers should skip
/// (via `markTestSkipped`) rather than fail when this is false, since it's
/// a large, separately-fetched, gitignored binary rather than something
/// this task's own build produces.
bool get sudachiTestDictionaryAvailable =>
    File(_researchDictionaryPath).existsSync();

/// Loads the real compiled `sudachi_tokenizer` native library, initializes
/// flutter_rust_bridge against it, and returns a [SudachiTokenizer] backed
/// by the R4 research spike's dictionary.
///
/// Only call this when [sudachiTestDictionaryAvailable] is true.
Future<SudachiTokenizer> createTestSudachiTokenizer() async {
  if (!RustLib.instance.initialized) {
    await RustLib.init(externalLibrary: _loadSudachiTokenizerLibrary());
  }

  return SudachiTokenizer.create(
    resourceDir: _researchResourceDir,
    dictionaryPath: _researchDictionaryPath,
  );
}

/// Explicitly locates and opens the compiled native library, rather than
/// relying on flutter_rust_bridge's generated zero-config default
/// (`RustLib.init()` with no arguments). That default resolves
/// `rust/target/release/` relative to the *process* working directory at
/// runtime (see the generated `kDefaultExternalLibraryLoaderConfig` in
/// rust/frb_generated.dart and flutter_rust_bridge's own
/// `loadExternalLibrary`) -- correct when `flutter test` is run from the
/// project root and `cargo build --release` was used, but this makes the
/// dependency explicit and also works after a plain `cargo build` (debug
/// profile), so this test doesn't silently depend on which one was last
/// run.
ExternalLibrary _loadSudachiTokenizerLibrary() {
  const stem = 'sudachi_tokenizer';
  final String fileName;
  if (Platform.isWindows) {
    fileName = '$stem.dll';
  } else if (Platform.isMacOS || Platform.isIOS) {
    fileName = 'lib$stem.dylib';
  } else {
    fileName = 'lib$stem.so';
  }

  final rustTargetDir = p.join(Directory.current.path, 'rust', 'target');
  for (final profile in ['release', 'debug']) {
    final candidate = p.join(rustTargetDir, profile, fileName);
    if (File(candidate).existsSync()) {
      return ExternalLibrary.open(candidate);
    }
  }

  throw StateError(
    'Compiled $fileName not found under $rustTargetDir (checked '
    'release/ and debug/). Run `cargo build` (or `cargo build --release`) '
    'in rust/ before running this test.',
  );
}
