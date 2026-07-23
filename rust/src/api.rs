//! Rust side of the Sudachi tokenizer integration (L2 linguistics layer).
//!
//! Ported from the R4 research spike (docs/research/r4-tokenizer.md), which
//! proved sudachi.rs compiles and tokenizes correctly through
//! flutter_rust_bridge on this stack (Sudachi.rs via flutter_rust_bridge,
//! correctly tokenizing 食べさせられた into 食べる + causative + passive +
//! past -- see docs/spec.md §8). Two production gaps fixed versus the spike:
//!
//! 1. No more `.expect()` panics: dictionary load and tokenization failures
//!    now return `Result::Err`, which flutter_rust_bridge turns into a
//!    catchable Dart exception (`TokenizerError`, below) instead of
//!    aborting the whole process across the FFI boundary.
//! 2. The dictionary/resource paths are runtime parameters to
//!    `init_tokenizer`, not a `CARGO_MANIFEST_DIR`-derived compile-time
//!    constant -- a real app resolves these to wherever the dictionary
//!    ends up at runtime (bundled asset, first-run download, ...); that
//!    resolution itself is out of scope for this pass (see
//!    docs/research/r4-tokenizer.md §3 and §6). Note this also sidesteps a
//!    latent portability trap in the spike's approach: `Config::new` (used
//!    by the spike) tries to load a `sudachi.json` from a location derived
//!    from *sudachi.rs's own* `CARGO_MANIFEST_DIR` before ever looking at
//!    the resource dir passed in, so the spike's `.expect()` only survived
//!    because sudachi.rs's git checkout on this dev machine happens to
//!    ship a `resources/sudachi.json` at that computed path -- that
//!    wouldn't exist in a packaged app on an end-user's device. Using
//!    `Config::minimal_at` (below) instead does no such file lookup: it
//!    builds a `Config` purely from the paths we pass in.
//!
//! `pos`/`inflection` extraction: sudachi.rs's `Morpheme` has no
//! inflection-only accessor -- `part_of_speech()` returns all six POS
//! components as one `&[String]`. See `split_pos` for the split.

use std::sync::{Arc, OnceLock};

use sudachi::analysis::stateless_tokenizer::StatelessTokenizer;
use sudachi::analysis::Tokenize;
use sudachi::config::Config;
use sudachi::dic::dictionary::JapaneseDictionary;
use sudachi::prelude::Mode;

static TOKENIZER: OnceLock<StatelessTokenizer<Arc<JapaneseDictionary>>> = OnceLock::new();

/// Errors surfaced across the FFI boundary as a catchable Dart exception.
/// flutter_rust_bridge generates a `TokenizerError` Dart class that
/// `implements Exception` for any non-`anyhow::Error` type used as a
/// `Result::Err`, so callers can `try { ... } on TokenizerError catch (e)`.
///
/// Deliberately carries only a message string per variant rather than the
/// original Sudachi error type -- Sudachi's own error types aren't (and
/// don't need to be) FFI-safe.
#[derive(Debug, Clone)]
pub enum TokenizerError {
    /// The dictionary or its resource files (char.def/unk.def/rewrite.def)
    /// failed to load from the given paths -- e.g. wrong path, missing
    /// file, or a corrupt/incompatible dictionary.
    DictionaryLoad(String),
    /// A Sudachi tokenization call itself failed. Rare in practice --
    /// Sudachi's tokenizer is total over any `&str` input -- but Sudachi's
    /// own API is fallible (e.g. pathological OOV/plugin errors), so this
    /// is surfaced rather than unwrapped.
    Tokenization(String),
    /// `tokenize` was called before `init_tokenizer` completed
    /// successfully.
    NotInitialized,
}

impl std::fmt::Display for TokenizerError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            TokenizerError::DictionaryLoad(msg) => {
                write!(f, "failed to load Sudachi dictionary: {msg}")
            }
            TokenizerError::Tokenization(msg) => write!(f, "Sudachi tokenization failed: {msg}"),
            TokenizerError::NotInitialized => {
                write!(f, "tokenize() called before init_tokenizer() completed")
            }
        }
    }
}

impl std::error::Error for TokenizerError {}

/// One Sudachi morpheme, shaped to match the L2-derived subset of
/// `lib/core/models/token.dart`'s `Token` fields -- everything a
/// `Tokenizer` populates (surface/dictForm/reading/pos/inflection). See
/// `lib/l2_linguistics/tokenizer/tokenizer.dart` for the Dart-side
/// contract this feeds.
#[derive(Debug, Clone)]
pub struct TokenInfo {
    pub surface: String,
    pub dict_form: String,
    pub reading: String,
    pub pos: String,
    /// Conjugation type + conjugated form (e.g. "下一段-バ行,連用形-一般"),
    /// or `None` for non-inflecting words (particles, nouns, ...). See
    /// `split_pos`.
    pub inflection: Option<String>,
}

/// Loads the Sudachi dictionary and prepares the tokenizer for `tokenize`
/// calls. Must be called once before `tokenize`; safe to call more than
/// once -- a call after successful initialization is a no-op success, so
/// app-startup code and test setup can call it unconditionally without
/// coordinating who calls it first.
///
/// `resource_dir` must contain `char.def`, `unk.def`, and `rewrite.def`
/// (sudachi.rs's own repo ships these under its top-level `resources/`).
/// `dictionary_path` is the path to a SudachiDict `.dic` file (e.g.
/// `system_small.dic`). Resolving these paths to wherever the app actually
/// bundles/downloads the dictionary is a follow-up -- see
/// docs/research/r4-tokenizer.md §3 and §6; this pass only makes the paths
/// injectable.
pub fn init_tokenizer(resource_dir: String, dictionary_path: String) -> Result<(), TokenizerError> {
    if TOKENIZER.get().is_some() {
        return Ok(());
    }

    // `Config::minimal_at` (unlike `Config::new`) does no file I/O of its
    // own -- it builds a `Config` purely from the given resource dir, so
    // dictionary-load failure here can only mean *our* paths were bad, not
    // a missing `sudachi.json` we never asked for (see module doc comment).
    let config = Config::minimal_at(resource_dir).with_system_dic(dictionary_path);
    let dict = JapaneseDictionary::from_cfg(&config)
        .map_err(|e| TokenizerError::DictionaryLoad(e.to_string()))?;

    // If a racing concurrent call already won `set`, discard this one --
    // both represent "initialized". Not expected to matter in practice
    // (callers await `init` before ever calling `tokenize`), but a stray
    // concurrent call should not panic.
    let _ = TOKENIZER.set(StatelessTokenizer::new(Arc::new(dict)));
    Ok(())
}

/// Tokenize Japanese text and return one `TokenInfo` per morpheme, in
/// order. Requires `init_tokenizer` to have completed first, or returns
/// `TokenizerError::NotInitialized`.
pub fn tokenize(text: String) -> Result<Vec<TokenInfo>, TokenizerError> {
    let tokenizer = TOKENIZER.get().ok_or(TokenizerError::NotInitialized)?;
    let morphemes = tokenizer
        .tokenize(&text, Mode::C, false)
        .map_err(|e| TokenizerError::Tokenization(e.to_string()))?;

    Ok((0..morphemes.len())
        .map(|i| {
            let m = morphemes.get(i);
            // `.surface()` returns a `Ref<str>` guard; extract an owned
            // `String` in its own statement so the guard is dropped here,
            // rather than being held until the end of the `TokenInfo { .. }`
            // struct-literal expression (same reasoning as the R4 spike).
            let surface = m.surface().to_string();
            let (pos, inflection) = split_pos(m.part_of_speech());
            TokenInfo {
                surface,
                dict_form: m.dictionary_form().to_string(),
                reading: m.reading_form().to_string(),
                pos,
                inflection,
            }
        })
        .collect())
}

/// Splits Sudachi's 6-component `part_of_speech()` array into a
/// human-facing part-of-speech string and an optional inflection string.
///
/// Sudachi has no separate inflection-only accessor on `Morpheme` --
/// `part_of_speech()` returns all six POS components as one `&[String]`
/// (confirmed against sudachi.rs's own `grammar.rs` test, which asserts
/// every `pos_list` entry has length 6): components 0-3 are the
/// (progressively finer, "*"-padded) part-of-speech classification;
/// components 4-5 are the conjugation type and conjugated form, meaningful
/// only for inflecting words (verbs, adjectives, auxiliary verbs) and
/// "*"/"*" otherwise -- e.g. 食べ -> `["動詞","一般","*","*","下一段-バ行","連用形-一般"]`,
/// 世界 -> `["名詞","普通名詞","一般","*","*","*"]`.
fn split_pos(components: &[String]) -> (String, Option<String>) {
    let pos_len = components.len().min(4);
    let pos_end = components[..pos_len]
        .iter()
        .rposition(|c| c != "*")
        .map(|i| i + 1)
        .unwrap_or(pos_len);
    let pos = components[..pos_end].join(",");

    let inflection = if components.len() >= 6 && components[5] != "*" {
        Some(format!("{},{}", components[4], components[5]))
    } else {
        None
    };

    (pos, inflection)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn s(values: &[&str]) -> Vec<String> {
        values.iter().map(|v| v.to_string()).collect()
    }

    #[test]
    fn split_pos_inflecting_verb() {
        // 食べ, from 食べさせられた -- the spec's own worked example (§8).
        let components = s(["動詞", "一般", "*", "*", "下一段-バ行", "連用形-一般"].as_slice());
        let (pos, inflection) = split_pos(&components);
        assert_eq!(pos, "動詞,一般");
        assert_eq!(inflection.as_deref(), Some("下一段-バ行,連用形-一般"));
    }

    #[test]
    fn split_pos_non_inflecting_noun_with_three_levels() {
        // 世界 (world) -- a common noun, three POS levels deep, no inflection.
        let components = s(["名詞", "普通名詞", "一般", "*", "*", "*"].as_slice());
        let (pos, inflection) = split_pos(&components);
        assert_eq!(pos, "名詞,普通名詞,一般");
        assert_eq!(inflection, None);
    }

    #[test]
    fn split_pos_non_inflecting_interjection_minimal_depth() {
        // こんにちは -- an interjection, only two POS levels used.
        let components = s(["感動詞", "一般", "*", "*", "*", "*"].as_slice());
        let (pos, inflection) = split_pos(&components);
        assert_eq!(pos, "感動詞,一般");
        assert_eq!(inflection, None);
    }

    #[test]
    fn split_pos_auxiliary_verb_inflection() {
        // させ (causative auxiliary), from 食べさせられた.
        let components = s(["助動詞", "*", "*", "*", "下一段-サ行", "未然形-一般"].as_slice());
        let (pos, inflection) = split_pos(&components);
        assert_eq!(pos, "助動詞");
        assert_eq!(inflection.as_deref(), Some("下一段-サ行,未然形-一般"));
    }
}
