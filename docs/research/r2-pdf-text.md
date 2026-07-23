# R2 — PDF Text-Layer Extraction: Character Boxes & Vertical-Text Reading Order (Research Spike)

**Status:** Research only. Nothing in `lib/`, `test/`, or `pubspec.yaml` was
touched. Time-boxed spike to de-risk the PDF-text-layer importer (`lib/l1_ingestion/pdf_text/`,
currently empty but for `.gitkeep`) that a future pass will write against the
frozen `Document/Chapter/Block/Sentence/Token`/`SourceRect` schema
(`lib/core/models/`). See spec §4 ("Ingestion") for the product requirement
this de-risks.

**Proof-of-concept:** `research/r2_pdf_text/` — a throwaway, standalone Dart
package (own `pubspec.yaml`, not part of the app; safe to delete once this
doc has been read). It generates synthetic Japanese-text PDF fixtures and
extracts text + character geometry from them via `pdfrx_engine`. See "How to
run the proof" below for exact commands and full sample output.

Pub.dev version numbers below are what actually resolved in this spike's
`pubspec.lock` as of this research (2026-07-22) — re-check before committing,
package versions shift.

---

## Recommendation

**Use `pdfrx` / `pdfrx_engine` alone. Raw pdfium FFI (`pdfium_bindings`,
hand-written ffigen bindings) is not necessary.**

- `pdfrx_engine` (the pure-Dart core that the Flutter-facing `pdfrx` package
  wraps) exposes exactly what's needed: a **per-character bounding box**
  (`PdfRect`, in PDF points) for every character on a page, grouped into
  fragments that each carry a **`PdfTextDirection`** (`ltr` / `rtl` / `vrtl` /
  `unknown`) computed from real glyph-position geometry — not from font
  metadata that might be missing or lie. This was verified hands-on against
  three generated fixtures (§5), not just read from docs.
- The one thing pdfrx's API surface does **not** give you is a guarantee that
  its linear text order matches true visual reading order for vertical
  (縦書き) columns. This spike **proved that gap exists** (§3) — but it is a
  property of how PDFium itself linearizes text (content-stream/paint order,
  not geometric order), which raw FFI access to the same PDFium build would
  face identically. Reaching past pdfrx buys nothing here; the fix has to
  live in the importer's own geometry-based reading-order reconstruction
  either way (recommended algorithm in §3.4).
- If some exotic primitive ever *is* needed that pdfrx_engine's formatter
  doesn't surface (e.g. raw `FPDFText_GetCharAngle`), it's already a zero-cost
  transitive dependency away, not a multi-week FFI-authoring project — see §4.

**Net effect on the future importer:** budget real time for the geometric
column-reconstruction algorithm (§3.4) and for mapping Sudachi token spans
onto the flat per-page `charRects` array (§3.5) — that is the actual work.
Budget near-zero time on "how do I get character boxes out of a PDF" — that
part is solved and proven working end-to-end below.

---

## 1. The API surface, and the one gotcha in reaching it

Add `pdfrx_engine: ^0.4.6` (pure Dart, no Flutter dependency — usable from a
plain `dart run` CLI, confirmed in this spike). The Flutter-facing `pdfrx`
package (pub.dev latest `2.4.7` at time of writing) is a viewer-widget layer
on top of this same engine; if the app ever wants to *render* an original PDF
page bitmap (as opposed to just extracting its text layer into the
`Document` model), that's `pdfrx` proper — an orthogonal decision from this
spike, since spec §4's text-layer requirement is satisfied by `pdfrx_engine`
alone.

Basic open/enumerate:

```dart
await pdfrxInitialize();
final document = await PdfDocument.openFile(path);
final page = document.pages[0];   // page.width / page.height in points
```

**Gotcha #1 (real, hit during this spike):** `PdfPage.loadText()` — the
method name you'd guess from the docs — only returns the flat
`PdfPageRawText { fullText, charRects }` (no fragments, no direction!). The
class that actually carries `fragments`/`direction`
(`PdfPageText`) is built by a **different, separate entry point**:

```dart
import 'package:pdfrx_engine/src/pdf_text_formatter.dart'; // NOT re-exported
              // from package:pdfrx_engine/pdfrx_engine.dart's public barrel

final PdfPageText text = await PdfTextFormatter.loadStructuredText(
  page,
  pageNumberOverride: pageIndex + 1, // required param; page's own 1-based number
);
```

This had to be found by reading pdfrx_engine's GitHub source
(`packages/pdfrx_engine/lib/src/pdf_text_formatter.dart`), not from pub.dev's
generated API docs, which describe `PdfPageText` and imply
`PdfPage.loadText()` produces it without mentioning `PdfTextFormatter` at all.
**Flag for the importer author:** as of `pdfrx_engine 0.4.6`, getting
fragments+direction requires importing an internal `src/` path, which is not
a stable public-API guarantee — pin the exact version and re-check this on
upgrade.

The full relevant type shapes (confirmed against source, `packages/pdfrx_engine/lib/src/pdf_text.dart`):

```dart
class PdfPageText {
  final int pageNumber;              // 1-based
  final String fullText;              // whole page, linear order (see §3)
  final List<PdfRect> charRects;      // 1:1 with fullText's UTF-16 code units
  final List<PdfPageTextFragment> fragments;
}

class PdfPageTextFragment {
  final PdfPageText pageText;
  final int index;                    // start offset into fullText
  final int length;
  int get end => index + length;
  String get text;                    // fullText.substring(index, end)
  final PdfRect bounds;                // fragment's overall bounding rect
  final List<PdfRect> charRects;       // this fragment's slice of char boxes
  final PdfTextDirection direction;    // ltr | rtl | vrtl | unknown
}

enum PdfTextDirection { ltr, rtl, vrtl, unknown }
// vrtl = "Vertical (top to bottom), Right to Left" -- exactly Japanese 縦書き.
// There is no separate "vertical left-to-right" value; not needed for CJK.

class PdfRect {
  final double left, top, right, bottom; // top > bottom (see §2 coordinate note)
  double get width;  double get height;
  // ...center/topLeft/topRight/bottomLeft/bottomRight helpers
}
```

---

## 2. Character-level bounding boxes: confirmed sufficient for `SourceRect` — with one open decision

Real output from this spike's horizontal fixture (`research/r2_pdf_text/fixtures/fixture_horizontal.pdf`,
420×300pt page, text `吾輩は猫である。名前はまだ無い。\nどこで生れたかとんと見当がつかぬ。`
rendered via the `pdf` package's real text-flow engine, not hand-placed):

```
--- page 0: 420.00 x 300.00 pt ---
fullText (34 chars): 吾輩は猫である。名前はまだ無い。\nどこで生れたかとんと見当がつかぬ。
charRects.length: 34
  [0] "吾" l=24.96 t=275.46 r=43.10 b=256.66 w=18.14 h=18.80
  [1] "輩" l=45.04 t=275.46 r=63.00 b=256.66 w=17.96 h=18.80
  ...
  [16] "\n" l=330.42 t=275.46 r=330.42 b=256.66 w=0.00 h=18.80
  [17] "ど" l=28.68 t=253.02 r=42.86 b=234.88 w=14.18 h=18.14
fragments: 3
  frag idx=0 len=16 ... dir=PdfTextDirection.ltr text="吾輩は猫である。名前はまだ無い。"
  frag idx=16 len=1  ... dir=PdfTextDirection.ltr text="\n"
  frag idx=17 len=17 ... dir=PdfTextDirection.ltr text="どこで生れたかとんと見当がつかぬ。"
normalized-fraction check (char 0): x/pageWidth=0.0594 y/pageHeight=0.9182
```

Every visible character gets its own precise, correctly-sized box — this is
directly usable as `SourceRect.{x,y,width,height}` with `pageWidth`/`pageHeight`
from `page.width`/`page.height` (same "points" unit, confirmed — the
`x/pageWidth`, `y/pageHeight` fractions above are exactly the normalization
`SourceRect`'s doc comment describes consumers doing).

**Two things the importer must handle, found by inspecting real output, not
assumption:**

1. **Zero-width synthesized characters.** Char `[16]` above is a `\n` I put
   in the source string, but PDFium/pdfrx also silently synthesizes
   *unrequested* filler characters with degenerate (zero-width or zero-area)
   boxes at run/line boundaries — confirmed again in §3's vertical fixtures,
   where a `\n` appears in `fullText` that nothing in the generator script
   ever placed there. `pdf_text_formatter.dart`'s own source comments confirm
   this is deliberate PDFium behavior ("PDFium inserts zero-width *generated*
   spaces to represent large gaps between text runs sharing the same
   baseline"). **The importer must filter `PdfRect.isEmpty`/zero-width boxes
   out before treating a char as a real glyph/tap target**, or an OCR-style
   consumer will end up with invisible zero-size tap targets in the token
   stream.
2. **Y-axis origin is bottom-left, not top-left — and `SourceRect`'s own doc
   comment doesn't say which convention it uses.** Confirmed both from
   `PdfRect`'s doc ("origin bottom-left... y-axis points upward... bottom is
   generally smaller than top") and empirically here: char `[0]` "吾" is the
   very first, visually-topmost character on the page, and its `y/pageHeight`
   fraction is **0.9182** — i.e. close to the *top* of the `[0,1]` range
   corresponds to a *high* raw value close to `pageHeight`, the opposite of
   Flutter's `Rect`/`Offset`/`Canvas` convention (top-left origin, y grows
   downward) and the opposite of how raster/OCR bounding boxes are
   conventionally expressed (`lib/l1_ingestion/pdf_scanned/` will get pixel
   boxes that are natively top-left-origin, y-down). `source_rect.dart`'s doc
   comment only says x/y/width/height *share a unit* with pageWidth/pageHeight
   (points vs. pixels) — it says nothing about which corner is the origin.
   **If the PDF-text importer stores PDFium's raw `top`/`bottom` un-flipped
   while the OCR importer naturally produces top-left-origin boxes, the same
   `SourceRect` struct means geometrically different things depending on
   which importer produced it** — any shared tap-target/highlight-rendering
   code in `l3_reader_ui` would then need to branch by source type, defeating
   the point of unifying on one `SourceRect` shape. **Recommendation: the
   PDF-text importer should flip at import time** (e.g.
   `sourceRect.y = pageHeight - charRect.top`, `height = charRect.height`) so
   every `SourceRect` in the system is top-left-origin/y-down, matching both
   OCR's natural convention and Flutter's own rect convention. This needs an
   explicit decision/sign-off from whoever owns the schema next (same spirit
   as R1's flagged schema gap) — it's silent in the current contract and easy
   to get backwards in a way that only shows up as vertically-flipped tap
   targets during manual QA, not a test failure.
3. **Page content is not clipped to the page's media box.** One of this
   spike's own fixture bugs (fixed in the committed version, see §5) briefly
   placed a character below `y=0`; PDFium still happily returned a valid
   `PdfRect` for it. Don't assume every `charRect` falls within
   `[0,pageWidth] x [0,pageHeight]` — malformed or edge-case source PDFs could
   have off-page content; consider defensive clamping/filtering.

---

## 3. Vertical text (縦書き): direction detection works; reading order does not come for free

This is the section that matters most for spec §4's explicit worry ("naive
extraction scrambles this").

### 3.1 How pdfrx actually decides `vrtl` vs `ltr`/`rtl`

Read from `packages/pdfrx_engine/lib/src/pdf_text_formatter.dart` on GitHub.
The core of it, `vector2direction()`, is pure geometry — it compares the
displacement vector `v` between consecutive (or first/last) character
centers:

```dart
if (v.x.abs() > v.y.abs()) {
  return v.x > 0 ? PdfTextDirection.ltr : PdfTextDirection.rtl;
} else {
  return PdfTextDirection.vrtl;
}
```

Lines are grouped by `getLineDirection()` (vector between the first and last
char centers of a run) and split further wherever consecutive char-to-char
vectors diverge by more than a ~1.5 radian (~86°) angle threshold
(`splitLine`), then chopped into whitespace-delimited "words" (`addWords`,
splitting on `\s+`) which — for Japanese, which has no inter-word spaces —
means **a fragment is line/column granularity, not word/token granularity**
(§3.5 below).

**Why this is the *right* heuristic for CJK** (worth recording so nobody
"fixes" it later by switching to angle-based detection): real vertical
Japanese typesetting keeps the great majority of glyphs upright (rotation
angle ≈ 0) — only a minority of punctuation (long vowel mark ー, small
kana, brackets) actually rotates. A per-glyph-angle signal
(`FPDFText_GetCharAngle`, which pdfrx does **not** call — confirmed by
reading `packages/pdfrx_engine/lib/src/native/pdfrx_pdfium.dart`, which only
calls `FPDFText_CountChars`/`FPDFText_GetUnicode`/`FPDFText_GetCharBox`)
would report ~0° for most vertical Japanese glyphs and therefore **fail to
distinguish vertical from horizontal text** for exactly the common case. The
position-delta approach pdfrx actually uses — "does the next character sit
below this one, or beside it" — is correct regardless of glyph rotation. This
also means going to raw FFI for `FPDFText_GetCharAngle` would be a **step
backward**, not an enhancement.

### 3.2 Confirmed working: `vrtl` detection on simulated vertical geometry

No real-world true-vertical-writing-mode PDF was available to test against
(see §5's caveat), so this spike hand-placed upright glyphs at explicit
(x, y) coordinates that reproduce vertical-column *geometry* — descending y
within a column, columns proceeding right-to-left
(`research/r2_pdf_text/fixtures/fixture_vertical_sim.pdf`, 320×520pt). Result:

```
fragments: 5
  frag idx=0  len=14 dir=PdfTextDirection.vrtl text="吾輩は猫である名前はまだ無い"
  frag idx=14 len=1  dir=PdfTextDirection.vrtl text="\n"
  frag idx=15 len=15 dir=PdfTextDirection.vrtl text="どこで生れたかとんと見当がつか"
  frag idx=30 len=1  dir=PdfTextDirection.vrtl text="\n"
  frag idx=31 len=1  dir=PdfTextDirection.unknown text="ぬ"
```

Both real columns are correctly classified `vrtl`. (The trailing lone `ぬ`
getting `unknown` is a separate, minor edge case — see §3.3.)

### 3.3 Minor observed quirk: the last character on a page can get isolated with `unknown` direction

The final character of the page's content (here, the very last glyph
painted) consistently came back as its own single-character fragment with
`direction = unknown`, even after ruling out degenerate geometry as the cause
(its y-spacing from the preceding character was the same uniform 28pt
step as every other row in the column — verified by inspecting the raw
`charRects`, not just the fragment summary). This looks like a PDFium/pdfrx
edge case specific to "last piece of text content in the page/document" (a
direction classification needs at least one neighboring vector to compare;
plausibly the very last character has no "next" to help confirm a run
continues). Root cause wasn't pursued further — out of scope for a spike —
but the **practical implication is concrete and worth carrying forward**:
`unknown`-direction fragments still carry perfectly valid, correctly-positioned
`charRects`. **The importer must not drop or ignore `unknown`-direction
fragments; it should inherit direction from the surrounding context** (the
enclosing block's or page's dominant direction, or the preceding fragment),
the same way it should treat direction generally as a hint to combine with
geometry (§3.4), not as an infallible oracle.

### 3.4 The important finding: linear order follows paint order, not visual order (proven, not assumed)

Spec §4 says naive extraction "scrambles" vertical reading order. This spike
did not just take that as received wisdom — it built a fixture to prove it.

`fixture_vertical_sim.pdf` (§3.2) painted the right column (correct
reading-first column in real 縦書き) *before* the left column in the PDF
content stream — i.e., paint order already matched visual reading order — and
got the correct `fullText` order out (`吾輩は猫である...` then `どこで生れ...`).

`research/r2_pdf_text/fixtures/fixture_vertical_scrambled.pdf` is the *exact
same visual page* (identical character positions, so a rendered/printed
page looks pixel-identical) — the **only** difference is that the generator
painted the left column first and the right column second in the content
stream. Result:

```
fullText (32 chars): どこで生れたかとんと見当がつかぬ\n吾輩は猫である名前はまだ無\nい
fragments: 5
  frag idx=0  len=16 dir=PdfTextDirection.vrtl text="どこで生れたかとんと見当がつかぬ"
  frag idx=17 len=13 dir=PdfTextDirection.vrtl text="吾輩は猫である名前はまだ無"
  ... (idx=31, "い", dir=unknown -- same trailing-char quirk as §3.3)
```

**This is the left column's text first, then the right column's text
second — backwards from correct 縦書き reading order, even though every
individual character's `direction` is correctly `vrtl` and every character's
box is in exactly the right visual position.** This directly and concretely
confirms: **PDFium's own linearization order (and therefore `fullText`,
`charRects` at the page level, and the order fragments come back in) follows
**content-stream/paint order**, not geometric/visual reading order.** A
real-world scanned-then-reflowed PDF, or a PDF produced by DTP software that
doesn't paint columns in strict right-to-left order internally, will exhibit
this same scrambling — exactly spec §4's concern, now demonstrated on
demand with a committed fixture (`assets/fixtures/synthetic_vertical_scrambled_ja.pdf`)
rather than being a theoretical risk.

**This is true regardless of pdfrx vs. raw pdfium FFI** — both sit on the
same underlying PDFium text-page linearization. There is no "use the raw C
API instead and get correct order for free" escape hatch; the reconstruction
has to happen above whichever extraction layer is used.

### 3.5 Recommended reading-order reconstruction algorithm for the real importer

Given the above, the future importer should **not** trust
`PdfPageText.fullText`/`fragments` order as final for any page/region
detected as vertical. Instead:

1. Extract all `charRects` for the page (or block/region) as usual.
2. **Detect** vertical vs. horizontal from the `direction` majority across
   fragments (falling back to a parent/page-level default for any
   `unknown`-direction fragment per §3.3).
3. For a vertical region: **cluster** `charRects` into columns by x-position
   proximity (chars in the same column share nearly-identical `left`/`right`
   — confirmed in the fixture data, e.g. every column-1 char above has
   `l=280.50` exactly). A simple greedy pass — sort candidate chars by x
   descending, start a new column whenever the x-gap from the current
   column's x exceeds roughly one char-width — is sufficient given how
   clean the column-level separation is in the data above.
4. **Sort columns** right-to-left (descending x — rightmost column read
   first).
5. **Sort characters within each column** top-to-bottom (descending PDF `y`,
   i.e. ascending reading position, given the bottom-left-origin coordinate
   system from §2).
6. Concatenate to get true reading order, independent of whatever order
   PDFium/pdfrx happened to hand characters back in.

This is an application-level geometric algorithm layered on top of char
boxes; it is the same work regardless of which library (pdfrx or raw FFI)
supplied those boxes, which is the main reason this spike does not
recommend raw FFI (§4) — it would not remove this work, only add an FFI
maintenance burden on top of it.

### 3.6 Fragments are line/column granularity, not word/token granularity

Worth flagging explicitly for whoever wires up L2: because Japanese has no
inter-word whitespace, `addWords()`'s whitespace-splitting is a no-op for
Japanese prose, so a `PdfPageTextFragment` corresponds to **one line (or
detected line-direction run)**, not one word. **Sudachi token boundaries have
no relationship to `PdfPageTextFragment` boundaries** and must be mapped
independently onto the flat `charRects` array by character index (i.e. once
L2 tokenizes `fullText`/the reconstructed reading-order string and gets a
token's start/length, look up the corresponding slice of `charRects` and
union their boxes into that `Token.sourceRect`). Since both `charRects`
indexing and (presumably) Sudachi token offsets operate on the same Dart
`String`'s UTF-16 code units, this should compose cleanly — but this spike's
fixtures never exercised a non-BMP (surrogate-pair) character (rare kanji
outside the BMU, e.g. some proper-noun kanji in Unicode CJK Extension B+),
so that alignment is asserted from Dart's indexing semantics, not verified
against a real surrogate-pair fixture. Flag for whoever wires up the L2
integration to confirm.

---

## 4. Is raw pdfium FFI ever necessary? No — and if it were, it's a zero-cost import away

`pdfrx_engine 0.4.6` pulls in `pdfium_dart 0.2.5` as a transitive dependency
(confirmed in this spike's resolved `pubspec.lock`). `pdfium_dart` is:

- **Auto-generated via `ffigen` against PDFium's full C API** — this is
  confirmed by reading `packages/pdfrx_engine/lib/src/native/pdfrx_pdfium.dart`,
  which calls straight through it (`pdfium.FPDFText_LoadPage`,
  `FPDFText_CountChars`, `FPDFText_GetUnicode`, `FPDFText_GetCharBox`, etc.) —
  i.e. it is exactly the kind of hand-written-ffigen-bindings option the task
  brief raised (`pdfium_bindings`), except it already exists, is already a
  dependency, and needs no authoring.
- **MIT licensed**, matching `pdfrx`/`pdfrx_engine`'s own MIT license.
- Fetches prebuilt PDFium binaries from the well-established
  [bblanchon/pdfium-binaries](https://github.com/bblanchon/pdfium-binaries)
  project automatically via **Dart's native-assets build hooks** — confirmed
  hands-on: every `dart run`/`dart pub get` in this spike's throwaway project
  printed `Running build hooks...` and transparently fetched/linked PDFium
  with **zero manual setup**, on Windows, in this environment. No manual DLL
  download, no CMake step, no platform-specific plumbing was needed at any
  point in this spike.

So if some future need arises that pdfrx_engine's own formatter doesn't
surface (the only candidate found in this spike is `FPDFText_GetCharAngle`,
per-glyph rotation — and §3.1 explains why that specific signal is actually
the *wrong* tool for CJK vertical-text detection, not a missing feature),
it's `import 'package:pdfium_dart/...'` away, not a new native-binding
project. **No scenario surfaced in this spike where bypassing pdfrx_engine's
high-level text API would be justified.**

---

## 5. Fixtures generated in this spike

`assets/fixtures/` started empty (`.gitkeep` only). This spike generated
three synthetic fixtures (via `research/r2_pdf_text/bin/gen_fixtures.dart`,
using the `pdf` pub.dev package — Apache-2.0 — loading the real system font
`C:\Windows\Fonts\yumin.ttf`, Yu Mincho, present on this dev machine) and
copied them into `assets/fixtures/` for a future importer's test suite to
start from:

| File | Contents | Caveats |
|---|---|---|
| `assets/fixtures/synthetic_horizontal_ja.pdf` | One page, two lines of horizontal Japanese prose (public-domain opening lines of Natsume Sōseki's *Wagahai wa Neko de Aru*, 1905), laid out via the `pdf` package's real paragraph/wrapping engine — not hand-placed. | Realistic for horizontal-prose testing. Single page, single font, no furigana/ruby, no images. |
| `assets/fixtures/synthetic_vertical_sim_ja.pdf` | Same source text, hand-placed character-by-character to reproduce vertical-column *geometry* (upright glyphs, descending y per column, columns right-to-left, correct paint order). | **Not a true PDF vertical-writing-mode page.** Real vertical CJK PDFs use a CID font with `WMode 1` / vertical glyph metrics and real shaping; authoring that needs a CJK-vertical-aware shaping engine this spike didn't have time to build (see §6 item 1 and 5). This fixture only proves pdfrx's *geometric* direction heuristic (§3.1) fires correctly on vertical-shaped geometry, not that it handles every real-world vertical PDF producer's output identically. |
| `assets/fixtures/synthetic_vertical_scrambled_ja.pdf` | Pixel-identical page to the one above, but the two columns are painted in reverse (left-then-right) content-stream order. | Purpose-built regression fixture proving §3.4's finding. Recommended as a permanent test case: assert that the real importer's reading-order reconstruction produces the *same* correct token sequence from this file as from `synthetic_vertical_sim_ja.pdf`, despite their different internal paint order. |

**What real-world fixtures are still needed** (explicitly out of reach of a
synthetic-generation approach in the time available, flagged per this task's
own instructions for a later step to supply):

- A real vertical-writing-mode PDF produced by actual Japanese DTP/typesetting
  software (e.g. a light novel or Aozora-Bunko-derived PDF with true `WMode 1`
  CID vertical fonts) — needed to confirm §3's reconstruction algorithm and
  the `vrtl` detection heuristic hold on genuine vertical font shaping and
  real inter-column furigana/ruby annotations, not just simulated geometry.
- A real multi-chapter light-novel-scale PDF (dozens+ pages) — needed for
  performance/scale testing of per-page `loadStructuredText()` calls and for
  realistic chapter/page-break-to-`Block`-boundary mapping, which a
  single-page synthetic fixture can't exercise.
- A rotated-page PDF (`/Rotate` 90/180/270) — this spike did not test whether
  `page.width`/`page.height`/`charRects` already account for page rotation;
  flagged as untested in §6.
- (Separately, out of this importer's scope: scanned/image-only PDFs belong
  to `lib/l1_ingestion/pdf_scanned/`'s OCR pipeline, covered by R3, not here.)

---

## 6. Prioritized open risks / what to verify next

1. **(High)** Validate §3.4's reconstruction algorithm against a *real*
   vertical-writing-mode PDF, not just this spike's simulated geometry —
   real CID vertical fonts, furigana/ruby side-columns (which sit
   geometrically adjacent to a main column and must not be mis-clustered
   into it), and mixed horizontal+vertical content on one page (e.g. a
   horizontal chapter heading above vertical body text) are all unverified
   here.
2. **(Medium)** Rotated pages (`/Rotate`) — untested; confirm
   `page.width`/`height` and `charRects` already account for rotation before
   the importer trusts them raw, or compensate explicitly.
3. **(Medium)** The y-axis-origin flip decision (§2, point 2) needs explicit
   sign-off from whoever owns the `SourceRect` contract before the importer
   ships — silent/undecided today, and easy to get backwards in a way that
   only surfaces as vertically-flipped tap targets during manual QA rather
   than a failing test.
4. **(Low)** Surrogate-pair (non-BMP) character alignment between
   `charRects` indexing and L2/Sudachi token offsets (§3.5) — reasoned
   through from Dart's UTF-16 string semantics, not tested against a fixture
   containing one.
5. **(Low)** Real vertical Japanese typesetting selectively rotates some
   punctuation (long vowel mark ー, small kana, brackets); this spike's
   simulated vertical fixture kept every glyph upright. Once a real vertical
   fixture (§5) is available, worth a quick check that rotated-punctuation
   characters don't confuse the column-clustering algorithm (their bounding
   boxes will have a different aspect ratio than surrounding upright glyphs).
6. **(Low)** `pdfrx_engine`'s fragment/direction entry point
   (`PdfTextFormatter.loadStructuredText`) is reached through an internal
   `src/` import (§1) — re-verify this on any version upgrade, since it's not
   a guaranteed-stable public API path as of `0.4.6`.

---

## How to run the proof

```powershell
$env:Path = "C:\src\flutter\bin;$env:Path"
cd research\r2_pdf_text
dart pub get
dart run bin/gen_fixtures.dart              # writes fixtures/*.pdf
dart run bin/extract.dart fixtures/fixture_horizontal.pdf
dart run bin/extract.dart fixtures/fixture_vertical_sim.pdf
dart run bin/extract.dart fixtures/fixture_vertical_scrambled.pdf
```

`research/r2_pdf_text/` is a fully standalone Dart package (own
`pubspec.yaml`, `environment: sdk: ^3.12.2`, deps `pdfrx_engine: ^0.4.6` for
extraction and `pdf: ^3.13.0` purely to *generate* the synthetic fixtures) —
it does not touch the main app's `lib/`, `test/`, or `pubspec.yaml`, and can
be deleted once this doc has been read; the fixtures it produced are also
committed under `assets/fixtures/` (see §5) so deleting it loses no
reusable artifact.

- `bin/gen_fixtures.dart` — loads `C:\Windows\Fonts\yumin.ttf` (Yu Mincho,
  present on this dev machine), then writes the three fixtures described in
  §5. Uses the `pdf` package's high-level widget API (`pw.Text`, real
  paragraph flow) for the horizontal fixture, and its low-level
  `PdfGraphics.drawString` canvas API (via `pw.CustomPaint`) for
  character-by-character placement in the vertical fixtures. **Gotcha hit
  while writing this:** `PdfGraphics.drawString()` wants a
  `package:pdf/pdf.dart` `PdfFont`, not the widget-layer `pw.Font` that
  `pw.Font.ttf()` returns — construct a `PdfTtfFont(doc.document, fontBytes)`
  directly from the raw font bytes instead of trying to extract one from the
  `pw.Font` wrapper.
- `bin/extract.dart` — opens a PDF path (first CLI arg, default
  `fixtures/fixture_horizontal.pdf`), calls
  `PdfTextFormatter.loadStructuredText()` per page, and dumps `fullText`,
  the first 20 `charRects`, every fragment (with direction and bounds), and
  a `SourceRect`-style normalized-fraction sanity check.

Full sample output for all three fixtures is quoted inline in §2 and §3
above (not abridged — these are complete `charRects`/`fragments` dumps
except where truncated with `...` for brevity, which is noted each time).

`dart analyze` was not run against this throwaway project (no
`analysis_options.yaml` was added); it was validated purely by successful
compilation and manual inspection of output, which was sufficient for a
research spike's purposes.

---

## Sources

- [pdfrx on pub.dev](https://pub.dev/packages/pdfrx) — Flutter-facing viewer package, MIT, latest `2.4.7`
- [pdfrx_engine on pub.dev](https://pub.dev/packages/pdfrx_engine) — pure-Dart core, MIT, `0.4.6` used here
- [pdfium_dart on pub.dev](https://pub.dev/packages/pdfium_dart) — ffigen'd raw PDFium bindings, MIT, `0.2.5` (transitive dep)
- [pdf on pub.dev](https://pub.dev/packages/pdf) — Apache-2.0, `3.13.0`, used only to generate fixtures
- [espresso3389/pdfrx on GitHub](https://github.com/espresso3389/pdfrx) — monorepo source
  - [`packages/pdfrx_engine/lib/src/pdf_text.dart`](https://github.com/espresso3389/pdfrx/blob/master/packages/pdfrx_engine/lib/src/pdf_text.dart) — `PdfPageText`/`PdfPageTextFragment`/`PdfTextDirection` definitions
  - [`packages/pdfrx_engine/lib/src/pdf_text_formatter.dart`](https://github.com/espresso3389/pdfrx/blob/master/packages/pdfrx_engine/lib/src/pdf_text_formatter.dart) — `vector2direction()`, line/word grouping, `loadStructuredText()`
  - [`packages/pdfrx_engine/lib/src/native/pdfrx_pdfium.dart`](https://github.com/espresso3389/pdfrx/blob/master/packages/pdfrx_engine/lib/src/native/pdfrx_pdfium.dart) — raw `FPDFText_*` calls confirming no `FPDFText_GetCharAngle` usage
  - [pdfrx README](https://github.com/espresso3389/pdfrx/blob/master/README.md), [pdfrx_engine README](https://github.com/espresso3389/pdfrx/blob/master/packages/pdfrx_engine/README.md)
  - [Issue #516 — text selection/copy](https://github.com/espresso3389/pdfrx/issues/516) (checked; no maintainer commentary on text-extraction reliability found)
- [bblanchon/pdfium-binaries](https://github.com/bblanchon/pdfium-binaries) — prebuilt PDFium binaries `pdfium_dart` fetches automatically
