//! R4 research spike: does sudachi.rs actually compile and tokenize on this
//! machine? This is a plain binary (no FFI) so we get the fastest possible
//! feedback on the highest technical risk: does the sudachi.rs dependency
//! tree build cleanly with the MSVC toolchain on Windows. Confirmed: yes.
//!
//! Run with: cargo run --bin r4_tokenizer_spike_cli
//!
//! Expects `resources/` (relative to this crate's manifest dir) to contain:
//!   - char.def, unk.def, rewrite.def   (fetched from the sudachi.rs repo)
//!   - system_small.dic                 (fetched from SudachiDict releases)
//!
//! The actual tokenization logic lives in `src/api.rs`, which is also the
//! module `flutter_rust_bridge_codegen` generates Dart bindings for -- this
//! binary and the Dart round-trip both exercise the exact same Rust code.

use r4_tokenizer_spike::api;

fn main() {
    let sentences = ["こんにちは世界", "食べさせられた"];

    for text in sentences {
        println!("\n=== {text} ===");
        for t in api::tokenize(text.to_string()) {
            println!(
                "surface={:<10} dict_form={:<10} reading={:<10} pos={}",
                t.surface, t.dict_form, t.reading, t.pos
            );
        }
    }
}
