//! Exercises the real, compiled Sudachi pipeline (dictionary load +
//! tokenization) from the Rust side, independent of the Dart/FFI layer --
//! isolating "does our Rust logic work" from "does FFI marshaling work"
//! (the latter is covered by the Dart-side tests in
//! test/l2_linguistics/tokenizer/, which are the load-bearing proof for
//! this integration pass).
//!
//! Reuses the R4 research spike's already-downloaded dictionary
//! (research/r4_tokenizer/spike_rs/resources/) rather than committing a
//! second ~118MB copy -- see that directory's own .gitignore/comment. Skips
//! (rather than failing) when that dictionary is absent, e.g. in a fresh
//! checkout that never ran the R4 spike's fetch step. This research-owned
//! path is for test setup only, never a production code path -- production
//! callers (e.g. SudachiTokenizer.create in the Dart app) always pass in
//! their own resolved paths.

use std::path::{Path, PathBuf};

use sudachi_tokenizer::api::{init_tokenizer, tokenize};

fn research_resource_dir() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../research/r4_tokenizer/spike_rs/resources")
}

#[test]
fn tokenizes_causative_passive_past_chain_with_real_dictionary() {
    let resource_dir = research_resource_dir();
    let dictionary_path = resource_dir.join("system_small.dic");
    if !dictionary_path.exists() {
        eprintln!(
            "skipping tokenizes_causative_passive_past_chain_with_real_dictionary: \
             research dictionary not present at {}. Run the R4 spike's fetch step \
             (docs/research/r4-tokenizer.md Appendix) to populate it.",
            dictionary_path.display()
        );
        return;
    }

    init_tokenizer(
        resource_dir.to_string_lossy().into_owned(),
        dictionary_path.to_string_lossy().into_owned(),
    )
    .expect("dictionary load should succeed when system_small.dic is present");

    // The spec's own worked example (docs/spec.md §8): 食べさせられた ->
    // 食べる + causative + passive + past.
    let tokens = tokenize("食べさせられた".to_string()).expect("tokenization should succeed");

    let surfaces: Vec<&str> = tokens.iter().map(|t| t.surface.as_str()).collect();
    assert_eq!(surfaces, vec!["食べ", "させ", "られ", "た"]);

    assert_eq!(tokens[0].dict_form, "食べる");
    assert_eq!(tokens[0].reading, "タベ");
    assert_eq!(tokens[0].pos, "動詞,一般");
    assert_eq!(
        tokens[0].inflection.as_deref(),
        Some("下一段-バ行,連用形-一般")
    );

    assert_eq!(tokens[1].dict_form, "させる");
    assert_eq!(tokens[2].dict_form, "られる");
    assert_eq!(tokens[3].dict_form, "た");
    // Auxiliary verbs all inflect too.
    assert!(tokens[1].inflection.is_some());
    assert!(tokens[2].inflection.is_some());
    assert!(tokens[3].inflection.is_some());

    // Non-inflecting-word case, from the spike's other worked example.
    let tokens2 = tokenize("こんにちは世界".to_string()).expect("tokenization should succeed");
    let world = tokens2
        .iter()
        .find(|t| t.surface == "世界")
        .expect("世界 should be a token");
    assert_eq!(world.pos, "名詞,普通名詞,一般");
    assert_eq!(world.inflection, None);
}
