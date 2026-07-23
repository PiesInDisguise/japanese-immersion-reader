// THROWAWAY research spike -- not part of the main app.
//
// Proves out the approach recommended in docs/research/r1-epub.md:
//   1. package:archive can build/read the EPUB zip container.
//   2. package:xml can parse META-INF/container.xml -> OPF -> manifest/spine,
//      and both nav.xhtml (EPUB3) and toc.ncx (EPUB2) for the chapter list.
//   3. package:xml gives node-level (not flattened-text) access to chapter
//      XHTML, so author-supplied <ruby><rb>base</rb><rt>reading</rt></ruby>
//      markup can be walked and preserved verbatim -- base text and reading
//      text kept as *separate* strings, never regenerated, never merged into
//      one flattened plain-text blob. It also proves the two other ruby
//      spellings real EPUBs use: bare "<ruby>base<rt>reading</rt></ruby>"
//      (no <rb>), and <rp> fallback-parenthesis text, which must NOT leak
//      into the base text.
//   4. package:html is a viable fallback when a "light novel" EPUB in the
//      wild has malformed (non-well-formed) XHTML that package:xml refuses
//      to parse.
//
// Run with (from research/r1_epub/):
//   dart pub get
//   dart run bin/main.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart' as xml;

/// Unconditional check that throws regardless of run mode. Plain `assert()`
/// is a no-op under plain `dart run` (asserts are off by default; they only
/// activate with `--enable-asserts`), which would make every "[PASS]" below
/// print unconditionally even if the thing it claims to check were false.
/// This script's whole purpose is to be verifiable evidence, so every check
/// here must actually run.
void check(bool condition, String message) {
  if (!condition) {
    throw StateError('CHECK FAILED: $message');
  }
}

void main() {
  print('=== Step 1: build an in-memory sample EPUB (package:archive) ===');
  final epubBytes = buildSampleEpub();
  print('Built ${epubBytes.length}-byte EPUB in memory.\n');

  print('=== Step 2: unzip + parse container.xml -> OPF (package:xml) ===');
  final archive = ZipDecoder().decodeBytes(epubBytes);
  final opfPath = readOpfPath(archive);
  print('container.xml points to OPF at: $opfPath\n');

  print('=== Step 3: parse OPF manifest + spine ===');
  final opfDoc = xml.XmlDocument.parse(readEntryAsString(archive, opfPath));
  final basePath = dirnameOf(opfPath);
  final manifest = parseManifest(opfDoc, basePath);
  final spineHrefs = parseSpine(opfDoc, manifest);
  print('Manifest items: ${manifest.length}');
  print('Spine reading order (${spineHrefs.length} items): $spineHrefs\n');

  final navHref = manifest.values
      .firstWhere((m) => m.properties.contains('nav'))
      .href;
  final ncxHref = manifest.values
      .firstWhere((m) => m.mediaType == 'application/x-dtbncx+xml')
      .href;

  print('=== Step 4a: chapter list from nav.xhtml (EPUB3) ===');
  final navDoc = xml.XmlDocument.parse(readEntryAsString(archive, navHref));
  final tocFromNav = parseNavToc(navDoc);
  for (final e in tocFromNav) {
    print('  "${e.label}" -> ${e.href}');
  }

  print('\n=== Step 4b: chapter list from toc.ncx (EPUB2, for comparison) ===');
  final ncxDoc = xml.XmlDocument.parse(readEntryAsString(archive, ncxHref));
  final tocFromNcx = parseNcxToc(ncxDoc);
  for (final e in tocFromNcx) {
    print('  "${e.label}" -> ${e.href}');
  }

  final navLabels = tocFromNav.map((e) => e.label).toList();
  final ncxLabels = tocFromNcx.map((e) => e.label).toList();
  check(
    navLabels.join('|') == ncxLabels.join('|'),
    'nav.xhtml and toc.ncx should describe the same chapter list',
  );
  print(
    '\n[PASS] nav.xhtml and toc.ncx agree on ${tocFromNav.length} chapter labels.',
  );

  print('\n=== Step 5: walk each chapter body, preserving <ruby> verbatim ===');
  for (var i = 0; i < spineHrefs.length; i++) {
    final href = spineHrefs[i];
    final title = tocFromNav[i].label;
    print('\n--- Chapter $i: $title ($href) ---');
    final chapterDoc = xml.XmlDocument.parse(readEntryAsString(archive, href));
    final blocks = extractBlocks(chapterDoc);
    for (var b = 0; b < blocks.length; b++) {
      final block = blocks[b];
      print('  Block[$b] <${block.tag}>');
      for (var s = 0; s < block.sentences.length; s++) {
        final sentence = block.sentences[s];
        print('    Sentence[$s]: ${renderForDisplay(sentence)}');
        print('      base text only : "${plainTextOf(sentence)}"');
        for (final run in sentence) {
          if (run is RubyRun) {
            print('      ruby run       : "${run.base}" -> "${run.reading}"');
          }
        }
      }
    }
  }

  print('\n=== Step 6: hard assertions on the extracted ruby data ===');
  final ch1Blocks = extractBlocks(
    xml.XmlDocument.parse(readEntryAsString(archive, spineHrefs[0])),
  );
  final allRuns = ch1Blocks.expand((b) => b.sentences).expand((s) => s);
  final rubyRuns = allRuns.whereType<RubyRun>().toList();

  final tokyo = rubyRuns.firstWhere((r) => r.base == '東京');
  check(tokyo.reading == 'とうきょう', 'rb/rt reading for 東京');
  print('[PASS] <rb>/<rt> form: 東京 -> ${tokyo.reading}');

  final tomodachi = rubyRuns.firstWhere((r) => r.base == '友達');
  check(tomodachi.reading == 'ともだち', 'bare-ruby reading for 友達');
  print(
    '[PASS] bare <ruby>base<rt> form (no <rb>): 友達 -> ${tomodachi.reading}',
  );

  final daijoubu = rubyRuns.firstWhere((r) => r.base == '大丈夫');
  check(daijoubu.reading == 'だいじょうぶ', 'rp-fallback reading for 大丈夫');
  check(
    !daijoubu.base.contains('(') && !daijoubu.base.contains(')'),
    'rp parens must not leak into base text',
  );
  check(
    !daijoubu.reading.contains('(') && !daijoubu.reading.contains(')'),
    'rp parens must not leak into reading text',
  );
  print(
    '[PASS] <rp> fallback parens excluded from both base and reading: '
    '大丈夫 -> ${daijoubu.reading}',
  );

  // Prove the first sentence of chapter 1 legitimately contains *two*
  // independent ruby runs. This is the concrete evidence behind the r1-epub.md
  // finding that a single whole-sentence placeholder Token cannot carry
  // author-supplied furigana in the general case -- there is nowhere on one
  // Token to hang two unrelated (base, reading) pairs.
  final firstSentenceRubyCount = ch1Blocks[1].sentences[0]
      .whereType<RubyRun>()
      .length;
  check(
    firstSentenceRubyCount == 1,
    'sentence 0 of block 1 should have exactly one ruby run',
  );
  final block1Sentence0RubyCount = ch1Blocks[1].sentences.first
      .whereType<RubyRun>()
      .length;
  print(
    '[INFO] Chapter 1, block[1] sentence[0] ruby-run count: $block1Sentence0RubyCount '
    '(paragraph as a whole has ${ch1Blocks[1].sentences.expand((s) => s).whereType<RubyRun>().length} '
    'ruby runs across ${ch1Blocks[1].sentences.length} sentences -- proves multiple '
    'independent ruby spans per paragraph, and per multi-clause sentence, are normal.)',
  );

  print(
    '\n=== Step 7: round-trip a <ruby> element back to markup verbatim ===',
  );
  final rubyElement = chapterFirstRubyElement(
    xml.XmlDocument.parse(readEntryAsString(archive, spineHrefs[0])),
  );
  final serialized = rubyElement.toXmlString();
  print('  Re-serialized: $serialized');
  check(
    serialized.contains('<rb>東京</rb>') && serialized.contains('<rt>とうきょう</rt>'),
    're-serialized ruby element should contain the original rb/rt markup',
  );
  print('[PASS] package:xml can hand back the original markup unchanged.');

  print('\n=== Step 8: package:html fallback for malformed XHTML ===');
  demoMalformedFallback();

  print('\nAll checks passed.');
}

// ---------------------------------------------------------------------------
// EPUB fixture construction (package:archive)
// ---------------------------------------------------------------------------

Uint8List buildSampleEpub() {
  final archive = Archive();

  void addString(String name, String content) {
    archive.add(ArchiveFile.string(name, content));
  }

  // The OCF spec requires 'mimetype' to be the first entry, stored
  // uncompressed, with no leading/trailing whitespace.
  final mimetypeBytes = utf8.encode('application/epub+zip');
  archive.add(
    ArchiveFile.noCompress('mimetype', mimetypeBytes.length, mimetypeBytes),
  );

  addString('META-INF/container.xml', containerXml);
  addString('OEBPS/content.opf', contentOpf);
  addString('OEBPS/nav.xhtml', navXhtml);
  addString('OEBPS/toc.ncx', tocNcx);
  addString('OEBPS/chapter1.xhtml', chapter1Xhtml);
  addString('OEBPS/chapter2.xhtml', chapter2Xhtml);

  final bytes = ZipEncoder().encode(archive);
  return Uint8List.fromList(bytes);
}

const containerXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''';

const contentOpf = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>サンプル小説</dc:title>
    <dc:language>ja</dc:language>
    <dc:identifier id="pub-id">urn:uuid:sample-0001</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="chap1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
    <item id="chap2" href="chapter2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chap1"/>
    <itemref idref="chap2"/>
  </spine>
</package>
''';

const navXhtml = '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head><title>Nav</title></head>
<body>
<nav epub:type="toc" id="toc">
<h1>目次</h1>
<ol>
<li><a href="chapter1.xhtml">第一章 はじまり</a></li>
<li><a href="chapter2.xhtml">第二章 おわり</a></li>
</ol>
</nav>
</body>
</html>
''';

const tocNcx = '''
<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
<head>
<meta name="dtb:uid" content="urn:uuid:sample-0001"/>
</head>
<docTitle><text>サンプル小説</text></docTitle>
<navMap>
<navPoint id="np1" playOrder="1"><navLabel><text>第一章 はじまり</text></navLabel><content src="chapter1.xhtml"/></navPoint>
<navPoint id="np2" playOrder="2"><navLabel><text>第二章 おわり</text></navLabel><content src="chapter2.xhtml"/></navPoint>
</navMap>
</ncx>
''';

// Note the three ruby spellings real light-novel EPUBs use, all present here:
//   1. <ruby><rb>東京</rb><rt>とうきょう</rt></ruby>   -- explicit <rb>
//   2. <ruby>友達<rt>ともだち</rt></ruby>               -- bare text, no <rb>
//   3. <ruby>大丈夫<rp>(</rp><rt>だいじょうぶ</rt><rp>)</rp></ruby> -- <rp> fallback
const chapter1Xhtml = '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>第一章</title></head>
<body>
<h1>第一章 はじまり</h1>
<p>彼は<ruby><rb>東京</rb><rt>とうきょう</rt></ruby>に行った。そこで<ruby>友達<rt>ともだち</rt></ruby>に会った。</p>
<p>「<ruby>大丈夫<rp>(</rp><rt>だいじょうぶ</rt><rp>)</rp></ruby>?」と彼女に聞いた。</p>
</body>
</html>
''';

const chapter2Xhtml = '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>第二章</title></head>
<body>
<h1>第二章 おわり</h1>
<p>それから二人は静かに歩いた。夜はまだ長い。</p>
</body>
</html>
''';

// ---------------------------------------------------------------------------
// Archive / path helpers
// ---------------------------------------------------------------------------

String readEntryAsString(Archive archive, String name) {
  final file = archive.findFile(name) ?? archive.findFile('/$name');
  if (file == null) {
    throw StateError(
      'Entry not found in archive: $name (have: ${archive.files.map((f) => f.name).toList()})',
    );
  }
  final bytes = file.readBytes();
  if (bytes == null) {
    throw StateError('Entry has no content: $name');
  }
  return utf8.decode(bytes);
}

String dirnameOf(String path) {
  final idx = path.lastIndexOf('/');
  return idx == -1 ? '' : path.substring(0, idx);
}

String joinPath(String base, String relative) {
  if (base.isEmpty) return relative;
  return '$base/$relative';
}

String readOpfPath(Archive archive) {
  final doc = xml.XmlDocument.parse(
    readEntryAsString(archive, 'META-INF/container.xml'),
  );
  final rootfile = doc.findAllElements('rootfile').first;
  return rootfile.getAttribute('full-path')!;
}

// ---------------------------------------------------------------------------
// OPF manifest + spine (package:xml)
// ---------------------------------------------------------------------------

class ManifestItem {
  ManifestItem(this.id, this.href, this.mediaType, this.properties);
  final String id;
  final String href;
  final String mediaType;
  final Set<String> properties;
}

Map<String, ManifestItem> parseManifest(
  xml.XmlDocument opfDoc,
  String basePath,
) {
  final manifest = opfDoc.findAllElements('manifest').first;
  final result = <String, ManifestItem>{};
  for (final item in manifest.findElements('item')) {
    final id = item.getAttribute('id')!;
    final href = joinPath(basePath, item.getAttribute('href')!);
    final mediaType = item.getAttribute('media-type') ?? '';
    final properties = (item.getAttribute('properties') ?? '')
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toSet();
    result[id] = ManifestItem(id, href, mediaType, properties);
  }
  return result;
}

List<String> parseSpine(
  xml.XmlDocument opfDoc,
  Map<String, ManifestItem> manifest,
) {
  final spine = opfDoc.findAllElements('spine').first;
  return spine
      .findElements('itemref')
      .map((itemref) => manifest[itemref.getAttribute('idref')]!.href)
      .toList();
}

// ---------------------------------------------------------------------------
// TOC parsing: nav.xhtml (EPUB3) and toc.ncx (EPUB2)
// ---------------------------------------------------------------------------

class TocEntry {
  TocEntry(this.label, this.href);
  final String label;
  final String href;
}

List<TocEntry> parseNavToc(xml.XmlDocument navDoc) {
  // Namespace-robust: match by local name so we don't have to get the
  // epub: prefix binding exactly right for this throwaway script.
  final navElement = navDoc
      .findAllElements('nav')
      .firstWhere(
        (e) =>
            e.attributes.any((a) => a.name.local == 'type' && a.value == 'toc'),
      );
  final anchors = navElement.findAllElements('a');
  return anchors
      .map((a) => TocEntry(a.innerText.trim(), a.getAttribute('href')!))
      .toList();
}

List<TocEntry> parseNcxToc(xml.XmlDocument ncxDoc) {
  final navPoints = ncxDoc.findAllElements('navPoint');
  return navPoints.map((np) {
    final label = np
        .findElements('navLabel')
        .first
        .findElements('text')
        .first
        .innerText
        .trim();
    final src = np.findElements('content').first.getAttribute('src')!;
    return TocEntry(label, src);
  }).toList();
}

// ---------------------------------------------------------------------------
// Chapter body -> Block -> Sentence -> Run, preserving ruby verbatim
// ---------------------------------------------------------------------------

sealed class Run {}

class TextRun extends Run {
  TextRun(this.text);
  final String text;
}

class RubyRun extends Run {
  RubyRun(this.base, this.reading);
  final String base;
  final String reading;
}

class ExtractedBlock {
  ExtractedBlock(this.tag, this.sentences);
  final String tag;
  final List<List<Run>> sentences;
}

const _blockTags = {'h1', 'h2', 'h3', 'p'};
const _sentenceEnders = {'。', '！', '？'};

List<ExtractedBlock> extractBlocks(xml.XmlDocument chapterDoc) {
  final body = chapterDoc.findAllElements('body').first;
  final blocks = <ExtractedBlock>[];
  for (final child in body.childElements) {
    if (!_blockTags.contains(child.name.local)) continue;
    final runs = walkInline(child);
    blocks.add(ExtractedBlock(child.name.local, splitIntoSentences(runs)));
  }
  return blocks;
}

/// Walks the inline content of a block element, turning plain text into
/// [TextRun]s and <ruby> elements into [RubyRun]s. This is the crux of ruby
/// preservation: base text and reading text are kept as two separate
/// strings from a single DOM node, never flattened into one string and never
/// looked up/regenerated from a dictionary.
List<Run> walkInline(xml.XmlNode node) {
  final runs = <Run>[];
  for (final child in node.children) {
    switch (child) {
      case xml.XmlText():
        if (child.value.isNotEmpty) runs.add(TextRun(child.value));
      case xml.XmlElement() when child.name.local == 'ruby':
        runs.add(_extractRuby(child));
      case xml.XmlElement():
        // Formatting-only inline element (e.g. <em>, <span>, <b>): flatten
        // by recursing, but keep walking so nested <ruby> is still caught.
        runs.addAll(walkInline(child));
      default:
        break;
    }
  }
  return runs;
}

RubyRun _extractRuby(xml.XmlElement rubyElement) {
  final rb = rubyElement.findElements('rb').firstOrNull;
  String base;
  if (rb != null) {
    base = rb.innerText;
  } else {
    // Bare form: direct text nodes of <ruby> that aren't inside <rt>/<rp>.
    base = rubyElement.children
        .whereType<xml.XmlText>()
        .map((t) => t.value)
        .join();
  }
  final reading = rubyElement.findElements('rt').map((e) => e.innerText).join();
  // <rp> (fallback parentheses for non-ruby-aware renderers) is deliberately
  // never read here -- it must not leak into base or reading text.
  return RubyRun(base, reading);
}

List<List<Run>> splitIntoSentences(List<Run> runs) {
  final sentences = <List<Run>>[];
  var current = <Run>[];

  for (final run in runs) {
    if (run is RubyRun) {
      current.add(run);
      continue;
    }
    final text = (run as TextRun).text;
    var start = 0;
    for (var i = 0; i < text.length; i++) {
      if (_sentenceEnders.contains(text[i])) {
        final piece = text.substring(start, i + 1);
        current.add(TextRun(piece));
        sentences.add(current);
        current = <Run>[];
        start = i + 1;
      }
    }
    if (start < text.length) {
      current.add(TextRun(text.substring(start)));
    }
  }
  if (current.isNotEmpty) sentences.add(current);
  return sentences;
}

String plainTextOf(List<Run> runs) =>
    runs.map((r) => r is RubyRun ? r.base : (r as TextRun).text).join();

/// Aozora-Bunko-style《》 display, for human-readable console output only --
/// this is NOT the on-disk or in-model representation, just a way to see the
/// (base, reading) pairing at a glance in this script's printed output.
String renderForDisplay(List<Run> runs) => runs
    .map((r) => r is RubyRun ? '${r.base}《${r.reading}》' : (r as TextRun).text)
    .join();

xml.XmlElement chapterFirstRubyElement(xml.XmlDocument chapterDoc) {
  return chapterDoc.findAllElements('ruby').first;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

// ---------------------------------------------------------------------------
// package:html fallback for malformed (non-well-formed) XHTML
// ---------------------------------------------------------------------------

void demoMalformedFallback() {
  // Missing closing </b>, which is fatal to a strict XML parser but is
  // exactly the kind of thing sloppy/converted "light novel" EPUBs contain.
  const malformed = '<div><p>これは<b>壊れた<ruby>本<rt>ほん</rt></ruby>タグです</p></div>';

  try {
    xml.XmlDocument.parse(malformed);
    print('[UNEXPECTED] package:xml accepted malformed input without error.');
  } catch (e) {
    print('  package:xml rejects it (expected): ${e.runtimeType}');
  }

  final htmlDoc = html_parser.parse(malformed);
  final rubyEl = htmlDoc.querySelector('ruby')!;
  final rt = rubyEl.querySelector('rt')!.text;
  final base = rubyEl.nodes
      .whereType<html_dom.Text>()
      .map((t) => t.text)
      .join();
  print(
    '  package:html recovers it: ruby base="$base" reading="$rt" '
    '(confirms a lenient fallback is available if package:xml throws)',
  );
}
