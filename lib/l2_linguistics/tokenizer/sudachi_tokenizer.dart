import 'package:japanese_immersion_reader/core/models/models.dart';

import 'rust/api.dart' as rust;
import 'tokenizer.dart';

/// Real (Sudachi) tokenizer, backed by sudachi.rs compiled to a native
/// library and called through flutter_rust_bridge-generated FFI bindings
/// (see rust/src/api.rs and docs/research/r4-tokenizer.md for the research
/// spike this was ported from).
///
/// Must be constructed via [SudachiTokenizer.create], which loads the
/// dictionary. Dictionary/tokenization failures on the Rust side surface
/// here as a catchable `TokenizerError` (see `rust/api.dart`) rather than
/// crashing the app -- flutter_rust_bridge turns the Rust `Result::Err`
/// into a normal thrown Dart exception.
class SudachiTokenizer implements Tokenizer {
  SudachiTokenizer._();

  /// Loads the Sudachi dictionary from [dictionaryPath] (a SudachiDict
  /// `.dic` file) using the support files (char.def/unk.def/rewrite.def)
  /// found in [resourceDir], and returns a ready-to-use tokenizer.
  ///
  /// Safe to call more than once -- the underlying Rust dictionary load is
  /// idempotent (see `init_tokenizer` in rust/src/api.rs), so independent
  /// callers during app startup don't need to coordinate who calls this
  /// first.
  ///
  /// Resolving [dictionaryPath]/[resourceDir] to wherever the app actually
  /// bundles or downloads the dictionary is out of scope for this pass --
  /// see docs/research/r4-tokenizer.md §3 and §6. Callers own that
  /// resolution and pass the resulting paths in here.
  static Future<SudachiTokenizer> create({
    required String resourceDir,
    required String dictionaryPath,
  }) async {
    await rust.initTokenizer(
      resourceDir: resourceDir,
      dictionaryPath: dictionaryPath,
    );
    return SudachiTokenizer._();
  }

  @override
  Future<List<Token>> tokenize(String text) async {
    final infos = await rust.tokenize(text: text);
    return infos.map(_toToken).toList();
  }

  Token _toToken(rust.TokenInfo info) => Token(
    surface: info.surface,
    dictForm: info.dictForm,
    reading: info.reading,
    pos: info.pos,
    inflection: info.inflection,
  );
}
