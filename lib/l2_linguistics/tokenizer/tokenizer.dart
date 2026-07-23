import 'package:japanese_immersion_reader/core/models/models.dart';

/// Real (Sudachi) word segmentation of plain text, position-blind.
///
/// This is deliberately the mirror image of L1's pre-L2 placeholder tokens:
/// a `Tokenizer` never sees page geometry or OCR confidence (it only ever
/// gets a plain `String`), so every `Token` it returns has `surface`,
/// `dictForm`, `reading`, `pos`, and `inflection` populated, and
/// `sourceRect`/`confidence` always null. [reconcileSentenceTokens] is what
/// combines this output with L1's position-aware tokens into the final
/// per-sentence token list.
abstract class Tokenizer {
  Future<List<Token>> tokenize(String text);
}
