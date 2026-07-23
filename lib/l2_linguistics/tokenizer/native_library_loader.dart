import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'package:path/path.dart' as p;

import 'rust/frb_generated.dart';

/// Initializes flutter_rust_bridge against the compiled `sudachi_tokenizer`
/// native library, if it hasn't been already. Must be called (and awaited)
/// before constructing any [SudachiTokenizer] -- flutter_rust_bridge throws
/// `Bad state: flutter_rust_bridge has not been initialized` from any
/// generated call otherwise. Safe to call more than once; a call after
/// successful initialization is a no-op.
Future<void> ensureSudachiNativeLibraryInitialized() async {
  if (RustLib.instance.initialized) return;
  await RustLib.init(externalLibrary: _loadSudachiTokenizerLibrary());
}

/// Explicitly locates and opens the compiled native library, rather than
/// relying on flutter_rust_bridge's generated zero-config default
/// (`RustLib.init()` with no arguments). That default resolves
/// `rust/target/release/` relative to the *process* working directory at
/// runtime (see the generated `kDefaultExternalLibraryLoaderConfig` in
/// `rust/frb_generated.dart` and flutter_rust_bridge's own
/// `loadExternalLibrary`) -- correct when run from the project root with a
/// release build, but this makes the dependency explicit and also works
/// after a plain `cargo build` (debug profile), so callers don't silently
/// depend on which one was last run.
///
/// Like `dictionary_paths.dart`'s dev fallback, this is a placeholder for
/// real native-library bundling (a `.dll`/`.so`/`.dylib` shipped with the
/// packaged app via CMake/Gradle/an Xcode build phase, or a Dart
/// native-assets hook), which is out of scope for this pass -- see
/// docs/research/r4-tokenizer.md §6. It only works when running from a
/// dev machine with `rust/target/{release,debug}` already built via
/// `cargo build`.
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
    'Compiled $fileName not found under $rustTargetDir (checked release/ '
    'and debug/). Run `cargo build` (or `cargo build --release`) in rust/ '
    'first -- see docs/research/r4-tokenizer.md.',
  );
}
