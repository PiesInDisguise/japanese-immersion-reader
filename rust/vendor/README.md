# vendor/sudachi.rs

A local copy of the `sudachi.rs` v0.6.11 git checkout (same commit
`Cargo.toml`'s `[dependencies] sudachi` pins via `tag = "v0.6.11"`), patched
in exactly two places, both real upstream bugs surfaced only by
cross-compiling for Android (this crate was presumably never built for a
mobile/32-bit target before):

1. `sudachi/src/plugin/loader.rs`'s `make_system_specific_name` is
   `#[cfg]`-gated per OS for DSO-plugin naming, and upstream's
   `cfg(any(target_os = "linux", target_os = "freebsd"))` arm doesn't
   include `target_os = "android"` -- Rust treats "android" as a distinct
   `target_os` from "linux" even though the `.so` naming convention is
   identical, so the crate fails to compile for any Android target at all
   without this. Added `target_os = "android"` to that one `cfg` arm.
2. `sudachi/src/util/fxhash.rs`'s adapted-from-`fxhash` `SEED: usize`
   constant only has a `cfg(target_pointer_width = "64")` arm -- the
   original `fxhash` crate this was vendored from has a 32-bit arm too, but
   it was dropped, so the crate fails to compile for any 32-bit target
   (e.g. `armv7-linux-androideabi`) at all. Added the missing
   `cfg(target_pointer_width = "32")` arm back, using the same `SEED32`
   this file already defines.

Nothing else changed.

Wired in via `[patch]` in `rust/Cargo.toml`, unconditionally (not only for
Android targets) -- the patch is a strict superset of upstream's behavior
for every other OS, so there's no reason to keep the two sources in sync
conditionally.

Re-vendor if bumping the pinned `sudachi` tag: re-copy the new checkout from
`~/.cargo/git/checkouts/sudachi.rs-*/`, reapply this same one-line `cfg` fix,
and check whether upstream has picked it up already (in which case this
whole directory + the `[patch]` section can be deleted).
