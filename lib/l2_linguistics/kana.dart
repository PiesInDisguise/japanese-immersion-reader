/// Converts full-width katakana to hiragana, one character at a time.
///
/// Sudachi's own token readings are always katakana (its convention --
/// `SudachiTokenizer`'s output, see `l2_linguistics/tokenizer/`), but
/// dictionary readings (Yomitan's `readingNormalized`, and this app's own
/// display conventions) are hiragana. Two real call sites need this:
///
/// - **Display**: `TokenGlossView`/`WordLookupSheet` show a Sudachi
///   reading directly to the reader -- without conversion it renders in
///   katakana, which reads as visually distinct from (and inconsistent
///   with) every dictionary-sourced reading shown elsewhere in the same
///   popup.
/// - **Lookup**: `DictionaryRepository`'s reading-match branch compares a
///   Sudachi reading against Yomitan's `readingNormalized` column via exact
///   SQL equality -- without conversion, a katakana value can never equal
///   a hiragana one, so that branch silently never contributes a match
///   (headword matching still works independently, which is why this went
///   unnoticed until a reading-only lookup was tried).
///
/// Characters outside the katakana letter range (kanji, ASCII, punctuation,
/// the prolonged-sound mark 'ー', the katakana middle dot '・') pass
/// through unchanged -- 'ー' in particular is deliberately *not* converted:
/// it's a length mark applied after a vowel, not a katakana letter with its
/// own hiragana counterpart.
String katakanaToHiragana(String input) {
  const katakanaStart = 0x30A1; // ァ
  const katakanaEnd = 0x30F6; // ヶ
  const hiraganaOffset = 0x60;

  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= katakanaStart && rune <= katakanaEnd) {
      buffer.writeCharCode(rune - hiraganaOffset);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}
