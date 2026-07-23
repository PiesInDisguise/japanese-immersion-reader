//! Verifies `tokenize` returns a proper `Result::Err` (not a panic) when
//! called before `init_tokenizer` -- replacing the R4 spike's `.expect()`
//! panics with catchable errors is one of the two production gaps this
//! crate fixes versus the spike (see docs/research/r4-tokenizer.md and
//! src/api.rs's module doc comment).
//!
//! This lives in its own `tests/*.rs` integration-test binary (rather than
//! a `#[cfg(test)]` unit test inside src/api.rs) specifically so it gets a
//! fresh process and therefore a fresh, never-yet-initialized copy of the
//! crate's process-wide `OnceLock` tokenizer. Unit tests in the library's
//! own test binary all share one process/statics and would make this
//! assertion order-dependent -- worse, it would pass or fail based on
//! whether a dictionary-backed test happened to run first in that same
//! binary. The dictionary-backed "after init" path is covered separately in
//! dictionary_integration.rs, itself a distinct process for the same
//! reason.

use sudachi_tokenizer::api::{tokenize, TokenizerError};

#[test]
fn tokenize_before_init_is_a_catchable_error_not_a_panic() {
    let result = tokenize("こんにちは".to_string());
    assert!(
        matches!(result, Err(TokenizerError::NotInitialized)),
        "expected Err(NotInitialized), got {result:?}"
    );
}
