# Japanese Immersion Reader — Product & Engineering Spec

*A cross-platform app for learning Japanese through native media, starting with light novels.*

---

## 1. Concept

A reading application that turns native Japanese media into a study loop. You read; tapping words and grammar mines them into a personal collection; that collection feeds a self-contained SRS review system.

V1 ships **light novels** in EPUB and PDF (including scanned PDF). The engine is deliberately built so the same reading, mining, and review layers later serve **manga and video subtitles** without a rewrite.

**Guiding principles**

- **Offline-first.** Everything core works with no network. Network access is strictly additive — when it's there, extra features light up; when it's not, nothing breaks.
- **Local-only.** No accounts, no required cloud. Pure local storage, with optional sync bolted on later.
- **Source-agnostic core.** Every media type collapses into one normalized document model above the ingestion layer, so nothing downstream cares whether text came from an EPUB, a scan, or (eventually) a subtitle track.

---

## 2. Recommended Stack

| Concern | Choice | Why |
|---|---|---|
| App shell | **Flutter** | One codebase across iOS, Android, and desktop; native-quality gesture performance for the swipe-card mode; mature CJK and vertical-text rendering. |
| Local database | **SQLite** (via Drift) with FTS5 | Dictionary lookup needs fast indexed search; FTS5 delivers it. Single-file DB syncs cleanly later. |
| Tokenizer | **Sudachi** | Handles light-novel prose better than MeCab/IPADIC; supports multiple split granularities and gives dictionary forms directly. Runs via FFI or bundled native lib. |
| EPUB | Custom XHTML renderer | Needs DOM-level control for tap-to-lookup and author-supplied ruby text. |
| PDF text layer | pdfium-based extraction | Per-glyph bounding boxes required for tap targets and for reconstructing vertical reading order. |
| OCR (scans) | **Manga OCR** primary, Tesseract `jpn`/`jpn_vert` fallback | Manga OCR generalizes to vertical scans and is the same model needed for the manga phase later. |
| Grammar | Rule-matched patterns + optional LLM explanation | See §8. |
| Audio | On-device TTS + downloadable pitch-accent data | Optional, off by default. See §9. |
| LLM | User's own API key (BYO) | Single-user for now; no hosted proxy needed. |
| Sync | Deferred; local-first schema prepared for it | See §13. |

---

## 3. Architecture Overview

```
┌──────────────────────────────────────────────┐
│  L1  Ingestion                               │
│      EPUB · PDF text layer · OCR             │
│      → normalized Document model             │
├──────────────────────────────────────────────┤
│  L2  Linguistic Processing                   │
│      Segmentation · Tokenization (Sudachi)   │
│      Dictionary lookup · Furigana · Grammar  │
├──────────────────────────────────────────────┤
│  L3  Reading UI                              │
│      Mode A: Card Mode · Mode B: Doc Mode    │
├──────────────────────────────────────────────┤
│  L4  Collection  (media-agnostic)            │
│      Word dictionary · Grammar dictionary    │
├──────────────────────────────────────────────┤
│  L5  SRS  (self-contained, FSRS)             │
└──────────────────────────────────────────────┘
```

**The load-bearing design decision:** L1 emits a single normalized `Document` structure regardless of source. Everything above L1 is format-blind.

```
Document
 └── Chapter[]
      └── Block[]           (paragraph · page · speech bubble · subtitle line)
           └── Sentence[]
                └── Token[] { surface, dictForm, reading, pos, inflection, sourceRect? }
```

- `sourceRect` is **null** for reflowable EPUB and **populated** for PDF/OCR, where tap targets map to pixel regions on the page.
- `Sentence` carries a stable ID. This is what lets the two reading modes share a position: a card index and a document scroll offset both resolve to the same `Sentence`, so switching modes keeps your place.

---

## 4. Ingestion (L1)

**EPUB**
Parse OPF/NCX for the table of contents; render XHTML. Preserve author-supplied ruby (furigana) — don't regenerate readings where the author already provided them.

**Text-layer PDF**
Extract text runs with bounding boxes. Detect writing direction from glyph advance. For vertical text (縦書き), reconstruct reading order as right-to-left columns — naive extraction scrambles this.

**Scanned PDF**
Page → text-region detection → OCR per region → normalized output. OCR runs as a **background job on import**, cached to disk, with per-chapter progress shown. A 300-page novel must never block the UI. Store OCR confidence per token so low-confidence text can be handled gracefully downstream.

**Vertical text**
Must render correctly in Document Mode. Flutter needs a custom vertical-text layout widget (equivalent to `writing-mode: vertical-rl`). This is non-trivial and affects tap-target geometry, so it should be prototyped early even if built later.

---

## 5. Library & Navigation

- **Library view** — imported works with cover art, progress %, and a media-type filter (ready for manga/video later).
- **Book view** — chapter list from the TOC.
- **Reading position** — persisted per work; mode switches preserve position via the shared `Sentence` ID.
- **Mode toggle** — available anytime from the reader toolbar.

**Book sources**

- **Sideload** from device files (primary).
- **Remote sources** via a pluggable provider interface, so a personal media server (WebDAV, OPDS, or a custom endpoint) can list and pull books. Designed as an interface from day one so new source types drop in without touching the reader.

---

## 6. Mode A — Card Mode

A vertical-feed reading experience: one sentence per card, swipe through the text.

**Segmentation**
One sentence per card. Sentences longer than a configurable character threshold split at major clause boundaries — 、, て-form breaks, conjunctive particles (が・けど・ので・から), and quotative と. Sudachi's analysis makes these splits linguistically sensible rather than arbitrary.

**Gestures**

| Action | Result |
|---|---|
| Swipe up | Next card |
| Swipe down | Previous card |
| Tap empty card space | Flip card → grammar breakdown |
| Tap a word | Definition + reading popup |
| Drag across characters | Override tokenizer boundary, look up the selected span |
| Tap a grammar point (flip side) | Grammar detail popup |

**Mining behavior (setting-dependent)**

- **Auto-add ON** — tapping a word adds it to the word dictionary. Tapping an already-collected word **resets its SRS state to "new"** (you forgot it). Because this mode has no explicit remove button, accidental adds are recoverable two ways: an **undo toast** immediately after, and **long-press to remove** anytime.
- **Auto-add OFF** — each card shows a **+** button. Tap → added, becomes **−**. Tap **−** → removed.

The **grammar side behaves identically** against the grammar dictionary.

**Text appearance**
Plain text by default — no underlines, tints, or color-coding on collected/known words. (The data to support such marking exists; it's simply off by default and could become an optional setting later.)

---

## 7. Mode B — Document Mode

A standard reader (paginated or scrolling; vertical-text aware) with the same interaction layer overlaid.

| Action | Result |
|---|---|
| Single tap on word | Definition + reading popup (same mining rules as Card Mode) |
| Drag across characters | Override tokenizer boundary |
| Double tap | Grammar breakdown of the containing sentence, shown as a popup (not a flip) |

All mining rules, undo behavior, and settings carry over unchanged from Card Mode.

---

## 8. Grammar Breakdown

Rendered on the card's flip side (Mode A) and in the double-tap popup (Mode B). Three layers, composed together:

1. **Token gloss** *(offline, instant)* — surface form, dictionary form, reading, part of speech, and full inflection chain. Example: 食べさせられた → 食べる + causative + passive + past. Straight from Sudachi.

2. **Matched grammar points** *(offline, instant)* — patterns matched against a curated database shaped like DoJG/Bunpro entries: `{ id, pattern, matcher, jlptLevel, explanation, examples }`. Each matched point is tappable and mines into the grammar dictionary.

3. **LLM natural-language explanation** *(network, optional)* — one call per sentence, **cached permanently by sentence hash** so it's paid for once. Sees the **sentence plus a few surrounding lines** as context, to resolve nuance and ambiguous parses. Streams in beneath layers 1 and 2, which are already fully usable without it.

**Tokenizer boundary handling**
Default behavior trusts Sudachi's segmentation silently — no confidence flags cluttering the text. When a boundary is wrong, dragging across the intended characters looks up that span instead. The fix is present when needed and invisible otherwise.

**Content note**
The grammar-point database is the largest content-authoring task in the project. Realistic path: build incrementally from the ~200 most common N5–N3 patterns, with a schema that allows adding points as data (no code changes). LLM-generating a first pass for hand-correction is a reasonable accelerator.

---

## 9. Audio *(optional, off by default)*

- **TTS** for words and full sentences, on-device where the platform supports it.
- **Pitch-accent audio** via downloadable data, network only for the initial download.

Both are opt-in and fully skippable — the app is complete without them.

---

## 10. Dictionaries

- **Import both** Yomitan/Yomichan ZIP format and raw JMdict (XML/JSON).
- **Yomitan support is the strategic anchor** — one importer unlocks a large ecosystem: JMdict, JMnedict, monolingual dictionaries (新明解 etc.), pitch-accent dictionaries, and frequency lists.
- **Multiple dictionaries** installed simultaneously with user-ordered priority.
- Lookup keys on the **dictionary form** from Sudachi, with fallback to surface form and a deconjugation retry.
- Frequency dictionaries, when present, can surface a word's commonality in the popup.

**Word definition popup — configurable fields**

Shown by default: **word, reading, meaning.**

Optional (toggled in settings): **example sentences, pitch accent, conjugation table.** (Other installed dictionaries' entries and frequency rank are available to add as further optional fields.)

---

## 11. Collection Layer (L4)

Collection entries are **media-agnostic** so the same word mined from a novel today and a subtitle later is one entry with two sightings.

```
CollectedWord
  id, dictForm, reading, senseIds[]
  addedAt
  sourceRefs[] → { workId, sentenceId, mediaType }
  srsState { interval, ease, due, lapses, status }

CollectedGrammar
  id, grammarPointId
  addedAt
  sourceRefs[] → { workId, sentenceId, mediaType }
  srsState { interval, ease, due, lapses, status }
```

Carrying `mediaType` in `sourceRefs` from the start is what lets a review card later say "first seen in Chapter 3 of X" or "in episode 4's subtitles" with no schema migration.

---

## 12. SRS Review System (L5) — *self-contained*

- **No Anki dependency**, no export requirement — fully self-contained.
- **Algorithm: FSRS** (better retention per review than SM-2; reference implementations exist to port).
- Cards generate from collection entries, with the **original source sentence built in as context**.
- **Default card type: recognition (JP → meaning).** Switchable per deck in deck settings to production, cloze from the source sentence, or audio/listening.

---

## 13. Storage & Sync

- **Local-first SQLite.** Pure local, no account.
- **Sync-ready schema:** every mutable row carries a stable UUID and `updatedAt`, so an optional cloud-sync layer (last-write-wins or CRDT) can be added later without reworking the data model.
- Dictionaries and OCR caches stay **local-only** (large, regenerable, not worth syncing).

---

## 14. Settings Summary

**Reader appearance** — light/dark, adjustable font size, font family, background/paper color, reading width & margins, furigana toggle (on/off).

**Mining** — auto-add on/off (words and grammar independently).

**Definition popup fields** — word/reading/meaning (default on); example sentences, pitch accent, conjugation table (optional).

**Audio** — TTS on/off, pitch-accent audio on/off.

**Dictionaries** — installed list with priority ordering; import (Yomitan / JMdict).

**LLM** — API key entry; grammar-explanation on/off.

**Decks (per deck)** — card type (recognition default), FSRS parameters.

**UI language** — English.

---

## 15. Progress & Stats

- Reading **streak / heatmap**
- **Words-mined** count
- **Comprehension %** per page (share of words already known/collected)
- **Time read**

---

## 16. Suggested Build Order

1. EPUB parse → normalized `Document` → plain reader
2. Sudachi integration + Yomitan dictionary import + tap-to-define
3. Collection layer (word dictionary; add/remove/undo states)
4. Card Mode with swipe gestures
5. Token-gloss grammar side
6. PDF text layer + vertical-text rendering
7. OCR pipeline for scans
8. Grammar-point database + matching
9. LLM explanation layer (BYO key)
10. FSRS review system
11. Audio (TTS + pitch accent)
12. Remote book sources · stats · optional sync

Steps 1–4 are a genuinely usable app on their own. **Vertical text (6)** and **OCR (7)** are the two places where scope can quietly triple — spike both early even if you build them late.

---

## 17. Scope Boundaries

**In V1:** light novels (EPUB, text PDF, scanned PDF); both reading modes; word + grammar mining; dictionary import; self-contained FSRS SRS; BYO-key LLM grammar; local-only storage.

**Explicitly deferred:** manga and video-subtitle sources (engine designed for them; not built); cloud sync; audio; remote book providers; hosted LLM.

**Non-goals:** Anki integration; accounts; always-online features.
