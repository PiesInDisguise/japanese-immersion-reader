import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SudachiDictionaryPaths {
  const SudachiDictionaryPaths({
    required this.resourceDir,
    required this.dictionaryPath,
  });

  final String resourceDir;
  final String dictionaryPath;
}

/// Resolves where the Sudachi dictionary + resource files (char.def/unk.def/
/// rewrite.def) actually live on this device.
///
/// **This function is a placeholder for a real asset-bundling/first-run-
/// download flow, which is out of scope for this pass** (see
/// docs/research/r4-tokenizer.md §3/§6, and `sudachi_tokenizer.dart`'s doc
/// comment -- both already flagged this as deferred). It's written so the
/// *real* resolution slots in cleanly later without touching callers: it
/// checks the application-support directory first (tier 1 below), which is
/// where a real bundling/download flow would eventually place these files,
/// and only falls back to a dev-machine-only path if that's absent, so
/// nothing here needs to change once that flow exists -- files just start
/// appearing in tier 1 and tier 2 stops being reached.
///
/// Tier 2 (today's actual path on this dev machine) points at the
/// R4 research spike's already-downloaded dictionary
/// (`research/r4_tokenizer/spike_rs/resources/`, gitignored there --
/// large, licensed, freely re-fetchable, not committed, same reasoning as
/// everywhere else in this repo that references it) via the process's
/// current working directory, which is the project root when running via
/// `flutter run`/`flutter test` from there. This will NOT resolve correctly
/// from a packaged/installed app, which is exactly why it's a fallback and
/// not the primary path.
Future<SudachiDictionaryPaths> resolveSudachiDictionaryPaths() async {
  final supportDir = await getApplicationSupportDirectory();
  final bundled = SudachiDictionaryPaths(
    resourceDir: p.join(supportDir.path, 'sudachi', 'resources'),
    dictionaryPath: p.join(
      supportDir.path,
      'sudachi',
      'resources',
      'system_small.dic',
    ),
  );
  if (await Directory(bundled.resourceDir).exists() &&
      await File(bundled.dictionaryPath).exists()) {
    return bundled;
  }

  final devFallback = SudachiDictionaryPaths(
    resourceDir: p.join(
      Directory.current.path,
      'research',
      'r4_tokenizer',
      'spike_rs',
      'resources',
    ),
    dictionaryPath: p.join(
      Directory.current.path,
      'research',
      'r4_tokenizer',
      'spike_rs',
      'resources',
      'system_small.dic',
    ),
  );
  if (await Directory(devFallback.resourceDir).exists() &&
      await File(devFallback.dictionaryPath).exists()) {
    return devFallback;
  }

  throw StateError(
    'No Sudachi dictionary found in the application support directory or '
    'the dev fallback location (${devFallback.dictionaryPath}). Real '
    'dictionary bundling/download is not implemented yet -- see '
    'docs/research/r4-tokenizer.md.',
  );
}
