import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/l1_ingestion/epub/epub_container.dart';
import 'package:xml/xml.dart' as xml;

Archive _archiveWith(Map<String, String> entries) {
  final archive = Archive();
  entries.forEach((name, content) {
    archive.add(ArchiveFile.string(name, content));
  });
  return archive;
}

void main() {
  group('path helpers', () {
    test('dirnameOf returns everything before the last slash', () {
      expect(dirnameOf('OEBPS/chapter1.xhtml'), 'OEBPS');
      expect(dirnameOf('OEBPS/text/chapter1.xhtml'), 'OEBPS/text');
    });

    test('dirnameOf returns empty string for a path with no directory', () {
      expect(dirnameOf('content.opf'), '');
    });

    test('joinPath joins a base and a relative path', () {
      expect(joinPath('OEBPS', 'chapter1.xhtml'), 'OEBPS/chapter1.xhtml');
    });

    test('joinPath treats an empty base as "no directory"', () {
      expect(joinPath('', 'content.opf'), 'content.opf');
    });

    test('joinPath collapses .. segments', () {
      expect(
        joinPath('OEBPS/toc', '../text/chapter1.xhtml'),
        'OEBPS/text/chapter1.xhtml',
      );
    });

    test('stripFragment removes a trailing #anchor', () {
      expect(stripFragment('chapter1.xhtml#section2'), 'chapter1.xhtml');
    });

    test('stripFragment is a no-op when there is no fragment', () {
      expect(stripFragment('chapter1.xhtml'), 'chapter1.xhtml');
    });
  });

  group('readEntryAsString', () {
    test('reads back UTF-8 text content, including non-ASCII', () {
      final archive = _archiveWith({'OEBPS/chapter1.xhtml': '第一章'});
      expect(readEntryAsString(archive, 'OEBPS/chapter1.xhtml'), '第一章');
    });

    test('also finds an entry stored with a leading slash', () {
      final archive = _archiveWith({'/OEBPS/chapter1.xhtml': 'text'});
      expect(readEntryAsString(archive, 'OEBPS/chapter1.xhtml'), 'text');
    });

    test('throws for a missing entry', () {
      final archive = _archiveWith({});
      expect(
        () => readEntryAsString(archive, 'missing.xhtml'),
        throwsStateError,
      );
    });
  });

  test('readOpfPath finds the rootfile full-path from container.xml', () {
    final archive = _archiveWith({
      'META-INF/container.xml': '''
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''',
    });
    expect(readOpfPath(archive), 'OEBPS/content.opf');
  });

  group('parseManifest / parseSpine', () {
    xml.XmlDocument buildOpf() => xml.XmlDocument.parse('''
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>サンプル小説</dc:title>
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
''');

    test('parseManifest resolves hrefs relative to the OPF directory', () {
      final manifest = parseManifest(buildOpf(), 'OEBPS');
      expect(manifest['chap1']!.href, 'OEBPS/chapter1.xhtml');
      expect(manifest['nav']!.href, 'OEBPS/nav.xhtml');
      expect(manifest['nav']!.properties, contains('nav'));
      expect(manifest['ncx']!.mediaType, 'application/x-dtbncx+xml');
    });

    test('parseManifest resolves hrefs against an empty base', () {
      final manifest = parseManifest(buildOpf(), '');
      expect(manifest['chap1']!.href, 'chapter1.xhtml');
    });

    test('parseSpine follows itemref/idref through the manifest', () {
      final manifest = parseManifest(buildOpf(), 'OEBPS');
      final spine = parseSpine(buildOpf(), manifest);
      expect(spine, ['OEBPS/chapter1.xhtml']);
    });

    test('parseOpfTitle reads dc:title regardless of its namespace prefix', () {
      expect(parseOpfTitle(buildOpf()), 'サンプル小説');
    });

    test('parseOpfTitle returns null when there is no title element', () {
      final doc = xml.XmlDocument.parse('''
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/"></metadata>
  <manifest></manifest>
  <spine></spine>
</package>
''');
      expect(parseOpfTitle(doc), isNull);
    });
  });

  test('parseNavToc walks nav.xhtml <ol><li><a> entries in order', () {
    final navDoc = xml.XmlDocument.parse('''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<body>
<nav epub:type="toc" id="toc">
<ol>
<li><a href="chapter1.xhtml">第一章 はじまり</a></li>
<li><a href="chapter2.xhtml">第二章 おわり</a></li>
</ol>
</nav>
</body>
</html>
''');
    final toc = parseNavToc(navDoc, 'OEBPS');
    expect(toc.map((e) => e.label).toList(), ['第一章 はじまり', '第二章 おわり']);
    expect(toc.map((e) => e.href).toList(), [
      'OEBPS/chapter1.xhtml',
      'OEBPS/chapter2.xhtml',
    ]);
  });

  test('parseNcxToc walks navMap/navPoint entries in order', () {
    final ncxDoc = xml.XmlDocument.parse('''
<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
<navMap>
<navPoint id="np1" playOrder="1"><navLabel><text>第一章 はじまり</text></navLabel><content src="chapter1.xhtml"/></navPoint>
<navPoint id="np2" playOrder="2"><navLabel><text>第二章 おわり</text></navLabel><content src="chapter2.xhtml"/></navPoint>
</navMap>
</ncx>
''');
    final toc = parseNcxToc(ncxDoc, 'OEBPS');
    expect(toc.map((e) => e.label).toList(), ['第一章 はじまり', '第二章 おわり']);
    expect(toc.map((e) => e.href).toList(), [
      'OEBPS/chapter1.xhtml',
      'OEBPS/chapter2.xhtml',
    ]);
  });

  test(
    'nav.xhtml and toc.ncx describing the same book agree on chapter labels',
    () {
      final navDoc = xml.XmlDocument.parse('''
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<body><nav epub:type="toc"><ol>
<li><a href="chapter1.xhtml">第一章</a></li>
<li><a href="chapter2.xhtml">第二章</a></li>
</ol></nav></body>
</html>
''');
      final ncxDoc = xml.XmlDocument.parse('''
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
<navMap>
<navPoint id="np1"><navLabel><text>第一章</text></navLabel><content src="chapter1.xhtml"/></navPoint>
<navPoint id="np2"><navLabel><text>第二章</text></navLabel><content src="chapter2.xhtml"/></navPoint>
</navMap>
</ncx>
''');
      expect(
        parseNavToc(navDoc, '').map((e) => e.label).toList(),
        parseNcxToc(ncxDoc, '').map((e) => e.label).toList(),
      );
    },
  );
}
