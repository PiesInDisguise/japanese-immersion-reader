# R3 — Scanned-PDF/OCR Feasibility Research

Status: research spike only. Nothing in `lib/`, `test/`, or `pubspec.yaml` was touched.
A throwaway, standalone Dart demo supporting finding 3 lives at
`research/r3_ocr/isolate_progress_demo.dart` (run with
`dart run research/r3_ocr/isolate_progress_demo.dart`; no Flutter/mobile
toolchain needed). Everything else below is a written assessment — no
Android/iOS device or emulator was available in this environment
(`flutter devices` only surfaced Windows desktop + Chrome + Edge), so ONNX
Runtime and Tesseract plugin behavior on real mobile hardware is **not**
verified here and is called out explicitly wherever that matters.

Pub.dev like/download/"published X ago" figures below are a snapshot as of
this research (2026-07-22); re-check current numbers before committing, package
popularity shifts.

---

## Recommendation (short version)

Spec's stack choice (Manga OCR primary, Tesseract `jpn`/`jpn_vert` fallback) is
**feasible but not trivial**, and the two backends carry very different kinds
of risk:

- **Manga OCR / ONNX**: the hosting package situation is fine
  (`flutter_onnxruntime`). The hard part isn't Flutter — it's that Manga OCR
  is a generative vision-encoder-decoder model, not a single-pass classifier.
  A correct Dart port needs its own autoregressive decode loop, its own
  tokenizer, and its own text-postprocessing step, none of which ship as part
  of any ONNX file. Budget real implementation time here, not just "wire up a
  plugin" time.
- **Tesseract fallback**: the plugin situation is fine and the model files are
  tiny, but `jpn_vert` itself is the fragile part — it has known, documented
  accuracy bugs and strict PSM/OEM requirements. Treat it as a true fallback
  (used when Manga OCR fails/unavailable), not as a co-equal option.
- **Isolate/background-job shape**: the progress-reporting and
  cancellation mechanics are low-risk and are demonstrated working in this
  repo's throwaway spike. The genuinely open question is whether calling the
  ONNX/Tesseract *plugins* from a background isolate is safe — that is
  unverified by any package's docs and needs a real-device spike before the
  importer is built around it.

Recommended fallback order for the real importer, in priority:
**Manga OCR (ONNX) → Tesseract `jpn`+`jpn_vert` (Tesseract4Android/SwiftyTesseract) → surface a "page needs manual review" state.** Don't design the UI as if OCR always succeeds cleanly — both backends have realistic failure modes (see below), and the per-token confidence field (see final section) is what lets low-confidence output degrade gracefully instead of silently corrupting the reading experience.

---

## 1. Manga OCR on-device via ONNX

### 1.1 What the model actually is

[kha-white/manga-ocr](https://github.com/kha-white/manga-ocr) (Apache-2.0) is
a Transformers `VisionEncoderDecoderModel`: a ViT image encoder feeding a
character-level BERT-style decoder, generated autoregressively. Concretely,
from the reference Python pipeline
([`manga_ocr/ocr.py`](https://github.com/kha-white/manga-ocr/blob/master/manga_ocr/ocr.py)):

- **Preprocessing**: image → grayscale → RGB → resized to a **fixed 224×224
  square** (`ViTFeatureExtractor`, confirmed via
  [`preprocessor_config.json`](https://huggingface.co/kha-white/manga-ocr-base/blob/main/preprocessor_config.json):
  `"size": 224`, mean/std `[0.5,0.5,0.5]` — i.e. a simple `pixel/255 * 2 - 1`
  normalization, nothing exotic).
- **Decoding**: `model.generate(..., max_length=300)` — **greedy decoding, no
  beam search**, hard-capped at 300 tokens.
- **Tokenizer**: character-level, not subword/BPE — the vocab is a flat list
  of supported characters (`vocab.txt`, ~24 KB). This is good news for
  porting: a Dart reimplementation is a lookup table, not a BPE merge engine.
- **Postprocessing** (this is the part people miss): the decoded string is
  *not* the final text. The reference pipeline also does, in order: strip all
  whitespace (`"".join(text.split())`), normalize `…` → `...`, collapse runs
  of `・`/`.`-like middle-dot characters via regex, then run
  `jaconv.h2z(text, ascii=True, digit=True)` (half-width ASCII/digits → full-width).
  None of this lives in the ONNX graph — it's Python glue that has to be
  reimplemented in Dart to match reference output. The `h2z(ascii=True,
  digit=True)` part is actually simple to port faithfully (full-width forms
  are just the printable-ASCII codepoints offset by `+0xFEE0`, plus space →
  U+3000 ideographic space) — it's the regex punctuation cleanup that needs a
  careful line-for-line port to avoid subtly diverging from upstream output.
- No dedicated mobile/on-device build exists from the maintainer — an issue
  asking about ONNX export
  ([kha-white/manga-ocr#45](https://github.com/kha-white/manga-ocr/issues/45))
  confirms this is community territory, not an officially supported path, and
  the issue itself flags exactly this tokenizer/pre/post-processing coupling
  as the blocker to a clean export.

### 1.2 Available ONNX exports

No official ONNX release exists; all exports are third-party, produced via
`optimum-cli export onnx --model kha-white/manga-ocr-base --task vision2seq-lm`,
which emits a separate `encoder_model.onnx` + `decoder_model.onnx`:

| Source | Notes |
|---|---|
| [mayocream/manga-ocr-onnx](https://huggingface.co/mayocream/manga-ocr-onnx) | Direct Optimum export. |
| [l0wgear/manga-ocr-2025-onnx](https://huggingface.co/l0wgear/manga-ocr-2025-onnx) | Same lineage, more recent re-export. |
| [manga-ocr-torchless](https://github.com/liksunrice/manga-ocr-torchless) | Consumes mayocream's export; proves the split encoder/decoder ONNX pair runs standalone without PyTorch. |
| [manga-ocr-rs](https://github.com/CodeMonkeyNinja/manga-ocr-rs) | Independent Rust reimplementation on top of ONNX Runtime; **adds beam search (k=4)** on top of the original's greedy decoding — a deliberate deviation, useful precedent but not drop-in reference behavior. |

**Size**: total ONNX weights land around **~400–450 MB fp32**
(manga-ocr-rs reports encoder ≈328 MB + decoder ≈113 MB ≈ 441 MB; the
original PyTorch checkpoint is quoted at "~400 MB" in the upstream README).
**No quantized (int8/fp16) variant was found anywhere in this search.**
Producing one (e.g. ONNX Runtime's `quantize_dynamic`) is unstarted work the
importer team would have to do itself, and should validate OCR accuracy
afterward on real scanned pages — dynamic quantization of attention/LayerNorm
layers in transformer encoder-decoders is not always accuracy-neutral.

**Implication for app size**: ~450 MB is too large to bundle as a Flutter
asset in the base install. Plan to fetch it on first scanned-PDF import
(ideally gated on a "download over Wi-Fi" prompt) and cache it under the same
local, regenerable, non-synced storage spec §13 already designates for OCR
caches — losing the model file just means re-downloading it, same as losing
the OCR cache means re-running OCR.

### 1.3 Region-cropping consequence of the fixed 224×224 input

Because the encoder forces every crop into a **square** 224×224 frame
regardless of source aspect ratio, feeding it a whole page-height vertical
text column (routine for light-novel prose, less so for manga speech
bubbles, which is what this model was actually trained on) will squash it
severely on resize and likely hurt accuracy. The L1 "text-region detection"
step (spec §4) should chunk tall vertical columns into shorter,
closer-to-square sub-crops (e.g., a handful of characters' worth of column
height at a time) rather than one whole-column crop per page. This also
directly bounds the decode length per call, which helps with 1.4 below.

### 1.4 Latency reality check

No mobile-CPU benchmark for this exact model was found. The closest real
data point: **manga-ocr-rs**, a native Rust/ONNX Runtime implementation on
*desktop* Linux, reports debug-build latency of **~1.8–2.0s on clean test
crops, but 5–40s on real manga bubbles**, with the author attributing the
long tail to "decoder runaway loops on poor-quality crops" — i.e., the
autoregressive loop grinding toward the max-length cap instead of hitting an
early EOS. That's a debug build on a desktop CPU; treat it as a *floor*, not
a mobile estimate — release-mode + mobile ARM CPU could go either way
depending on quantization, but there's no evidence it'll be fast.

This is tolerable **only** because spec explicitly frames OCR as a
non-blocking background job — a few seconds per region across a 300-page
background job is fine if the UI stays responsive and progress is visible.
It is not tolerable if a single bad crop can hang a chapter indefinitely, so
the importer must enforce, independent of anything the model does
internally:
1. A hard max-decode-length cap (mirror the reference's 300, or tune lower).
2. A **wall-clock timeout per region** that abandons and flags that region
   (low confidence / "needs review") rather than trusting the model's own
   EOS behavior — manga-ocr-rs's own experience shows that behavior can't be
   trusted on messy input.

### 1.5 Flutter/Dart hosting packages

| Package | Version seen | Platforms | Health | Notes |
|---|---|---|---|---|
| **[flutter_onnxruntime](https://pub.dev/packages/flutter_onnxruntime)** | 1.8.3 | Android, iOS, Linux, macOS, Windows, web | Best of the group: verified publisher (masic.ai), published days ago at research time, 45 likes / ~9.7k weekly downloads, bundles full upstream ONNX Runtime 1.23.0. Platform-channel-based (native Kotlin/Swift/C++ wrappers), supports creating multiple independent `OrtSession`s (needed for the encoder+decoder split). | **Recommended primary.** |
| [onnxruntime_v2](https://pub.dev/packages/onnxruntime_v2) | 1.23.2+2 | Android, iOS, Linux, macOS, Windows | dart:ffi-based (direct native calls, no platform channel). Explicitly a continuation of an unmaintained original. Only 4 likes / ~53 weekly downloads at research time — low battle-testing. | Worth a look **only if** flutter_onnxruntime turns out not to be isolate-safe (see §3) — FFI calls don't need `BackgroundIsolateBinaryMessenger` the way platform-channel plugins do. Low adoption is its own risk. |
| [onnxruntime](https://pub.dev/packages/onnxruntime) (gtbluesky) | 1.4.1, ~2 years stale | — | The original that `onnxruntime_v2` forked from; stale, don't use directly. | Skip. |
| [flutter_onnxruntime_genai](https://pub.dev/packages/flutter_onnxruntime_genai) | — | — | Wraps ONNX Runtime GenAI C-API, shaped for chat-style vision-language models (e.g. Phi-3.5 Vision) with a streaming-generation API. | Wrong shape for a custom ViT+char-decoder pair — skip. |
| [onnx](https://pub.dev/packages/onnx) | — | — | Came up in search; another cross-platform Dart ONNX SDK. Not investigated in depth given `flutter_onnxruntime`'s clear lead in adoption/maintenance. | Not evaluated further. |

**Bottom line**: `flutter_onnxruntime` is the right primary choice. It gives
you raw tensor in/out via `session.run()`; **you** are responsible for
writing the autoregressive generation loop, tokenizer, and postprocessing in
Dart (see 1.1) — the package itself only solves "get ONNX Runtime into a
Flutter app," not "reproduce manga-ocr's output."

---

## 2. Tesseract `jpn`/`jpn_vert` fallback

### 2.1 Packages

| Package | Version seen | Health | Config exposed |
|---|---|---|---|
| **[tesseract_ocr](https://pub.dev/packages/tesseract_ocr)** (arrrrny/zuzu.dev) | 0.5.0 | Verified publisher, 89 likes, ~1.56k weekly downloads, published ~13 months ago at research time. Uses Tesseract4Android on Android, SwiftyTesseract + Apple Vision on iOS. | Exposes an `OCRConfig` with **language, engine mode (OEM), and page segmentation mode (PSM)** as first-class options. |
| [flutter_tesseract_ocr](https://pub.dev/packages/flutter_tesseract_ocr) | 0.4.31 | 214 likes, ~4.37k weekly downloads, published ~51 days ago — higher adoption, unverified publisher. Also on Tesseract4Android/SwiftyTesseract. | Confirmed configurable `psm` arg; OEM exposure not clearly confirmed in the docs surfaced here. |
| [flusseract](https://github.com/letterassist-ai/flusseract) | 0.1.1 | dart:ffi-based (notable architecturally — see §3), but early-stage: 47 commits, 12 stars, no tagged releases. Its own docs suggest just using ML Kit/Vision natively on mobile instead of Tesseract. | Too immature to bet the fallback path on today; worth re-checking later given the FFI angle. |

**Recommendation**: `tesseract_ocr` over `flutter_tesseract_ocr`, specifically
*because* jpn_vert requires exact OEM/PSM control (next section) and
`tesseract_ocr`'s `OCRConfig` documents both as configurable — don't pick the
package with more stars without confirming it exposes the flags you actually
need.

Both wrap **[Tesseract4Android](https://github.com/adaptech-cz/Tesseract4Android)**
(actively maintained — v4.9.0 at research time, wrapping Tesseract core
5.5.1) on Android and SwiftyTesseract on iOS, so the transitive native
dependency is healthy on Android specifically.

### 2.2 `jpn_vert` is the fragile part, not the plugins

Traineddata files are small and trivially bundleable as assets (no
download-on-demand needed, unlike the ONNX model):
[`jpn.traineddata`](https://github.com/tesseract-ocr/tessdata) and
[`jpn_vert.traineddata`](https://github.com/tesseract-ocr/tessdata/blob/main/jpn_vert.traineddata)
(2.9 MB) from the standard (`fast`) `tessdata` repo — not `tessdata_best`,
which is far larger per language and not worth it for mobile.

But `jpn_vert` itself has real, documented problems, independent of any
Flutter wrapper:
- Requires `--oem 1` (LSTM engine only) — the legacy engine doesn't support it.
- Does **not** work with the default `--psm 6`; needs `--psm 5`.
- Combining `-l jpn+jpn_vert` in one call reads vertical text horizontally
  and fails — the caller must decide orientation *before* invoking Tesseract
  and pick one language mode, not let Tesseract guess
  ([tesseract-ocr/tesseract#4128](https://github.com/tesseract-ocr/tesseract/issues/4128)).
- Known character-reuse bugs across "words" in vertical text even with LSTM
  "best" models
  ([tesseract-ocr/tesseract#1117](https://github.com/tesseract-ocr/tesseract/issues/1117)).

Practical consequence: Tesseract cannot be trusted to detect vertical vs.
horizontal orientation itself. The importer's own region-detection step
(which spec already needs for reconstructing vertical reading order in
text-layer PDFs, per §4) has to classify each region's orientation and
explicitly select `jpn` vs. `jpn_vert` + the right PSM/OEM per region — reuse
that same orientation-detection logic here rather than building a second one.
A community effort ([zodiac3539/jpn_vert](https://github.com/zodiac3539/jpn_vert))
exists specifically to retrain a more accurate `jpn_vert`, which is worth
revisiting if stock accuracy proves too poor in practice.

### 2.3 Licensing

Tesseract and its traineddata are Apache-2.0, matching Manga OCR's
Apache-2.0 — no licensing conflict between primary and fallback.

---

## 3. Background-isolate feasibility

### 3.1 What's verified here (low risk)

The pure-Dart mechanics — spawn a long-lived worker isolate, stream
fractional progress + stage back via `SendPort`/`ReceivePort`, cancel it
mid-job, and recover from a per-chapter failure without aborting the whole
document — are demonstrated working in this repo:

**`research/r3_ocr/isolate_progress_demo.dart`** (run via
`dart run research/r3_ocr/isolate_progress_demo.dart`, pure `dart:isolate` +
`dart:async`, no Flutter/package deps, verified to run in this environment).
It mirrors `ImportProgress`/`ImportStage` from `lib/l1_ingestion/importer.dart`
(redeclared locally so the spike stays standalone) and demonstrates two
scenarios: a full run where a simulated chapter throws and the job continues
past it, and a run cancelled mid-flight — in both, a simulated "UI heartbeat"
timer on the calling isolate keeps ticking on schedule throughout, showing
the caller is never blocked. Sample output from an actual run:

```
=== Scenario A: full run (progress + recoverable per-chapter error) ===
progress: [37.5%] Stage.ocr chapter 3 (recovered from error: Bad state: low-confidence page, skipped)  (ui heartbeat ticks so far: 25)
...
progress: [100.0%] Stage.done  (ui heartbeat ticks so far: 50)
UI heartbeat ticked 50 times while OCR ran in the background isolate -- the calling isolate was never blocked.

=== Scenario B: cancelled partway through ===
--- main isolate requests cancellation ---
progress: [37.5%] Stage.ocr chapter 3 (cancelled)  (ui heartbeat ticks so far: 18)
```

This part of finding 3 is de-risked: `Isolate.spawn` + ports is the right
shape for `Importer.import`'s `onProgress` callback, and per-chapter
error isolation is straightforward to build in.

### 3.2 What's NOT verified here (the real open risk)

Whether calling the **ONNX Runtime or Tesseract plugin itself** from inside
that worker isolate actually works is unverified, and none of the packages
above document it either way. This matters because of an architectural
split:

- `flutter_onnxruntime`, `tesseract_ocr`, and `flutter_tesseract_ocr` are all
  **platform-channel-based** (native wrappers invoked over `MethodChannel`).
  Per [Flutter's own isolate docs](https://docs.flutter.dev/perf/isolates),
  using platform plugins from a non-root isolate is now possible but requires
  calling `BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken)`
  inside that isolate first — and even then, it only works if the plugin's
  native implementation doesn't assume it's always invoked from the main/root
  isolate (e.g. no hidden dependence on a main-`Looper` `Handler` on Android).
  Nothing in either plugin's docs confirms this was tested by their authors.
- `onnxruntime_v2` and `flusseract` are **dart:ffi-based** — direct native
  calls that bypass the Flutter engine's binary messenger entirely, so they
  don't need `BackgroundIsolateBinaryMessenger` at all. This is a real
  structural advantage for the background-isolate use case, traded off
  against both packages' low adoption/maturity (§1.5, §2.1).
- Separately, even calling a platform-channel plugin from the **root**
  isolate doesn't guarantee UI smoothness — that depends on whether the
  plugin's native side dispatches the actual inference work to a background
  native thread and completes the channel result asynchronously, or runs it
  synchronously on the platform thread. This is plugin-implementation detail
  that isn't documented for any of the packages evaluated here.

**Recommended spike, first thing next phase, before writing the real
importer**: on an actual Android device/emulator (this research environment
had none — only Windows desktop/Chrome/Edge were available via `flutter
devices`), spawn a background isolate, call
`BackgroundIsolateBinaryMessenger.ensureInitialized`, then call
`flutter_onnxruntime`'s `session.run()` and `tesseract_ocr`'s recognize call
from inside it. Watch for exceptions and, using DevTools' timeline, confirm
frame times on the root isolate stay clean during a real inference call made
both from the root isolate and from a spawned one. If platform-channel calls
from a background isolate throw or misbehave, fall back to: call the plugin
from the root isolate but confirm (same timeline check) that its native side
backgrounds the heavy work; if *that* also janks, `onnxruntime_v2`'s FFI
approach becomes the fallback worth hardening despite its low current
adoption.

### 3.3 Recommended architecture split

Given the above, structure the importer so the isolate boundary question
matters as little as possible:

- **Pure-Dart, CPU-bound work** (image decode/resize/normalize into tensors,
  the character-level tokenizer, the postprocessing regex/normalization from
  §1.1, autoregressive loop bookkeeping) has no native escape hatch — it runs
  on whatever isolate calls it and *will* jank the UI if run on the root
  isolate. This is unambiguously worth `Isolate.spawn`-ing regardless of how
  §3.2 resolves.
- **The actual plugin calls** (`session.run()`, Tesseract recognize) are the
  part gated on §3.2's outcome — best case they can be awaited from that same
  worker isolate; worst case they need to stay on the root isolate while
  everything Dart-side is offloaded around them.
- Either way, enforce the per-region wall-clock timeout from §1.4 at the
  Dart orchestration layer, not inside the plugin — nothing here provides
  that for you.

---

## 4. Per-token OCR confidence — observation for the Token model

`lib/core/models/token.dart`'s `Token` has no confidence field, and spec §4
requires storing per-token OCR confidence. Confirmed a field is needed — but
flagging a real shape mismatch for whoever adds it:

- **Tesseract** naturally produces per-word/per-symbol confidence
  (0–100, via `TessBaseAPI` result iterators; Tesseract4Android 4.9.0 even
  added a `getConfidentText` convenience method for this). This lines up
  reasonably well with word-ish spans.
- **Manga OCR** has no equivalent native concept — it's a generative decoder
  emitting one flat string per region. The closest honest proxy is the
  softmax probability of each chosen token at each autoregressive decode
  step (already computed internally to pick that token, so capturing it is
  "free" if the Dart decode loop threads it through). But that confidence
  lands on **decoded characters within a region string**, produced *before*
  L2/Sudachi ever splits that string into `Token`s.

So whoever adds the field also has to design a small alignment step:
character/region-level OCR confidence → sliced or aggregated (e.g. min/mean
over the characters spanning a token's `surface`) → attached to each
post-Sudachi `Token`. That's a real design decision, not just "add a
`double? confidence` field" — worth scoping explicitly in whatever ticket
picks this up, and worth deciding early since it affects both OCR backends'
output shape on the way into L2.

---

## 5. Prioritized open risks / what to spike next

1. **(Blocking)** On-device isolate-safety of `flutter_onnxruntime` /
   `tesseract_ocr` per §3.2 — everything else here assumes an answer to this.
2. **(High)** Real mobile inference latency for Manga OCR — no data found
   anywhere for this specific model on ARM; the only proxy (manga-ocr-rs on
   desktop) suggests a wide, unreliable range (1.8–40s/crop) driven by
   decoder runaway on bad input. Needs measuring on a real device with real
   scanned-novel crops before committing to a UX around it.
3. **(High)** Producing and validating a quantized Manga OCR ONNX variant —
   none exists publicly; ~450 MB fp32 is not a reasonable thing to bundle or
   even download without asking, and quantization accuracy isn't guaranteed.
4. **(Medium)** Faithfully porting postprocessing (§1.1) — a line-for-line
   translation task with a clear reference
   ([`ocr.py`](https://github.com/kha-white/manga-ocr/blob/master/manga_ocr/ocr.py)),
   low-risk but easy to under-scope if treated as an afterthought.
5. **(Medium)** Region-cropping strategy for tall vertical columns (§1.3) —
   needs to reuse/extend whatever orientation-detection logic gets built for
   text-layer PDF vertical reconstruction (spec §4).
6. **(Low)** Confidence-field alignment design (§4) — not urgent for this
   phase but should be scoped before the field is added, per the actual task
   author's request not to add it in this pass.

---

## Sources

- [kha-white/manga-ocr](https://github.com/kha-white/manga-ocr) — model repo, Apache-2.0, architecture/pipeline description
- [manga_ocr/ocr.py](https://github.com/kha-white/manga-ocr/blob/master/manga_ocr/ocr.py) — reference pre/post-processing and generation call
- [kha-white/manga-ocr-base](https://huggingface.co/kha-white/manga-ocr-base) and its [preprocessor_config.json](https://huggingface.co/kha-white/manga-ocr-base/blob/main/preprocessor_config.json)
- [kha-white/manga-ocr#45](https://github.com/kha-white/manga-ocr/issues/45) — ONNX export not officially supported
- [mayocream/manga-ocr-onnx](https://huggingface.co/mayocream/manga-ocr-onnx), [l0wgear/manga-ocr-2025-onnx](https://huggingface.co/l0wgear/manga-ocr-2025-onnx)
- [manga-ocr-torchless](https://github.com/liksunrice/manga-ocr-torchless)
- [manga-ocr-rs](https://github.com/CodeMonkeyNinja/manga-ocr-rs) — desktop ONNX Runtime reimplementation, latency data point
- [flutter_onnxruntime](https://pub.dev/packages/flutter_onnxruntime) / [GitHub](https://github.com/masicai/flutter_onnxruntime)
- [onnxruntime_v2](https://pub.dev/packages/onnxruntime_v2), [onnxruntime](https://pub.dev/packages/onnxruntime) (stale original), [flutter_onnxruntime_genai](https://pub.dev/packages/flutter_onnxruntime_genai)
- [tesseract_ocr](https://pub.dev/packages/tesseract_ocr), [flutter_tesseract_ocr](https://pub.dev/packages/flutter_tesseract_ocr), [flusseract](https://github.com/letterassist-ai/flusseract)
- [Tesseract4Android](https://github.com/adaptech-cz/Tesseract4Android)
- [tesseract-ocr/tessdata jpn_vert.traineddata](https://github.com/tesseract-ocr/tessdata/blob/main/jpn_vert.traineddata)
- [tesseract-ocr/tesseract#4128](https://github.com/tesseract-ocr/tesseract/issues/4128), [#1117](https://github.com/tesseract-ocr/tesseract/issues/1117) — jpn_vert known bugs
- [zodiac3539/jpn_vert](https://github.com/zodiac3539/jpn_vert) — community jpn_vert retraining effort
- [Flutter: Concurrency and isolates](https://docs.flutter.dev/perf/isolates) — `BackgroundIsolateBinaryMessenger`, platform-plugin-in-isolate support
- [yomihon](https://github.com/yomihon/yomihon) — real-world Android manga reader with on-device OCR; uses a separate TFLite YOLO panel detector ([MODEL_ATTRIBUTION.md](https://raw.githubusercontent.com/yomihon/yomihon/main/MODEL_ATTRIBUTION.md)), no OCR-model provenance disclosed, so not usable as an OCR precedent beyond confirming on-device text extraction is shipped in production apps
