// Generates the EPUB fixtures under assets/fixtures/ used by
// epub_importer_test.dart. Not a test itself (no `test()`/`group()` calls,
// and its filename doesn't end in `_test.dart`, so `flutter test` never
// picks it up) -- a one-off, re-runnable utility kept around (rather than
// discarded like the throwaway research/r1_epub/ spike) in case a fixture
// ever needs regenerating to cover another ruby form or quirk.
//
// Run from the repo root:
//   dart run test/l1_ingestion/epub/fixture_generator.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

void main() {
  _writeEpub('assets/fixtures/epub_ruby_forms.epub', _buildRubyFormsEpub());
  _writeEpub('assets/fixtures/epub_plain_text.epub', _buildPlainTextEpub());
  _writeEpub('assets/fixtures/epub_malformed.epub', _buildMalformedEpub());
  _writeEpub('assets/fixtures/epub_cover_epub3.epub', _buildEpub3CoverEpub());
  _writeEpub('assets/fixtures/epub_cover_epub2.epub', _buildEpub2CoverEpub());
}

void _writeEpub(String path, Uint8List bytes) {
  File(path).writeAsBytesSync(bytes);
}

Uint8List _buildEpub(
  Map<String, String> textEntries, {
  Map<String, Uint8List> binaryEntries = const {},
}) {
  final archive = Archive();

  // The OCF spec requires 'mimetype' to be the first entry, stored
  // uncompressed, with no leading/trailing whitespace.
  final mimetypeBytes = utf8.encode('application/epub+zip');
  archive.add(
    ArchiveFile.noCompress('mimetype', mimetypeBytes.length, mimetypeBytes),
  );

  textEntries.forEach((name, content) {
    archive.add(ArchiveFile.string(name, content));
  });
  binaryEntries.forEach((name, bytes) {
    archive.add(ArchiveFile(name, bytes.length, bytes));
  });

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

const _containerXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''';

// ---------------------------------------------------------------------------
// Fixture 1: multiple ruby forms (<rb>/<rt>, bare, <rp>-fallback), including
// two independent ruby runs inside one sentence -- the concrete case from
// docs/research/r1-epub.md that motivated Sentence.tokens allowing more than
// one pre-L2 placeholder. Both nav.xhtml and toc.ncx present (real EPUB3
// books commonly ship both); the importer prefers nav.xhtml.
// ---------------------------------------------------------------------------

Uint8List _buildRubyFormsEpub() {
  const opf = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>サンプル小説</dc:title>
    <dc:language>ja</dc:language>
    <dc:identifier id="pub-id">urn:uuid:ruby-forms-0001</dc:identifier>
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

  const nav = '''
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

  const ncx = '''
<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
<head><meta name="dtb:uid" content="urn:uuid:ruby-forms-0001"/></head>
<docTitle><text>サンプル小説</text></docTitle>
<navMap>
<navPoint id="np1" playOrder="1"><navLabel><text>第一章 はじまり</text></navLabel><content src="chapter1.xhtml"/></navPoint>
<navPoint id="np2" playOrder="2"><navLabel><text>第二章 おわり</text></navLabel><content src="chapter2.xhtml"/></navPoint>
</navMap>
</ncx>
''';

  // Three ruby spellings in one paragraph, plus a third paragraph with two
  // *independent* ruby runs inside a single sentence (先生/せんせい and
  // 難しい/むずかしい) -- proving a sentence can carry more than one
  // author-supplied reading at once.
  const chapter1 = '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>第一章</title></head>
<body>
<h1>第一章 はじまり</h1>
<p>彼は<ruby><rb>東京</rb><rt>とうきょう</rt></ruby>に行った。そこで<ruby>友達<rt>ともだち</rt></ruby>に会った。</p>
<p>「<ruby>大丈夫<rp>(</rp><rt>だいじょうぶ</rt><rp>)</rp></ruby>?」と彼女に聞いた。</p>
<p>その<ruby>先生<rt>せんせい</rt></ruby>は<ruby>難しい<rt>むずかしい</rt></ruby>漢字を書いた。</p>
</body>
</html>
''';

  const chapter2 = '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>第二章</title></head>
<body>
<h1>第二章 おわり</h1>
<p>それから二人は静かに歩いた。夜はまだ長い。</p>
</body>
</html>
''';

  return _buildEpub({
    'META-INF/container.xml': _containerXml,
    'OEBPS/content.opf': opf,
    'OEBPS/nav.xhtml': nav,
    'OEBPS/toc.ncx': ncx,
    'OEBPS/chapter1.xhtml': chapter1,
    'OEBPS/chapter2.xhtml': chapter2,
  });
}

// ---------------------------------------------------------------------------
// Fixture 2: plain text, no ruby anywhere -- confirms the no-ruby path
// yields exactly one token per sentence. Also EPUB2-style: no nav.xhtml at
// all, only toc.ncx, exercising the NCX-fallback chapter-title path.
// ---------------------------------------------------------------------------

Uint8List _buildPlainTextEpub() {
  const opf = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="pub-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>普通の小説</dc:title>
    <dc:language>ja</dc:language>
    <dc:identifier id="pub-id">urn:uuid:plain-text-0001</dc:identifier>
  </metadata>
  <manifest>
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

  const ncx = '''
<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
<head><meta name="dtb:uid" content="urn:uuid:plain-text-0001"/></head>
<docTitle><text>普通の小説</text></docTitle>
<navMap>
<navPoint id="np1" playOrder="1"><navLabel><text>一章</text></navLabel><content src="chapter1.xhtml"/></navPoint>
<navPoint id="np2" playOrder="2"><navLabel><text>二章</text></navLabel><content src="chapter2.xhtml"/></navPoint>
</navMap>
</ncx>
''';

  const chapter1 = '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>一章</title></head>
<body>
<h1>一章</h1>
<p>猫は屋根の上で眠っていた。日差しは暖かかった。</p>
<p>やがて風が吹いて、木の葉が揺れた。</p>
</body>
</html>
''';

  const chapter2 = '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>二章</title></head>
<body>
<h1>二章</h1>
<p>彼女は静かに本を読んでいた。</p>
</body>
</html>
''';

  return _buildEpub({
    'META-INF/container.xml': _containerXml,
    'OEBPS/content.opf': opf,
    'OEBPS/toc.ncx': ncx,
    'OEBPS/chapter1.xhtml': chapter1,
    'OEBPS/chapter2.xhtml': chapter2,
  });
}

// ---------------------------------------------------------------------------
// Fixture 3: malformed chapter XHTML (unclosed <b>) that package:xml refuses
// to parse, forcing the package:html fallback -- which must still recover
// the nested ruby span. Container/OPF/nav/ncx are all well-formed; only the
// chapter body is broken, matching a real sideloaded-EPUB failure mode.
// ---------------------------------------------------------------------------

Uint8List _buildMalformedEpub() {
  const opf = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>壊れた本</dc:title>
    <dc:language>ja</dc:language>
    <dc:identifier id="pub-id">urn:uuid:malformed-0001</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="chap1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chap1"/>
  </spine>
</package>
''';

  const nav = '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head><title>Nav</title></head>
<body>
<nav epub:type="toc" id="toc">
<ol>
<li><a href="chapter1.xhtml">第一章</a></li>
</ol>
</nav>
</body>
</html>
''';

  const ncx = '''
<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
<head><meta name="dtb:uid" content="urn:uuid:malformed-0001"/></head>
<docTitle><text>壊れた本</text></docTitle>
<navMap>
<navPoint id="np1" playOrder="1"><navLabel><text>第一章</text></navLabel><content src="chapter1.xhtml"/></navPoint>
</navMap>
</ncx>
''';

  // Deliberately unclosed <b> -- fatal to a strict XML parser (dart-xml
  // throws an XmlException on the mismatched </p>), but exactly the kind of
  // sloppy markup a real sideloaded "light novel" EPUB can contain.
  // package:html's lenient HTML5 parser must recover this and still expose
  // the nested <ruby> for extraction.
  const chapter1 = '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>第一章</title></head>
<body>
<h1>第一章</h1>
<div><p>これは<b>壊れた<ruby>本<rt>ほん</rt></ruby>タグです。まだ続く文章がある。</p></div>
</body>
</html>
''';

  return _buildEpub({
    'META-INF/container.xml': _containerXml,
    'OEBPS/content.opf': opf,
    'OEBPS/nav.xhtml': nav,
    'OEBPS/toc.ncx': ncx,
    'OEBPS/chapter1.xhtml': chapter1,
  });
}

// ---------------------------------------------------------------------------
// Fixtures 4-5: cover art (cover_art_extractor_test.dart). The embedded
// "cover" content is a small marker byte sequence, not a real decodable
// image -- the extractor-level test only asserts raw-byte pass-through from
// the manifest item, it never decodes the bytes as an image.
// ---------------------------------------------------------------------------

final _fakeCoverBytes = Uint8List.fromList(utf8.encode('FAKE_COVER_BYTES'));

/// EPUB3-style cover declaration: `<item properties="cover-image">`.
Uint8List _buildEpub3CoverEpub() {
  const opf = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>表紙付きの本 (EPUB3)</dc:title>
    <dc:language>ja</dc:language>
    <dc:identifier id="pub-id">urn:uuid:cover-epub3-0001</dc:identifier>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="cover-img" href="cover.png" media-type="image/png" properties="cover-image"/>
    <item id="chap1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="chap1"/>
  </spine>
</package>
''';

  const nav = '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head><title>Nav</title></head>
<body>
<nav epub:type="toc" id="toc">
<ol><li><a href="chapter1.xhtml">第一章</a></li></ol>
</nav>
</body>
</html>
''';

  const chapter1 = '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>第一章</title></head>
<body><p>表紙のある本です。</p></body>
</html>
''';

  return _buildEpub(
    {
      'META-INF/container.xml': _containerXml,
      'OEBPS/content.opf': opf,
      'OEBPS/nav.xhtml': nav,
      'OEBPS/chapter1.xhtml': chapter1,
    },
    binaryEntries: {'OEBPS/cover.png': _fakeCoverBytes},
  );
}

/// EPUB2-style cover declaration: no `properties` attribute at all, instead
/// `<metadata><meta name="cover" content="ITEM_ID">` pointing at the
/// manifest item by id.
Uint8List _buildEpub2CoverEpub() {
  const opf = '''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="pub-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>表紙付きの本 (EPUB2)</dc:title>
    <dc:language>ja</dc:language>
    <dc:identifier id="pub-id">urn:uuid:cover-epub2-0001</dc:identifier>
    <meta name="cover" content="cover-img"/>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="cover-img" href="cover.png" media-type="image/png"/>
    <item id="chap1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chap1"/>
  </spine>
</package>
''';

  const ncx = '''
<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
<head><meta name="dtb:uid" content="urn:uuid:cover-epub2-0001"/></head>
<docTitle><text>表紙付きの本 (EPUB2)</text></docTitle>
<navMap>
<navPoint id="np1" playOrder="1"><navLabel><text>第一章</text></navLabel><content src="chapter1.xhtml"/></navPoint>
</navMap>
</ncx>
''';

  const chapter1 = '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>第一章</title></head>
<body><p>表紙のある本です。</p></body>
</html>
''';

  return _buildEpub(
    {
      'META-INF/container.xml': _containerXml,
      'OEBPS/content.opf': opf,
      'OEBPS/toc.ncx': ncx,
      'OEBPS/chapter1.xhtml': chapter1,
    },
    binaryEntries: {'OEBPS/cover.png': _fakeCoverBytes},
  );
}
