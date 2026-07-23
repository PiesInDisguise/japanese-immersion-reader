# R6 — Manga/Comic Text-Region Detection (comic-text-detector, mokuro, Manga-Text-Segmentation)

Status: research addendum to R3. R3 covered OCR *recognition* (Manga OCR,
Tesseract `jpn`/`jpn_vert`) but left "region detection" as an explicit stub
(`lib/l1_ingestion/pdf_scanned/scanned_pdf_importer.dart` currently treats
every page as one whole-page region). This doc researches three
user-suggested projects for filling that gap, plus re-checks Flutter-package
Windows support for R3's two OCR backends against what's actually buildable
in this dev environment (Windows desktop only — no Android/iOS
device/emulator available here, same constraint R3 already noted).

Pub.dev/GitHub figures below are a snapshot as of this research (2026-07-23).

---

## Recommendation (short version)

- **[comic-text-detector](https://github.com/dmMaze/comic-text-detector)
  (GPL-3.0) is a strong, concretely actionable fit** for the region-detection
  stub: it's the detector [mokuro](https://github.com/kha-white/mokuro) itself
  uses in production ahead of Manga OCR, and — the big practical win — a
  **pretrained ONNX export is directly downloadable** (no PyTorch→ONNX
  conversion work needed on our side). See §2.
- **flutter_onnxruntime supports Windows desktop** (confirmed via pub.dev,
  not assumed from R3's platform table) — meaning both this detector model
  *and* Manga OCR (R3 §1) can actually be wired up and verified for real in
  this dev environment, unlike R3's original Tesseract recommendation. See §4.
- **tesseract_ocr (R3's recommended fallback package) does NOT support
  Windows** — Android/iOS only. **flusseract does** (Windows/Linux/macOS/
  Android/iOS), at the cost of a from-source Tesseract compile (~10 min on
  first build) and a much smaller, less battle-tested package (0.1.3, 2 years
  stale). This changes R3's package recommendation for this project
  specifically, even though R3's *behavioral* findings about `jpn_vert` are
  unaffected. See §4.2.
- **Manga-Text-Segmentation (MIT) is not directly actionable** — it's the
  academic predecessor comic-text-detector's own README says it was partly
  built from, distributed as Jupyter notebooks (research code), not a
  packaged model with a ready inference path. Background/provenance only.
  See §3.
- **Licensing needs a real decision, not a default**: comic-text-detector
  (and mokuro, which glues it to Manga OCR) are GPL-3.0. This project has one
  existing GPL-3.0 precedent elsewhere (MajdataPlay, in the unrelated MaiMai
  repo), so the user is evidently not opposed to GPL-3.0 dependencies in
  general, but bundling a GPL-3.0-licensed *model* into a shipped app is a
  real distribution-license decision, not just a code-style one — flag
  explicitly before shipping, don't silently assume it's fine because of an
  unrelated prior precedent.

---

## 1. mokuro — validates the overall pipeline shape

[kha-white/mokuro](https://github.com/kha-white/mokuro) (GPL-3.0, 1677
stars, actively maintained — last updated the day before this research) is a
Python CLI: for each manga page, **detect text regions** (via
comic-text-detector) **then OCR each region** (via
[manga-ocr](https://github.com/kha-white/manga-ocr), the same model R3 §1
already researched), producing a `.mokuro` JSON file consumed by a separate
web reader for a "selectable text overlay on manga" experience — explicitly
aimed at "Japanese learners who want to read manga... with a pop-up
dictionary like Yomitan," i.e. close to this project's own stated goal.

**Why this matters for us**: it's real-world proof, not a hypothesis, that
comic-text-detector → Manga OCR is a working, maintained, popular pipeline
for exactly our use case (as opposed to us being the first to try combining
these two specific models). mokuro itself doesn't change any of R3's Manga
OCR findings — it depends on the plain PyTorch `manga-ocr` package, not an
ONNX build, so it doesn't independently validate ONNX export quality; treat
R3 §1's ONNX findings as still the operative ones for our own port.
`--disable_ocr` (generate detection-only output) and `--no_cache` (skip
mokuro's own OCR result cache) confirm the two stages are already treated as
separable in the reference implementation, which matches how this project's
own `OcrEngine` interface (already region-based, see R3 §... / current code)
and region-detection step would compose.

---

## 2. comic-text-detector — the actionable region-detection candidate

### 2.1 What it is

Training scripts + inference code (`inference.py`, `basemodel.py`) for a
combined text-detection model, built on
[manga-image-translator](https://github.com/zyddnys/manga-image-translator)'s
architecture: a shared backbone feeding **two heads** —

- a **YOLOv5** head producing text-block bounding boxes (`blk` output), and
- a **DBNet-style U-Net segmentation head** (`UnetHead`/`DBHead` in
  `basemodel.py`) producing a per-pixel text mask + the raw shrink/threshold
  probability maps DB's standard box-formation algorithm turns into line-level
  polygons (`seg`/`det` outputs).

Trained on ~13k manga/comic-style images (1/3 Manga109-s, 1/3 Digital Comic
Museum, 1/3 synthetic). Confirmed GPL-3.0 (repo license).

### 2.2 Pretrained model — ONNX already exists, no conversion needed

The repo's own `inference.py` includes a `TextDetBaseDNN` class that loads
weights via **`cv2.dnn.readNetFromONNX(model_path)`** — i.e. an ONNX export
is already a first-class, intended consumption path for this model, not
something we'd have to newly produce. Confirmed the actual pretrained file
exists: the README points to
[zyddnys/manga-image-translator's `beta-0.2.1` release](https://github.com/zyddnys/manga-image-translator/releases/tag/beta-0.2.1),
whose assets include:

| Asset | Size | Downloads (at research time) |
|---|---|---|
| `comictextdetector.pt` (PyTorch checkpoint) | 79.9 MB | 34,839 |
| **`comictextdetector.pt.onnx`** | **94.7 MB** | 2,963 |

So the ONNX file is a direct download — this project would not need to run
`utils/export.py` itself (that script exists in the repo, using
`torch.onnx.export` + `onnxsim` simplification, and is useful only as a
reference for *why* the ONNX graph is shaped the way it is, e.g. confirming
`input_names=['images']`/`output_names=['blk','seg','det']`).

### 2.3 Input/output shape (from `basemodel.py`/`inference.py`, read directly)

- **Input**: a single RGB image, **letterboxed to a square** (`inference.py`'s
  own usage: `TextDetector(model_path, input_size=1024, ...)` — 1024×1024 in
  the reference inference script; note this differs from a `640` figure that
  appears only in `export_onnx`'s YOLOv5-convention docstring/comment, which
  is not the actual pretrained model's input size), normalized `/255`, NCHW.
  `cv2.dnn.blobFromImage(im_in, scalefactor=1/255.0, size=(input_size,
  input_size))` is the exact reference preprocessing call.
- **Output**: three tensors —
  1. `blk` — YOLOv5-format raw detections (needs standard YOLO NMS to become
     final text-block boxes; `utils/yolov5_utils.non_max_suppression` is the
     reference implementation to port).
  2. `seg` — the text/mask segmentation map.
  3. `det` — DBNet's raw shrink+threshold probability maps, turned into
     polygons via `utils/db_utils.SegDetectorRepresenter` (the standard
     "Differentiable Binarization" paper's post-processing algorithm — a
     well-documented, portable, non-ML numerical algorithm, not something
     specific to this repo).
- This project's own `OcrEngine.recognize` interface
  (`lib/l1_ingestion/pdf_scanned/ocr_engine.dart`) already returns
  `List<OcrRegionResult>` — i.e. already shaped for "many regions per page" —
  so plugging in a real detector upstream of it doesn't require an interface
  change, only an implementation of whatever currently produces the
  single-whole-page-region stub.

### 2.4 Porting effort — same shape of work as Manga OCR, smaller scope

Like Manga OCR (R3 §1.1), **none of the pre/post-processing lives in the
ONNX graph** — letterboxing, YOLO NMS, and DB's box-formation algorithm are
all Python/OpenCV glue that needs a faithful Dart port, same category of work
R3 already flagged for Manga OCR's tokenizer/decode-postprocessing. Two
comparative notes worth weighing when scoping:

- This model's job (find rectangular/polygonal text regions) is
  self-contained and has no autoregressive/generative component — no analog
  to Manga OCR's "decoder runaway" latency risk (R3 §1.4). Expect more
  predictable, boundable latency: one forward pass + NMS/DB post-processing,
  not an open-ended generation loop.
- YOLO NMS and DB box-formation are both extremely well-documented, widely
  reimplemented algorithms (unlike Manga OCR's bespoke text-normalization
  regex chain) — there's a much larger body of reference ports to check
  Dart output against.

### 2.5 Licensing (flag explicitly, don't default)

comic-text-detector is **GPL-3.0**, same as mokuro. No separate/more
permissive license was found for the model weights specifically (the release
asset is hosted on a *different* GPL-3.0 repo — zyddnys/manga-image-
translator — which doesn't change the analysis). Contrast with R3's two
recognized backends, which are both Apache-2.0 (Manga OCR, Tesseract) — this
detector is the first GPL-3.0 model this project would bundle. This repo has
one existing GPL-3.0 precedent (MajdataPlay, integrated into the *separate*
MaiMai project per that repo's own git history) — worth knowing that
precedent exists, but a shipping decision for *this* app should be made
explicitly when it comes up, not inferred automatically from an unrelated
project's choice.

---

## 3. Manga-Text-Segmentation — background/provenance only, not directly actionable

[juvian/Manga-Text-Segmentation](https://github.com/juvian/Manga-Text-Segmentation)
(MIT, 142 stars) is the academic paper/dataset
(["Unconstrained Text Detection in Manga: A New Dataset and Baseline",
ECCV 2020 workshops](https://link.springer.com/chapter/10.1007%2F978-3-030-67070-2_38))
that comic-text-detector's own README credits as part of its training-data
generation ("we used ... Manga-Text-Segmentation with some post-processing to
generate masks"). Distributed as Jupyter notebooks (a ResNet34 U-Net-style
segmentation model) plus a Zenodo-hosted label-mask dataset — research
artifacts, not a packaged model with a documented pretrained-weights download
or ready inference script the way comic-text-detector has. More permissively
licensed (MIT) than comic-text-detector, but since comic-text-detector
already supersedes it for our purposes (newer, actively used by mokuro,
ONNX-ready), there's no concrete reason to integrate this one directly rather
than its more mature successor.

---

## 4. Flutter package platform support — re-checked against R3, Windows-specific

R3's package tables (§1.5, §2.1) didn't call out Windows specifically as its
own column; re-checked here since **this dev environment is Windows desktop
only** (no Android/iOS device/emulator available, matching R3's own
constraint) — platform support directly determines what can actually be
built *and verified* here, versus written blind.

### 4.1 ONNX Runtime — good news, unchanged recommendation

**[flutter_onnxruntime](https://pub.dev/packages/flutter_onnxruntime)**
(v1.8.3, checked directly on pub.dev) lists **Android, iOS, Linux, macOS,
web, Windows** — Windows desktop is fully supported. This means both Manga
OCR (R3 §1) and comic-text-detector (§2 above) — both ONNX models — can be
integrated *and tested for real* in this dev environment, unlike anything
requiring a mobile-only plugin. R3's recommendation to use this package as
primary stands, now with the added confirmation it's not mobile-only.

### 4.2 Tesseract — R3's package pick doesn't work here; a different one does

**tesseract_ocr** (R3's recommended pick, §2.1) — re-checked directly on
pub.dev: platforms listed are **Android and iOS only**. Windows is not
supported at all. This doesn't change any of R3's *behavioral* findings
about `jpn_vert` (OEM/PSM requirements, the horizontal-misread bug when
combining `jpn+jpn_vert`, etc. — those are Tesseract-the-engine facts,
package-independent) — but it does mean this specific package cannot be
built or verified in this environment.

**[flusseract](https://pub.dev/packages/flusseract)** (v0.1.3, verified
publisher letterassist.ai) — re-checked directly: supports **Android, iOS,
Linux, macOS, and Windows**. It "builds the Tesseract OCR libraries and its
dependencies from source" via CMake per-platform, with the getting-started
guide warning the *first* build takes roughly 10 minutes while it downloads
and compiles Tesseract for the target platform. R3 §2.1 already knew about
flusseract and set it aside as "too immature to bet the fallback path on" in
favor of tesseract_ocr — that tradeoff needs revisiting now that
tesseract_ocr is confirmed *unbuildable* on this machine. Not yet confirmed
whether flusseract's API exposes the same first-class OEM/PSM control
`tesseract_ocr`'s `OCRConfig` does (R3 §2.1 flagged this as the specific
reason `tesseract_ocr` was chosen over the higher-adoption
`flutter_tesseract_ocr`) — check this concretely before committing to
flusseract, since `jpn_vert` support is unusable without it (R3 §2.2).

**Practical consequence for scoping this project's own OCR phase**: Manga
OCR + comic-text-detector (both ONNX, both Windows-buildable) can be a real,
testable-here first pass. Tesseract fallback, if pursued this same pass,
either needs flusseract (slower first build, OEM/PSM support unconfirmed) or
has to be written without local verification and confirmed later on a real
Android/iOS device — worth deciding deliberately rather than discovering
mid-implementation.

---

## 5. Prioritized open risks / what to check next

1. **(High)** Confirm flusseract actually exposes OEM 1 + PSM 5 control
   before relying on it for `jpn_vert` — unconfirmed here, and R3 already
   established this exact control is non-negotiable for vertical Tesseract
   OCR to work at all.
2. **(Medium)** Port comic-text-detector's YOLO-NMS and DB
   box-formation/polygon-extraction postprocessing faithfully to Dart —
   well-documented algorithms, but still real porting work, same category as
   R3's Manga OCR postprocessing finding (R3 §1.1, §5 item 4).
3. **(Medium)** Still open from R3, unaffected by this doc's findings:
   background-isolate safety of calling ONNX Runtime from a worker isolate
   (R3 §3.2) — now relevant to *two* ONNX models (Manga OCR + this detector)
   instead of one, but the same unresolved question and the same recommended
   spike-on-a-real-device approach applies to both.
4. **(Low)** GPL-3.0 licensing decision for bundling comic-text-detector's
   model (§2.5) — not blocking for building/testing locally, but should be
   resolved before any real shipping/distribution decision.

---

## Sources

- [kha-white/mokuro](https://github.com/kha-white/mokuro) — GPL-3.0, pipeline shape, README
- [dmMaze/comic-text-detector](https://github.com/dmMaze/comic-text-detector) — GPL-3.0; `README.md`, `inference.py`, `basemodel.py`, `utils/export.py` read directly
- [zyddnys/manga-image-translator releases (beta-0.2.1)](https://github.com/zyddnys/manga-image-translator/releases/tag/beta-0.2.1) — pretrained `comictextdetector.pt.onnx` asset, confirmed present and sized directly via the GitHub API
- [juvian/Manga-Text-Segmentation](https://github.com/juvian/Manga-Text-Segmentation) — MIT; README, paper citation
- [flutter_onnxruntime on pub.dev](https://pub.dev/packages/flutter_onnxruntime) — platform list confirmed directly (Windows included)
- [tesseract_ocr on pub.dev](https://pub.dev/packages/tesseract_ocr) — platform list confirmed directly (Android/iOS only, no Windows)
- [flusseract on pub.dev](https://pub.dev/packages/flusseract) — platform list confirmed directly (Windows included), from-source CMake build noted
- `docs/research/r3-ocr.md` — this project's own prior OCR research; this doc is an addendum to it, not a replacement
