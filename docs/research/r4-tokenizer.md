# R4 — Tokenizer Feasibility (Sudachi.rs via flutter_rust_bridge)

**Status: spike complete, working round-trip achieved.**
**Date: 2026-07-22**

This was flagged as the single highest-risk unknown in the project: there is
no ready-made Dart/Flutter binding for Sudachi, and the spec's whole L2
layer (dictionary form, reading, POS, inflection — everything in
`lib/core/models/token.dart` except `surface`) depends on it working. This
document reports what was actually *built and run*, not just read about.

## TL;DR / Recommendation

**Commit to Sudachi.rs + flutter_rust_bridge for Phase 2.** It works. A
real Rust binary compiled sudachi.rs against the small SudachiDict
dictionary, and a real Dart process called it through
flutter_rust_bridge-generated FFI bindings and got back correct
surface/dictionary-form/reading/POS data for both a simple sentence and an
inflected one, on this Windows machine, with no exotic native dependencies.

The fallback candidates (Vibrato, Lindera) turned out **not** to be
Sudachi-dictionary-compatible in practice (see §2) — if Sudachi.rs itself
had failed to compile or run, the fallback story would have been "port to a
different dictionary ecosystem," not "swap the engine and keep the data."
That makes today's positive result more load-bearing than it might
otherwise be: there isn't a cheap escape hatch if this had gone wrong.

The one thing **not** proven end-to-end is a full Flutter GUI build calling
this (Windows desktop, Android, or iOS) — this machine is missing the
Visual Studio C++ workload and the Android SDK/NDK, and iOS is categorically
unavailable from Windows. What's proven instead is the actual hard part —
Rust↔Dart FFI marshalling of strings and structs through
flutter_rust_bridge, compiled sudachi.rs, real tokenization output — via a
plain Dart CLI. See §6 for exactly what's left and why that remainder is
lower-risk, well-trodden ground.

---

## 1. Sudachi.rs + flutter_rust_bridge: what was tested

### 1.1 Rust toolchain — not previously installed, now is

Confirmed no Rust toolchain existed on this machine (`cargo`/`rustc`/`rustup`
all absent from PATH). Installed via the official method, same spirit as
the earlier Flutter SDK install:

- **What:** `rustup` 1.29.0 (the official Rust toolchain installer), via
  `winget install --id Rustlang.Rustup -e`. Publisher-verified as "The Rust
  Programming Language" (rust-lang.org); installer fetched from
  `static.rust-lang.org`, hash-verified by winget.
- **What it pulled in:** stable toolchain `1.97.1` for host triple
  `x86_64-pc-windows-msvc` (rustup's Windows default, and the right choice
  here — see below).
- **Where:** `C:\Users\sheep\.rustup` (≈1.27 GiB — toolchain, std lib) and
  `C:\Users\sheep\.cargo` (≈0.37 GiB — registry cache, git checkouts,
  installed binaries). Cargo/rustup binaries land in
  `C:\Users\sheep\.cargo\bin`, which is **not** yet on PATH in a fresh
  shell — prepend it, e.g. PowerShell:
  `$env:Path = "C:\Users\sheep\.cargo\bin;$env:Path"`.
- **Also installed (as a side effect of building flutter_rust_bridge_codegen,
  which shells out to it):** `cargo-expand` v1.0.124, via
  `cargo install cargo-expand`, landing in the same `.cargo\bin`.
- **Also installed (explicitly, the actual codegen tool):**
  `flutter_rust_bridge_codegen` v2.12.0 via `cargo install
  flutter_rust_bridge_codegen`.

**Why MSVC and not GNU:** this machine has no MinGW-w64/gcc, but it does
have a usable (if old) MSVC linker: Visual Studio 2022 Community is
installed but *without* the C++ workload, while **Visual Studio 2017
Build Tools is installed and does have the full v141 C++ toolset**
(`link.exe` 14.16) plus a Windows 10 SDK (`10.0.17763.0`). Modern rustc
auto-discovers MSVC installations the same way `vswhere` does, so it found
the 2017 Build Tools without any extra configuration and linked
successfully. This means: **the Rust side needed zero additional system
installs beyond rustup itself** — a pleasant surprise given the VS
situation initially looked like it might block everything.

### 1.2 Does sudachi.rs actually compile and tokenize correctly on Windows?

Yes, cleanly, on the first successful attempt (after fixing one ordinary
Rust borrow-checker mistake in my own spike code, not in sudachi.rs).

sudachi.rs is **not published on crates.io** (its own README lists that as
a TODO), so it must be pulled as a git dependency. Pinned to the latest
tagged release for reproducibility:

```toml
# research/r4_tokenizer/spike_rs/Cargo.toml
[dependencies]
sudachi = { git = "https://github.com/WorksApplications/sudachi.rs", tag = "v0.6.11" }
```

Its dependency tree (`aho-corasick`, `fancy-regex`, `nom`, `yada`,
`memmap2`, `csv`, `serde`, `regex`, …) is **entirely pure Rust** — no
`cc`/C-library build-script dependencies to fight with. `cargo build`
fetched and compiled the whole tree, including sudachi itself, in well
under a minute.

Verified with a plain Rust binary first (fastest possible feedback loop,
no FFI involved yet), tokenizing against the downloaded SudachiDict
**small** dictionary:

```
=== こんにちは世界 ===
surface=こんにちは      dict_form=こんにちは      reading=コンニチハ      pos=["感動詞", "一般", "*", "*", "*", "*"]
surface=世界         dict_form=世界         reading=セカイ        pos=["名詞", "普通名詞", "一般", "*", "*", "*"]

=== 食べさせられた ===
surface=食べ         dict_form=食べる        reading=タベ         pos=["動詞", "一般", "*", "*", "下一段-バ行", "連用形-一般"]
surface=させ         dict_form=させる        reading=サセ         pos=["助動詞", "*", "*", "*", "下一段-サ行", "未然形-一般"]
surface=られ         dict_form=られる        reading=ラレ         pos=["助動詞", "*", "*", "*", "助動詞-レル", "連用形-一般"]
surface=た          dict_form=た          reading=タ          pos=["助動詞", "*", "*", "*", "助動詞-タ", "終止形-一般"]
```

That second line is the *exact* example from `docs/spec.md` §8
("食べさせられた → 食べる + causative + passive + past") — Sudachi's own
inflection chain matches the product spec's assumption precisely: 食べ
(食べる, conjunctive) + させ (causative させる) + られ (passive られる) + た
(past). Mode `C` (longest/named-entity-preferring split) was used, which
is generally the right default for a reading/lookup app like this one
(Mode A/B give progressively finer splits, useful mainly for NLP research
rather than end-user dictionary lookup) — worth a deliberate revisit during
L2 implementation rather than treating this as settled.

**Integration note for whoever builds L2:** the spec's `Token.pos` and
`Token.inflection` are two separate nullable fields, but Sudachi's
`Morpheme::part_of_speech()` returns all six POS components as one
`&[String]` (e.g. `["動詞","一般","*","*","下一段-バ行","連用形-一般"]`) — for
inflecting words the last two slots *are* the conjugation type and
conjugated form (i.e. "inflection"); for non-inflecting words (nouns, etc.)
they're just `"*"`. There's no separate inflection-only accessor. The L2
mapping layer will need to split that array itself: components 0–3 → `pos`,
components 4–5 → `inflection` (when not `"*"`).

### 1.3 The actual round trip: Dart → Rust → Dart via flutter_rust_bridge

The spike crate was restructured as a library (`cdylib` + `rlib`) exposing:

```rust
// research/r4_tokenizer/spike_rs/src/api.rs
pub struct TokenInfo {
    pub surface: String,
    pub dict_form: String,
    pub reading: String,
    pub pos: String,
}

pub fn tokenize(text: String) -> Vec<TokenInfo> { /* ... */ }
```

`flutter_rust_bridge_codegen generate --rust-input crate::api` (pointed at
this crate and at a plain Dart package) generated, without hand-editing:

- Rust glue: `spike_rs/src/frb_generated.rs`
- Dart bindings: `dart_spike/lib/src/rust/{api.dart,frb_generated.dart,frb_generated.io.dart}`

The codegen correctly: converted `dict_form`/`TokenInfo` to idiomatic Dart
camelCase (`dictForm`), generated an async
`Future<List<TokenInfo>> tokenize({required String text})`, generated a
matching Dart `TokenInfo` class with `==`/`hashCode`, and silently excluded
my private (non-`pub`) helper function from the bindings, all correctly
inferred from plain Rust signatures — no annotation macros were needed for
this simple case.

**Why a plain Dart CLI and not a Flutter app:** `flutter run -d windows`
would need the Visual Studio "Desktop development with C++" workload,
which isn't installed (see §6). But the `flutter_rust_bridge` **Dart**
package (as opposed to the codegen tool) declares no Flutter SDK constraint
at all (`environment: {sdk: ">=3.4.0 <4.0.0"}` — no `flutter:` key) —
confirmed directly against its pub.dev metadata. So it's a pure Dart
package, usable from `dart pub get`/`dart run` with no Flutter engine in
the loop. That let this spike test exactly the mechanism in question (FFI
marshalling through generated bindings, calling into a compiled Rust
cdylib) without needing the pieces of the Flutter toolchain that are
missing on this machine and are a separate, better-documented concern
(mobile packaging, §6).

Running it (`dart run bin/main.dart` from `research/r4_tokenizer/dart_spike/`,
against the **release-mode** compiled `r4_tokenizer_spike.dll`):

```
=== こんにちは世界 ===
surface=こんにちは	dictForm=こんにちは	reading=コンニチハ	pos=感動詞,一般,*,*,*,*
surface=世界	dictForm=世界	reading=セカイ	pos=名詞,普通名詞,一般,*,*,*

=== 食べさせられた ===
surface=食べ	dictForm=食べる	reading=タベ	pos=動詞,一般,*,*,下一段-バ行,連用形-一般
surface=させ	dictForm=させる	reading=サセ	pos=助動詞,*,*,*,下一段-サ行,未然形-一般
surface=られ	dictForm=られる	reading=ラレ	pos=助動詞,*,*,*,助動詞-レル,連用形-一般
surface=た	dictForm=た	reading=タ	pos=助動詞,*,*,*,助動詞-タ,終止形-一般
```

Identical output to the pure-Rust binary, now produced by Dart code calling
through FFI. This is the core mechanism the whole L2 layer depends on, and
it works.

The default library-loading path flutter_rust_bridge generated
(`ioDirectory: '../spike_rs/target/release/'`, inferred automatically from
the `--rust-root`/`--dart-output` layout) just worked with zero manual
`ExternalLibrary` path configuration. A real app integration will load the
library differently (bundled as a platform-specific asset/plugin rather
than a relative path), but that's the well-documented, ordinary part of
flutter_rust_bridge's setup (`flutter_rust_bridge_codegen integrate`).

Concrete build artifacts, for scale: the compiled release cdylib
(`r4_tokenizer_spike.dll`) is **2.88 MiB**. Rust code size is not the
concern here — the dictionary is (§3).

---

## 2. Fallback assessment: Vibrato and Lindera

The brief for this spike assumed at least one of these would be
Sudachi-dictionary-compatible, as a safety net. **That assumption did not
hold up under research** — worth flagging clearly since it changes the risk
picture:

- **Lindera** (`lindera` crate, v4.0.1, MIT): ships builder crates for
  IPADIC, IPADIC NEologd, UniDic, ko-dic, and CC-CEDICT
  (`lindera-ipadic-builder`, `lindera-unidic-builder`, etc.). There is no
  Sudachi-related crate in its published crate set at all, and a GitHub
  code search for "sudachi" across the `lindera` repo returns nothing.
  It's a MeCab-dictionary-family tool, full stop.

- **Vibrato** (`vibrato` crate, Apache-2.0/MIT): its own README frames it
  as a Rust reimplementation of MeCab, and every dictionary it has ever
  published as release assets is MeCab/UniDic-family
  (`ipadic-mecab-2_7_0`, `unidic-cwj-3_1_1`, `jumandic-mecab-7_0`,
  `naist-jdic-mecab-0_6_3b`, …) — no Sudachi variant. A code search for
  "sudachi" in the repo turns up exactly two hits, both cosmetic: a code
  comment noting its lattice implementation was *inspired by* sudachi.rs,
  and a test-fixture README crediting sudachi.rs's test resources. Neither
  is dictionary compatibility.

**Practical takeaway:** if Sudachi.rs had failed here, "fall back to
Vibrato or Lindera" would really have meant *also* re-sourcing a
MeCab/UniDic/IPADIC-format dictionary and accepting different
tokenization/POS conventions than SudachiDict — a bigger swap than "same
data, different engine." Given that Sudachi.rs demonstrably works (§1),
this doesn't block anything, but it's worth the team knowing the fallback
story is weaker than assumed, in case sudachi.rs regresses or a future
platform target (e.g. web/WASM) doesn't pan out for it.

If a fallback is ever actually needed, Vibrato is the more credible of the
two for this project specifically — its Viterbi engine and lattice code
are directly descended from the same lineage as sudachi.rs (per its own
code comments) and it has the better speed profile of the two — but it
would mean shipping a UniDic-based dictionary and re-validating
POS/inflection field mapping against UniDic's tag schema instead of
SudachiDict's, and re-checking Yomitan/JMdict lookup-key compatibility
(the spec's dictionary-lookup story in §10 assumes Sudachi's dictionary-form
normalization). Not a same-day swap.

---

## 3. Dictionary size tradeoffs (mobile bundle size)

SudachiDict ships three editions (release `v20260428`, all Apache-2.0):

| Edition | Contents | Download (zip) | On-disk (uncompressed `.dic`) |
|---|---|---:|---:|
| **small** | UniDic vocabulary only | 39.8 MiB | **117.3 MiB** *(measured)* |
| **core** | + basic/common vocabulary (upstream default) | 68.9 MiB | ~203 MiB *(extrapolated)* |
| **full** | + miscellaneous proper nouns | 120.8 MiB | ~356 MiB *(extrapolated)* |

The "measured" figure is from actually downloading and extracting the small
dictionary for this spike. Core/full uncompressed sizes are extrapolated
from small's observed ~2.94x (uncompressed ÷ zip) ratio, not independently
measured — treat as ballpark, not exact.

**Implication for the app:** even the smallest edition is ~117 MiB on disk,
which is a lot to embed directly in an app bundle (Play Store/App Store
over-the-air download-size limits and general app-size hygiene both push
against it). Recommended approach for Phase 2, to decide alongside the
actual L2 implementation rather than settle here:

1. Ship **small** as the default, either as a compressed asset
   (decompressed to app-local storage on first run) or downloaded on first
   launch — sudachi.rs supports constructing a dictionary from in-memory
   bytes (`SudachiDicData`/`Storage::Owned`, seen directly in its test
   helpers), not just a file path, so "ship compressed, decompress once to
   a cache file, then mmap from there on subsequent launches" is a
   realistic path that avoids ever shipping the uncompressed 117 MiB in the
   app bundle itself.
2. Treat **core**/**full** as an optional user-triggered download
   (settings: "install expanded dictionary") rather than default-bundled,
   the same pattern the spec already uses for Yomitan/JMdict import (§10) —
   users who need obscure proper-noun coverage opt in explicitly.
3. All three editions are Apache-2.0 (small's UniDic-derived and
   NEologd-derived source data carry their own attribution notices folded
   into that same Apache-2.0 grant — confirmed by reading the dictionary's
   own `LEGAL` file), so there's no licensing blocker to bundling or
   redistributing any edition; it's purely a size/UX tradeoff.

---

## 4. What was installed on this machine (full transparency)

| What | Version | Method | Where |
|---|---|---|---|
| rustup | 1.29.0 | `winget install --id Rustlang.Rustup -e` (official, rust-lang.org-published, hash-verified) | installer only; manages the below |
| Rust toolchain | `stable-x86_64-pc-windows-msvc` (rustc/cargo 1.97.1) | installed automatically by rustup | `C:\Users\sheep\.rustup` (≈1.27 GiB) |
| Cargo registry/cache/git checkouts | — | populated by `cargo build`/`cargo install` | `C:\Users\sheep\.cargo` (≈0.37 GiB) |
| cargo-expand | 1.0.124 | `cargo install cargo-expand` (auto-triggered by flutter_rust_bridge_codegen the first time it needed it) | `C:\Users\sheep\.cargo\bin` |
| flutter_rust_bridge_codegen | 2.12.0 | `cargo install flutter_rust_bridge_codegen` | `C:\Users\sheep\.cargo\bin` |

**Nothing else system-level was installed.** In particular, no changes were
made to Visual Studio, no Android SDK/NDK, no environment variables set
persistently (PATH prepends were done per-session only, same convention as
the existing `C:\src\flutter\bin` prepend). Net disk usage across all of
the above plus build artifacts and the downloaded dictionary: roughly
2.6–2.7 GiB (free space went from ~17.4 GiB to ~14.75 GiB over the course
of this spike; the biggest single chunk of that is `spike_rs/target/`,
which is disposable build output, and the 117 MiB dictionary file, which
is `.gitignore`d — see Appendix).

---

## 5. flutter_rust_bridge itself

Latest stable: **2.12.0** (Dart pub.dev package, MIT-licensed); the CLI
`flutter_rust_bridge_codegen` at the matching version. It supports Android,
iOS, Windows, Linux, macOS, and Web as compile targets (Web via
wasm-bindgen — not evaluated here, sudachi.rs's dictionary-mmap-based
loading would need adaptation for that target and it isn't in the spec's
platform list anyway). The codegen mechanics worked smoothly for a
realistic function signature (owned `String` in, `Vec<CustomStruct>` out)
with zero hand-written FFI glue.

One friction point worth flagging for whoever does the real integration:
`flutter_rust_bridge_codegen generate` did **not** automatically add its
own Rust-side crate dependency to `Cargo.toml` (it tried, logged
`Fail to auto_upgrade... flutter_rust_bridge not found in Cargo.toml
dependencies`, and continued anyway, having still generated correct code).
That line needs adding by hand:
`flutter_rust_bridge = "=2.12.0"` (pinned to match the codegen/Dart-package
version exactly — the generated code embeds a content-hash check between
the Rust and Dart sides that a mismatched version can trip).

---

## 6. What's left for the real L2 integration (and why it's lower-risk)

This spike deliberately stopped short of a full Flutter GUI round-trip.
Concretely, on **this machine**, `flutter doctor -v` reports:

```
[!] Visual Studio - develop Windows apps (Visual Studio Community 2022 17.14.35)
    X Visual Studio is missing necessary components. Please re-run the
      Visual Studio installer for the "Desktop development with C++"
      workload...
[X] Android toolchain - develop for Android devices
    X Unable to locate Android SDK.
```

Neither was installed as part of this spike — both are heavy (the VS C++
workload alone is typically several GiB; Android Studio + SDK + NDK is
larger still and normally wants its own GUI-driven first-run setup), and
both are **standard, thoroughly-documented Flutter setup steps that have
nothing to do with the tokenizer risk** this spike existed to de-risk. iOS
is moot on this machine regardless — it categorically requires Xcode on
macOS, which no amount of installing on Windows fixes.

Remaining steps, in the order a future integration pass would likely hit
them:

1. **Add the Cargo dependency line** (`flutter_rust_bridge = "=2.12.0"` or
   current) that codegen couldn't add automatically (§5).
2. **Decide the dictionary delivery strategy** (§3) before wiring up asset
   bundling — this affects how `JapaneseDictionary` gets constructed
   (file path vs. in-memory bytes via `Storage::Owned`).
3. **Wire the L2 `Token` mapping**: split Sudachi's 6-element
   `part_of_speech()` array into the spec's separate `pos`/`inflection`
   fields (§1.2); decide whether `dictForm`/`reading` come from
   `dictionary_form()`/`reading_form()` or `normalized_form()` (Sudachi
   distinguishes "dictionary form" from "normalized form" — the spec wants
   dictionary form per §10, which is what this spike used).
4. **Real Flutter integration**: run
   `flutter_rust_bridge_codegen integrate` inside the actual app (adds the
   Rust crate as a proper sibling package, wires `pubspec.yaml`, sets up
   per-platform build hooks) rather than the manual `generate`-only
   approach used here, which was chosen specifically to avoid needing a
   full Flutter project scaffold.
5. **Desktop (Windows) build**: install the VS2022 "Desktop development
   with C++" workload (MSVC v142+, C++ CMake tools, Windows 10 SDK) to
   unblock `flutter run -d windows` — flutter_rust_bridge's dynamic-library
   loading on desktop is otherwise identical in spirit to what this spike
   already proved.
6. **Android build**: install Android Studio/SDK + NDK, add
   `cargo-ndk` (`cargo install cargo-ndk`), add the Android Rust targets
   (`rustup target add aarch64-linux-android armv7-linux-androideabi
   x86_64-linux-android` — confirmed available via `rustup target list`
   on this machine already, just not yet added), cross-compile the cdylib
   per-ABI into `android/app/src/main/jniLibs/<abi>/`. This is
   flutter_rust_bridge's most-documented path (it's the primary platform
   its own docs are written against).
7. **iOS build**: needs a Mac. `cargo build --target aarch64-apple-ios`
   + `xcodebuild -create-xcframework` (or `cargo-lipo`), matching
   flutter_rust_bridge's iOS tutorial. Nothing to do here until there's
   macOS hardware in the loop.

None of steps 4–7 are exotic — they're flutter_rust_bridge's documented,
default path, exercised by many other projects. The part that was
genuinely unknown going in — does sudachi.rs even build on this stack, and
does the FFI plumbing actually marshal Japanese text and structured data
correctly end-to-end — is what this spike answered directly, with a
running program, not just documentation reading.

---

## Appendix: spike file manifest

```
research/r4_tokenizer/
  spike_rs/                    Rust crate (cdylib + rlib + CLI bin)
    Cargo.toml                 sudachi (git, tag v0.6.11) + flutter_rust_bridge 2.12.0
    Cargo.lock                 pins exact dependency versions incl. sudachi commit 90fd6068
    src/
      lib.rs                   `mod frb_generated;` (auto) + `pub mod api;`
      api.rs                   tokenize() -- the function frb generates Dart bindings for
      main.rs                  plain-binary sanity check (no FFI), same tokenize() call
      frb_generated.rs         generated Rust FFI glue (do not hand-edit)
    resources/                 char.def, unk.def, rewrite.def (from sudachi.rs repo)
                                + SudachiDict license/legal notices
                                (system_small.dic itself is .gitignore'd -- see below)
  dart_spike/                  plain Dart package (NOT a Flutter app -- see §1.3)
    pubspec.yaml                depends on flutter_rust_bridge ^2.12.0
    bin/main.dart                the Dart-side round-trip entrypoint
    lib/src/rust/                generated Dart bindings (api.dart, frb_generated*.dart)
```

To re-run the whole spike from scratch:

```powershell
$env:Path = "C:\Users\sheep\.cargo\bin;C:\src\flutter\bin;$env:Path"

# 1. Fetch the dictionary (not checked into git -- ~118MB, Apache-2.0)
Invoke-WebRequest -Uri "https://github.com/WorksApplications/SudachiDict/releases/download/v20260428/sudachi-dictionary-20260428-small.zip" -OutFile "$env:TEMP\sudachi-small.zip"
Expand-Archive -Path "$env:TEMP\sudachi-small.zip" -DestinationPath "$env:TEMP\sudachi-small" -Force
Copy-Item "$env:TEMP\sudachi-small\*\system_small.dic" "research\r4_tokenizer\spike_rs\resources\system_small.dic"

# 2. Rust sanity check (no FFI)
cd research\r4_tokenizer\spike_rs
cargo run --bin r4_tokenizer_spike_cli

# 3. Release build (produces the cdylib the Dart side loads)
cargo build --release

# 4. Dart round trip
cd ..\dart_spike
dart pub get
dart run bin/main.dart
```

Both `char.def`/`unk.def`/`rewrite.def` and the generated
Rust/Dart glue files are already committed in this spike, so step 1 (the
dictionary itself) is the only fetch needed to reproduce it. If sudachi.rs
publishes a newer tag by the time this is revisited, re-check the pinned
`tag = "v0.6.11"` in `spike_rs/Cargo.toml` against
https://github.com/WorksApplications/sudachi.rs/tags.
