# Japanese Immersion Reader

A cross-platform Flutter app for learning Japanese through native media, starting with light novels (EPUB, text PDF, scanned PDF). Read → tap words/grammar to mine them into a personal collection → review with a self-contained FSRS spaced-repetition system.

Full product/engineering spec: [docs/spec.md](docs/spec.md).

## Architecture

`lib/` is organized by architecture layer, matching the spec's L1–L5 breakdown:

| Directory | Layer | Concern |
|---|---|---|
| `lib/core/` | — | Document/Chapter/Block/Sentence/Token models, Drift database, stable-ID generation — the shared contract every other layer depends on |
| `lib/l1_ingestion/` | L1 | EPUB / PDF text-layer / scanned-PDF (OCR) → normalized `Document` |
| `lib/l2_linguistics/` | L2 | Sudachi tokenization, Yomitan/JMdict dictionary import + lookup |
| `lib/l3_reader_ui/` | L3 | Document Mode, Card Mode, vertical-text rendering |
| `lib/l4_mining/` | L4 | Word/grammar collection (media-agnostic) |
| `lib/l5_srs/` | L5 | FSRS review system |
| `lib/app/` | — | App shell, routing, DI, theming |

`test/` mirrors `lib/` 1:1. `integration_test/` holds end-to-end device tests. `assets/fixtures/` holds sample EPUB/PDF files used by importer tests. `assets/dictionaries/` is gitignored — Yomitan/JMdict data is fetched at build/runtime, not checked in.

## Getting started

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates *.g.dart / *.freezed.dart
flutter test
```

Generated code (`*.g.dart`, `*.freezed.dart`) is committed. Multiple people/agents work on this codebase in parallel across independent directories; committing generated output avoids `build_runner` merge conflicts across branches. Re-run `build_runner` and commit the diff whenever you change an annotated model.

## Branch convention

Branches are named `phase<N>/<workstream>` (e.g. `phase1/core-model`, `phase1/epub-importer`) or `spike/<name>` for time-boxed research spikes, matching the phased build plan.
