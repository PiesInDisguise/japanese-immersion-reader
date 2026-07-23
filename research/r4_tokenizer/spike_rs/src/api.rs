//! The function(s) in this module are what `flutter_rust_bridge_codegen`
//! generates Dart bindings for. Kept deliberately close to the shape of the
//! app's real `Token` model (see lib/core/models/token.dart in the main
//! repo): surface / dict_form / reading / pos.
//!
//! Dictionary/resource loading here is hardcoded to this spike's on-disk
//! layout (resolved via `CARGO_MANIFEST_DIR` at compile time) purely to keep
//! the research spike self-contained. A real L2 integration would instead
//! take a dictionary path (or bytes) resolved from a Flutter asset at
//! runtime -- see docs/research/r4-tokenizer.md for the follow-up plan.

use std::path::PathBuf;
use std::sync::{Arc, OnceLock};

use sudachi::analysis::stateless_tokenizer::StatelessTokenizer;
use sudachi::analysis::Tokenize;
use sudachi::config::Config;
use sudachi::dic::dictionary::JapaneseDictionary;
use sudachi::prelude::Mode;

/// Mirrors the subset of `lib/core/models/token.dart`'s `Token` fields that
/// come from L2/Sudachi (i.e. everything except `surface` there is null
/// until this runs). `pos` is flattened to a comma-joined string here only
/// because wiring a `Vec<String>` through flutter_rust_bridge is exactly as
/// easy -- it was left a string purely so the printed spike output stays
/// readable; a real binding would return `Vec<String>` untouched.
pub struct TokenInfo {
    pub surface: String,
    pub dict_form: String,
    pub reading: String,
    pub pos: String,
}

static TOKENIZER: OnceLock<StatelessTokenizer<Arc<JapaneseDictionary>>> = OnceLock::new();

fn get_tokenizer() -> &'static StatelessTokenizer<Arc<JapaneseDictionary>> {
    TOKENIZER.get_or_init(|| {
        let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        let resource_dir = manifest_dir.join("resources");
        let dict_path = resource_dir.join("system_small.dic");
        let config = Config::new(None, Some(resource_dir), Some(dict_path))
            .expect("failed to build sudachi config");
        let dict = JapaneseDictionary::from_cfg(&config).expect("failed to load dictionary");
        StatelessTokenizer::new(Arc::new(dict))
    })
}

/// Tokenize Japanese text and return one `TokenInfo` per morpheme, in order.
/// This is the exact function `flutter_rust_bridge_codegen` generates a Dart
/// binding for in this spike.
pub fn tokenize(text: String) -> Vec<TokenInfo> {
    let tokenizer = get_tokenizer();
    let morphemes = tokenizer
        .tokenize(&text, Mode::C, false)
        .expect("tokenization failed");

    (0..morphemes.len())
        .map(|i| {
            let m = morphemes.get(i);
            // `.surface()` returns a `Ref<str>` guard; extract an owned
            // `String` in its own statement so the guard is dropped here,
            // rather than being held (and outliving its backing data) until
            // the end of the `TokenInfo { .. }` struct-literal expression.
            let surface = m.surface().to_string();
            TokenInfo {
                surface,
                dict_form: m.dictionary_form().to_string(),
                reading: m.reading_form().to_string(),
                pos: m.part_of_speech().join(","),
            }
        })
        .collect()
}
