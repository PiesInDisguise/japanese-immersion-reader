import 'dart:math' as math;

import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/core/util/sentence_splitter.dart';

import 'epub_ruby.dart';

/// Splits one block's inline [Run]s into per-sentence token lists, using the
/// shared L1 sentence splitter run against the block's *flattened* plain
/// text (see [plainTextOf]) so boundaries are found in the text a reader
/// actually sees, not a string with furigana mixed in.
///
/// Within one sentence, consecutive plain-text runs are merged into a single
/// token — so a block with no ruby at all yields exactly one token per
/// sentence, the common case — and each ruby run becomes its own token with
/// `reading` set, splitting the surrounding plain text at that boundary. A
/// ruby run is attributed whole to the sentence containing its start offset:
/// real furigana is always attached to a kanji/word span, so it never itself
/// contains a sentence terminator and can never legitimately straddle a
/// boundary the splitter finds.
///
/// Returns one inner list per L1 sentence, in order; `[]` if the block's
/// flattened text is empty/whitespace-only (callers are expected to have
/// already filtered those out — see `extractRawBlocksXml`/`Html` in
/// epub_ruby.dart — but this stays total rather than assuming that).
List<List<Token>> tokenListsForBlock(List<Run> runs) {
  final spans = splitIntoSentenceSpans(plainTextOf(runs));
  if (spans.isEmpty) return const [];

  final positioned = _positionRuns(runs);
  return [for (final span in spans) _tokensForSpan(positioned, span)];
}

class _PositionedRun {
  _PositionedRun(this.run, this.start, this.end);

  final Run run;
  final int start;
  final int end;
}

/// Assigns each run its `[start, end)` offset range within the block's
/// flattened plain text (ruby runs contribute their `base` length, matching
/// [plainTextOf]), so a sentence span's character range can be mapped back
/// onto whichever runs cover it.
List<_PositionedRun> _positionRuns(List<Run> runs) {
  final result = <_PositionedRun>[];
  var offset = 0;
  for (final run in runs) {
    final length = run is RubyRun
        ? run.base.length
        : (run as TextRun).text.length;
    result.add(_PositionedRun(run, offset, offset + length));
    offset += length;
  }
  return result;
}

List<Token> _tokensForSpan(
  List<_PositionedRun> positionedRuns,
  SentenceSpan span,
) {
  final tokens = <Token>[];
  final buffer = StringBuffer();

  void flushBuffer() {
    if (buffer.isNotEmpty) {
      tokens.add(Token(surface: buffer.toString()));
      buffer.clear();
    }
  }

  for (final entry in positionedRuns) {
    if (entry.end <= span.start || entry.start >= span.end) {
      continue; // this run doesn't overlap the current sentence at all
    }

    final run = entry.run;
    if (run is RubyRun) {
      // Only attribute the run to the span containing its *start* -- avoids
      // double-counting it in the (never-expected-in-practice) case that it
      // numerically overlaps more than one span.
      if (entry.start >= span.start) {
        flushBuffer();
        tokens.add(Token(surface: run.base, reading: run.reading));
      }
    } else {
      final text = (run as TextRun).text;
      final localStart = math.max(0, span.start - entry.start);
      final localEnd = math.min(text.length, span.end - entry.start);
      if (localEnd > localStart) {
        buffer.write(text.substring(localStart, localEnd));
      }
    }
  }

  flushBuffer();
  return tokens;
}
