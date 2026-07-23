// Shared setup for tests that exercise the *real* compiled Sudachi native
// library (as opposed to a fake/mock) -- see docs/research/r4-tokenizer.md
// and lib/l2_linguistics/tokenizer/sudachi_tokenizer.dart.
//
// Not a `_test.dart` file itself -- it has no tests of its own, only
// helpers imported by sudachi_tokenizer_test.dart and
// sudachi_reconcile_integration_test.dart.

import 'dart:io';

import 'package:japanese_immersion_reader/l2_linguistics/tokenizer/native_library_loader.dart';
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
  await ensureSudachiNativeLibraryInitialized();

  return SudachiTokenizer.create(
    resourceDir: _researchResourceDir,
    dictionaryPath: _researchDictionaryPath,
  );
}
