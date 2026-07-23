# R1 — EPUB Parsing Approach (Research Spike)

**Status:** Research only. No production code changed. Time-boxed spike to
de-risk the EPUB importer that a future pass will write against the frozen
`Document/Chapter/Block/Sentence/Token` schema (`lib/core/models/`).

**Proof-of-concept:** `research/r1_epub/` (throwaway Dart package, not part of
the app — see "How to run the proof" below).

---

## Recommendation

**Use `package:xml` + `package:archive` directly. Do not take a dependency on
an off-the-shelf EPUB package (`epubx`, `epub_pro`, or the original `epub`).**

Reasons, in order of weight:

1. **Ruby preservation requires hand-rolled DOM walking regardless of which
   path you pick.** Every EPUB package surveyed (see below) hands back chapter
   body content as a raw, untouched XHTML string — none of them parse or
   understand `<ruby>` markup. So the code that walks the chapter DOM to keep
   `<rb>`/`<rt>` separate from flattened text has to be written either way.
   Adding a wrapper package buys nothing for the one requirement (§4) that
   actually matters most here.
2. **A wrapper's real value-add is OPF/manifest/spine/NCX/nav parsing — and
   that's a bounded, well-specified ~150 lines**, not a deep rabbit hole. The
   proof script below implements and runs it against both an EPUB3 nav.xhtml
   and an EPUB2 toc.ncx.
3. **Dependency-pin risk.** `epubx` (latest 4.0.0, published 2023-06-30) pins
   `archive: ^3.1.6` and `xml: ^6.0.1`; the current latest majors are
   `archive: 4.0.9` and `xml: 7.0.1`. Adding epubx would force the whole app
   onto older majors of both, or create a version-solve conflict the moment
   anything else wants current `xml`/`archive`. `epub_pro` (an actively
   maintained fork, latest 5.6.0) is current on `archive` but still pins
   `xml: ^6.5.0`, one major behind. Depending on `xml`/`archive` directly
   keeps the app on latest for two very foundational, widely-used packages
   instead of inheriting a third party's older ceiling.
4. **The frozen schema's chapter/block model doesn't match an off-the-shelf
   package's object model anyway.** `epubx`'s `EpubChapter` tree is built
   from the TOC (`NavMap`/`Points`), including a `_split_` mechanism that
   silently breaks one spine file into several synthetic "chapters" when a
   file is large. Translating that into our `Chapter -> Block -> Sentence`
   shape (and generating `stableNodeId`-compatible index paths from it) is
   its own translation layer regardless of what library produced the tree —
   simpler to build the tree we actually want directly from the OPF spine.
5. **Supply-chain footprint.** `xml` (renggli/dart-xml) and `archive`
   (brendan-duncan/archive) are foundational, broadly-depended-on packages.
   The EPUB-specific wrappers are a small-team/single-maintainer niche: the
   original `epub` package (orthros/dart-epub) is dead (`sdk: >=2.0.0 <3.0.0`
   — doesn't even support Dart 3, i.e. cannot be added to this app at all),
   `epubx` is a fork of it with 56 stars / 22 open issues, `epub_pro` is a
   further fork with more recent activity. None are a bad-faith risk, but
   none are as load-bearing-proven as `xml`/`archive` either, for a piece of
   infra every single import will pass through.

**Caveat / hedge:** if OPF/NCX/nav edge cases across messy real-world EPUBs
turn out to eat more time than expected during actual implementation,
`epub_pro`'s source (MIT-licensed, actively maintained,
github.com/watate/epub_pro) is a good reference to crib from — its
`NavigationReader`-equivalent already handles both EPUB2 and EPUB3 TOC
formats. Reading it for edge cases costs nothing; depending on it costs the
version-pin and translation-layer issues above.

---

## The most important finding: a schema gap between L1 and L2

This wasn't one of the explicit questions but came up while tracing how a
`<ruby>` tag's reading actually reaches the `Token` model, and it materially
affects how the future importer must be written, so it's flagged first.

**The problem.** `sentence.dart` documents the pre-L2 contract:

> "Immediately after L1 ingestion (before Sudachi segmentation runs in L2), a
> sentence holds **exactly one placeholder Token** spanning its full text
> with null linguistic fields... This keeps the type shape identical before
> and after L2."

And `token.dart`:

> "`dictForm`/`reading`/`pos`/`inflection` are null until L2 (Sudachi)
> processes the sentence — L1 ingestion only ever populates `surface` and
> `sourceRect`."

But a real sentence routinely contains **multiple independent ruby spans**.
The proof script's own fixture demonstrates this without needing a real
novel: chapter 1's first paragraph —
`彼は<ruby>東京<rt>とうきょう</rt></ruby>に行った。そこで<ruby>友達<rt>ともだち</rt></ruby>に会った。`
— has one ruby run per sentence across its two sentences, and it is entirely
ordinary for a single light-novel sentence to carry two or three ruby-glossed
compounds at once (e.g. proper nouns + a rare kanji reading in the same
clause). A single `Token.reading : String?` field on one whole-sentence
placeholder token has nowhere to hang more than one `(base, reading)` pair.
So: **if L1 is limited to exactly one token per sentence with only `surface`
populated, author-supplied furigana has no field to live in until L2 runs —
and by the time L2 (Sudachi) runs, it generates its own dictionary reading
per token with no notion that some of those tokens already had an
authoritative, verbatim reading that must NOT be overwritten.** Left
unresolved, this silently violates spec §4 ("don't regenerate readings where
the author already provided them") the first time Sudachi integration ships.

**This is not a flaw in `xml`/`archive`** — parsing and preserving the ruby
data is the easy part (proven below). It's a data-flow gap: nothing in the
frozen `Document` tree carries a ruby association from L1 to L2.

**Two resolutions, for whoever owns the schema next:**

- **(a) Recommended — pre-split at ruby-run boundaries, no schema change.**
  L1 emits more than one token per sentence pre-L2, split at ruby-run
  boundaries rather than exactly one placeholder: e.g. for `彼は東京《とうきょう》に行った`
  emit `[Token(surface:"彼は"), Token(surface:"東京", reading:"とうきょう"), Token(surface:"に行った")]`
  — all three still have `dictForm/pos/inflection/sourceRect` null, satisfying
  every invariant `test/core/document_contract.dart` actually checks
  (non-empty tokens, null `sourceRect` for EPUB). This fits the frozen shape
  as written — `checkDocumentContract` never asserts token *count* — but
  narrows what "exactly one placeholder Token" means in practice, so it needs
  sign-off from whoever owns that comment's intent. The real cost lands on
  **L2's Sudachi-integration step**, which must reconcile Sudachi's own word
  boundaries against these pre-existing author-drawn boundaries (straightforward
  when they align, e.g. Sudachi's own segmentation may split what the ruby
  span covers into more than one morpheme — needs an explicit tie-break rule,
  e.g. "prefer the author span, attach its reading to the merged token" or
  "only keep the author reading if exactly one Sudachi token fills the span,
  else fall back to Sudachi's dictionary reading and log the mismatch").
  Whoever writes L2 needs to know this reconciliation step is coming; it
  should not be a surprise discovered mid-implementation.
- **(b) Add an explicit schema-level side channel** — e.g. a
  `List<RubyAnnotation>` (base/reading/offset) hung off `Sentence`, or a
  richer `Importer.import()` return type. Cleaner conceptually, but requires
  amending the just-frozen contract, which is outside this research task's
  authority (`lib/` is explicitly off-limits here) and outside a "Phase 1
  froze this" spike's scope to decide unilaterally.

Recommend (a) to the next owner as the lower-friction path, but this is a
decision to make explicitly, not something to let an importer-writing agent
default into ad hoc.

**Secondary, smaller schema note:** `BlockKind` has no `heading` variant
(`paragraph | page | speechBubble | subtitleLine`). A chapter's `<h1>` inside
the XHTML body has to either fold into a `paragraph` Block, or — probably
cleaner, since `Chapter.title` already exists and is populated from the
TOC/nav label — be recognized and dropped by the importer when it merely
restates the chapter title, rather than double-representing the title as
both `Chapter.title` and a Block. Worth a one-line decision when the real
importer is written; not blocking.

---

## 1. Ruby preservation: `xml`+`archive` vs. off-the-shelf EPUB packages

**`package:xml` gives full, verbatim control**, because XML parsing is
inherently tag-agnostic: `<ruby>`, `<rb>`, `<rt>`, `<rp>` are just ordinary
`XmlElement` nodes with no special treatment, so nothing "flattens" them
unless your own code chooses to call `.innerText` (which *does* flatten,
deliberately provided by the package for when you want that). The proof
script (`research/r1_epub/bin/main.dart`) walks real XHTML fixtures and
confirms, with runtime checks (not disabled `assert()`s — see note below),
all three ruby spellings actually seen in the wild:

| Form | Markup | Result |
|---|---|---|
| Explicit `<rb>` | `<ruby><rb>東京</rb><rt>とうきょう</rt></ruby>` | base=`東京`, reading=`とうきょう` |
| Bare (no `<rb>`, very common) | `<ruby>友達<rt>ともだち</rt></ruby>` | base=`友達`, reading=`ともだち` |
| `<rp>` fallback parens | `<ruby>大丈夫<rp>(</rp><rt>だいじょうぶ</rt><rp>)</rp></ruby>` | base=`大丈夫` (no parens), reading=`だいじょうぶ` (no parens) |

The `<rp>` case is the sharpest illustration of why this needs DOM-level
control: naively flattening the node to plain text (`element.innerText`)
would include the `(`/`)` fallback glyphs in the visible string, corrupting
both the base text and, if not careful about which text node is which, the
reading. Walking `rb`/`rt` as distinct child elements and explicitly
skipping `rp` avoids that. The script also proves round-tripping: parsing a
`<ruby>` element and calling `.toXmlString()` on it reproduces the original
markup exactly (`<ruby><rb>東京</rb><rt>とうきょう</rt></ruby>`) — so verbatim
storage of the raw markup, not just extraction, is available for free if
that's ever wanted (e.g. debugging, or a future "why did this word get this
reading" audit trail).

**Off-the-shelf packages were checked at the source level**, not just their
docs, since this determines whether they'd help or hinder:

- `epubx` (`ScerIO/epubx.dart`, MIT, fork of `orthros/dart-epub`) —
  `EpubChapter.HtmlContent` and `EpubTextContentFile.Content` are both plain
  `String?`. Tracing `ContentReader`/`ChapterReader` in its source: chapter
  body bytes are UTF-8 decoded into a string and handed back completely
  unparsed — epubx never even builds a DOM for chapter bodies, only for
  container/OPF/NCX/nav (where it already uses `package:xml` internally).
  So it neither preserves nor destroys ruby markup — it's simply silent on
  chapter-body content, which is 100% our own code's responsibility either
  way.
- `epub_pro` (`watate/epub_pro`, active fork of epubx) — same picture:
  `chapter.htmlContent` is a raw string. Its README highlights "improved
  extraction... to find first non-empty text content," but that's for
  auto-detecting a chapter *title* fallback, not a general HTML-to-text
  flattening of body content — it doesn't touch ruby handling either way.
- `epub` (`orthros/dart-epub`, the original both above forked from) — dead:
  latest release 2.1.0 (2019), `environment: sdk: >=2.0.0 <3.0.0`. Not
  installable in a Dart 3 project at all. Ruled out outright.
- `epub_view` / `flutter_epub_viewer` / `vocsy_epub_viewer` / `flureadium` —
  these wrap a native/webview EPUB *renderer*, not a structural parser.
  Out of scope on spec grounds alone: §4 explicitly calls for a "Custom
  XHTML renderer... DOM-level control for tap-to-lookup and author-supplied
  ruby text," which a black-box viewer widget cannot give us regardless of
  its furigana support.

**Malformed-markup fallback.** EPUB3 requires content documents to be the
XML serialization of (X)HTML, i.e. well-formed XML — `XmlDocument.parse`
is therefore the spec-correct primary parser. But "light novel" EPUBs are
frequently sideloaded from uneven sources and some have broken markup
(unclosed tags, stray unescaped `&`, etc.) that a strict XML parser will
reject. The proof script demonstrates the fallback: feed a deliberately
unclosed `<b>` tag to `xml.XmlDocument.parse` (throws `XmlTagException`,
as expected), then to `package:html`'s lenient HTML5 parser (`parse()` from
`package:html/parser.dart`), which recovers and still exposes the nested
`<ruby>`/`<rt>` for extraction. Recommend: try `package:xml` first; on
`XmlParserException`/`XmlTagException`, fall back to `package:html` for that
one file. `package:html` (dart-lang/tools, current 0.15.6) is a lightweight,
official Dart-team package — worth taking as a dependency purely as this
fallback, independent of the ruby-vs-wrapper decision above.

---

## 2. OPF + NCX/nav.xhtml → chapter list

Confirmed end-to-end in the proof script, including cross-checking that
both TOC formats agree:

1. Read `META-INF/container.xml` (fixed path, always present) → find
   `<rootfile full-path="...">` → this is the OPF path.
2. Parse the OPF (`content.opf`): `<manifest>` gives `id -> {href, media-type,
   properties}`; `<spine>` gives the ordered list of `idref`s — resolving
   spine `idref`s through the manifest map produces the linear reading
   order (this, not the TOC, is the ground truth for chapter *content*
   order).
3. Chapter *list/labels* (§5's "chapter list from the TOC") come from
   whichever TOC document the manifest points to:
   - **EPUB3**: the manifest item with `properties="nav"` → parse as XHTML →
     find `<nav epub:type="toc">` → walk `<ol><li><a href="...">Label</a></li></ol>`
     recursively for nested sub-lists.
   - **EPUB2 legacy**: manifest item with `media-type="application/x-dtbncx+xml"`
     (or the `<spine toc="...">` idref) → parse as XML → `navMap` →
     `navPoint` (recursive via nested `navPoint`s) → `navLabel/text` for the
     label, `content/@src` for the target.
4. In the proof fixture (which deliberately ships both a `nav.xhtml` and a
   `toc.ncx` describing the same two chapters), both parse paths produce
   identical `["第一章 はじまり", "第二章 おわり"]` label lists — checked
   programmatically, not just eyeballed.

Real-world caveat worth carrying into implementation: TOC entries and spine
files are not guaranteed 1:1 (a TOC entry can point to an in-page anchor
within a spine file shared by other TOC entries, or a spine file can have no
TOC entry at all). The importer will need a policy for this when it's
written (most likely: one `Chapter` per TOC entry, resolving anchors within
a spine file to a sub-range) — flagged here as a known follow-on design
point, not solved in this spike.

---

## How to run the proof

```powershell
$env:Path = "C:\src\flutter\bin;$env:Path"
cd research\r1_epub
dart pub get
dart run bin/main.dart
```

`research/r1_epub/` is a fully standalone Dart package (own `pubspec.yaml`,
`environment: sdk: ^3.12.2`, deps `archive: ^4.0.9`, `xml: ^7.0.1`,
`html: ^0.15.6`) — it does not touch the main app's `lib/`, `test/`, or
`pubspec.yaml`, and can simply be deleted once the real importer lands.
`dart analyze` is clean (no issues).

`bin/main.dart`:
- Builds a small sample EPUB **in memory** with `package:archive`
  (`mimetype`, `META-INF/container.xml`, `OEBPS/content.opf`,
  `OEBPS/nav.xhtml`, `OEBPS/toc.ncx`, two chapter XHTML files — one with the
  three ruby forms above, one plain, to confirm the no-ruby path still
  works cleanly).
- Unzips and parses it back via the exact approach recommended above.
- Prints the extracted Chapter → Block → Sentence → Run structure, showing
  base text and ruby readings side by side.
- Ends with a battery of runtime checks (`check()`, a small helper that
  unconditionally throws on failure) confirming each claim in this document.

**Note on `assert()`:** the script deliberately does *not* rely on Dart's
`assert()` for its checks. `dart run` does **not** enable asserts by
default in this SDK (3.12.2) — confirmed by a quick throwaway test during
this spike (`assert(1==2, ...)` silently did not fire under plain
`dart run`, only under `dart run --enable-asserts`). Using bare `assert()`
here would have made every "[PASS]" line print regardless of whether the
check actually held, which would have undermined the point of writing a
proof at all. All checks in the committed script use a `check()` helper
that throws unconditionally, in any run mode.

Sample output (abridged):

```
=== Step 5: walk each chapter body, preserving <ruby> verbatim ===
--- Chapter 0: 第一章 はじまり (OEBPS/chapter1.xhtml) ---
  Block[1] <p>
    Sentence[0]: 彼は東京《とうきょう》に行った。
      base text only : "彼は東京に行った。"
      ruby run       : "東京" -> "とうきょう"
    Sentence[1]: そこで友達《ともだち》に会った。
      ruby run       : "友達" -> "ともだち"
  Block[2] <p>
    Sentence[0]: 「大丈夫《だいじょうぶ》?」と彼女に聞いた。
      ruby run       : "大丈夫" -> "だいじょうぶ"

=== Step 7: round-trip a <ruby> element back to markup verbatim ===
  Re-serialized: <ruby><rb>東京</rb><rt>とうきょう</rt></ruby>

=== Step 8: package:html fallback for malformed XHTML ===
  package:xml rejects it (expected): XmlTagException
  package:html recovers it: ruby base="本" reading="ほん"

All checks passed.
```

(The `《》` notation in the printout is this script's own display
convenience — an Aozora-Bunko-style visualization for human eyes — not a
representation used in the actual data model.)

---

## Suggested module shape for the real importer (non-binding)

Not part of this spike's deliverable, just a natural seam noticed while
writing the proof, offered for whoever picks up the real implementation:

- `epub_container.dart` — container.xml/OPF/manifest/spine/NCX/nav parsing →
  ordered spine hrefs + chapter label tree. No knowledge of `Document`/etc.
- `epub_ruby.dart` — the inline-content walker (`walkInline`/`_extractRuby`
  equivalents) → produces base/reading runs from one XHTML body element.
  No knowledge of zip/OPF.
- `epub_importer.dart` — the actual `Importer` implementation: wires the
  above two together, applies the L1/L2 token-boundary decision from the
  "schema gap" section above, and calls `stableNodeId` for every
  Chapter/Block/Sentence per the existing convention in
  `lib/core/ids/stable_id.dart`.

This mirrors the split already proven out in `research/r1_epub/bin/main.dart`
(container/OPF/TOC helpers vs. the `Run`/`walkInline`/`splitIntoSentences`
helpers are already independent of each other there).
