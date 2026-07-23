import 'package:html/dom.dart' as html_dom;
import 'package:xml/xml.dart' as xml;

/// One piece of a block's inline content, in reading order: either plain
/// text or an author-supplied `<ruby>` span. Kept as separate pieces (never
/// flattened into one string) so a ruby span's reading survives all the way
/// to a `Token.reading` — see docs/research/r1-epub.md.
sealed class Run {}

/// Plain text with no furigana.
class TextRun extends Run {
  TextRun(this.text);

  final String text;
}

/// One author-supplied `<ruby>` span: `base` is the annotated text (from
/// `<rb>` if present, otherwise the ruby element's own direct text nodes)
/// and `reading` is the furigana (from `<rt>`). `<rp>` fallback-parenthesis
/// text is never read into either field, by design — see
/// docs/research/r1-epub.md §1 for why naively flattening the element would
/// leak it into the visible text.
class RubyRun extends Run {
  RubyRun(this.base, this.reading);

  final String base;
  final String reading;
}

/// A block-level element (`<p>`, a heading, ...) with its inline content
/// already walked into [Run]s, but not yet split into sentences/tokens.
class RawBlock {
  RawBlock(this.tag, this.runs);

  final String tag;
  final List<Run> runs;
}

const _blockTags = {'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'};

/// The text a reader sees with furigana hidden: ruby runs contribute their
/// `base`, never their `reading` or any `<rp>` text. This is the string
/// sentence-boundary detection runs against (see epub_sentence_builder.dart)
/// — boundaries are found in the reading order a reader sees, not in a
/// string that mixes in furigana.
String plainTextOf(List<Run> runs) =>
    runs.map((run) => run is RubyRun ? run.base : (run as TextRun).text).join();

// ---------------------------------------------------------------------------
// package:xml backend (primary: well-formed XHTML)
// ---------------------------------------------------------------------------

/// Recursively finds block-level elements (`<p>`/headings) under [root],
/// descending into wrapping containers (`<div>`, `<section>`, ...) so a
/// chapter body that groups paragraphs inside a wrapper still yields the
/// same blocks a flat body would. Blocks that flatten to empty/whitespace
/// (e.g. `<p></p>`) are dropped rather than emitted as empty blocks.
List<RawBlock> extractRawBlocksXml(xml.XmlElement root) {
  final blocks = <RawBlock>[];
  void visit(xml.XmlElement element) {
    for (final child in element.childElements) {
      if (_blockTags.contains(child.name.local)) {
        final runs = walkInlineXml(child);
        if (plainTextOf(runs).trim().isNotEmpty) {
          blocks.add(RawBlock(child.name.local, runs));
        }
      } else {
        visit(child);
      }
    }
  }

  visit(root);
  return blocks;
}

/// Walks the inline content of a block element, turning plain text into
/// [TextRun]s and `<ruby>` elements into [RubyRun]s — the crux of ruby
/// preservation: base and reading text are read as two separate strings off
/// one DOM node, never flattened into one string and never regenerated from
/// a dictionary. Other inline elements (`<em>`, `<span>`, ...) are
/// formatting-only as far as this model is concerned: flattened by
/// recursing into them, so any `<ruby>` nested inside is still caught.
List<Run> walkInlineXml(xml.XmlNode node) {
  final runs = <Run>[];
  for (final child in node.children) {
    switch (child) {
      case xml.XmlText():
        if (child.value.isNotEmpty) runs.add(TextRun(child.value));
      case xml.XmlElement() when child.name.local == 'ruby':
        runs.add(_extractRubyXml(child));
      case xml.XmlElement():
        runs.addAll(walkInlineXml(child));
      default:
        break;
    }
  }
  return runs;
}

RubyRun _extractRubyXml(xml.XmlElement rubyElement) {
  final rb = _firstOrNull(rubyElement.findElements('rb'));
  final base = rb != null
      ? rb.innerText
      : rubyElement.children
            .whereType<xml.XmlText>()
            .map((t) => t.value)
            .join();
  final reading = rubyElement.findElements('rt').map((e) => e.innerText).join();
  // <rp> fallback parentheses are deliberately never read here.
  return RubyRun(base, reading);
}

// ---------------------------------------------------------------------------
// package:html backend (fallback: malformed/non-well-formed XHTML)
// ---------------------------------------------------------------------------

/// As [extractRawBlocksXml], but walking a `package:html`-parsed DOM — used
/// when a sideloaded EPUB's chapter XHTML isn't well-formed XML and
/// `xml.XmlDocument.parse` throws. See docs/research/r1-epub.md §1.
List<RawBlock> extractRawBlocksHtml(html_dom.Element root) {
  final blocks = <RawBlock>[];
  void visit(html_dom.Element element) {
    for (final child in element.children) {
      if (_blockTags.contains(child.localName)) {
        final runs = walkInlineHtml(child);
        if (plainTextOf(runs).trim().isNotEmpty) {
          blocks.add(RawBlock(child.localName!, runs));
        }
      } else {
        visit(child);
      }
    }
  }

  visit(root);
  return blocks;
}

/// As [walkInlineXml], but over a `package:html` DOM node. Ruby lookup uses
/// `querySelector`/`querySelectorAll` (descendant search) rather than
/// assuming direct-child structure, since the whole point of this backend is
/// tolerating markup a lenient parser had to reshape to recover.
List<Run> walkInlineHtml(html_dom.Node node) {
  final runs = <Run>[];
  for (final child in node.nodes) {
    if (child is html_dom.Text) {
      if (child.data.isNotEmpty) runs.add(TextRun(child.data));
    } else if (child is html_dom.Element) {
      if (child.localName == 'ruby') {
        runs.add(_extractRubyHtml(child));
      } else {
        runs.addAll(walkInlineHtml(child));
      }
    }
  }
  return runs;
}

RubyRun _extractRubyHtml(html_dom.Element rubyElement) {
  final rb = rubyElement.querySelector('rb');
  final base = rb != null
      ? rb.text
      : rubyElement.nodes.whereType<html_dom.Text>().map((t) => t.data).join();
  final reading = rubyElement.querySelectorAll('rt').map((e) => e.text).join();
  // <rp> fallback parentheses are deliberately never read here.
  return RubyRun(base, reading);
}

T? _firstOrNull<T>(Iterable<T> iterable) {
  for (final item in iterable) {
    return item;
  }
  return null;
}
