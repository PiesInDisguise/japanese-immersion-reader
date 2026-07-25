import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;

/// One `<manifest><item>` entry from the OPF: `href` is already resolved
/// relative to the archive root (joined against the OPF's own directory), so
/// it is directly usable as an archive entry name.
class ManifestItem {
  ManifestItem(this.id, this.href, this.mediaType, this.properties);

  final String id;
  final String href;
  final String mediaType;
  final Set<String> properties;
}

/// One chapter-list entry from `nav.xhtml` (EPUB3) or `toc.ncx` (EPUB2).
/// `href` is resolved relative to the archive root (joined against that TOC
/// document's own directory, which is not always the OPF's directory) and
/// may carry a `#fragment` pointing at a location inside a spine file — see
/// [stripFragment].
class TocEntry {
  TocEntry(this.label, this.href);

  final String label;
  final String href;
}

/// Reads a zip entry as UTF-8 text. Tries both `name` and `/name` since some
/// archives store entries with a leading slash.
String readEntryAsString(Archive archive, String name) {
  final file = archive.findFile(name) ?? archive.findFile('/$name');
  if (file == null) {
    throw StateError('EPUB entry not found: $name');
  }
  final bytes = file.readBytes();
  if (bytes == null) {
    throw StateError('EPUB entry has no content: $name');
  }
  return utf8.decode(bytes);
}

/// Reads a zip entry's raw bytes, or `null` if the entry doesn't exist or
/// has no content -- the binary-safe sibling of [readEntryAsString], which
/// UTF-8-decodes and throws. Cover art needs raw image bytes, and its
/// caller treats "not found" as "no cover" rather than a hard error.
Uint8List? readEntryAsBytes(Archive archive, String name) {
  final file = archive.findFile(name) ?? archive.findFile('/$name');
  return file?.readBytes();
}

/// The directory portion of an archive-relative path, `''` if `path` has no
/// directory component.
String dirnameOf(String path) {
  final idx = path.lastIndexOf('/');
  return idx == -1 ? '' : path.substring(0, idx);
}

/// Joins a possibly-relative `relative` path onto `base`, collapsing `.` and
/// `..` segments — needed because manifest hrefs are relative to the OPF's
/// directory while TOC-internal hrefs are relative to the TOC document's own
/// (not always identical) directory.
String joinPath(String base, String relative) {
  final combined = base.isEmpty ? relative : '$base/$relative';
  final segments = <String>[];
  for (final part in combined.split('/')) {
    if (part.isEmpty || part == '.') continue;
    if (part == '..') {
      if (segments.isNotEmpty) segments.removeLast();
    } else {
      segments.add(part);
    }
  }
  return segments.join('/');
}

/// Strips a trailing `#fragment` from an href, e.g. a TOC entry pointing at
/// an anchor inside a spine file rather than at the file as a whole.
String stripFragment(String href) {
  final idx = href.indexOf('#');
  return idx == -1 ? href : href.substring(0, idx);
}

/// `META-INF/container.xml` always exists at this fixed path and always
/// points to the OPF (the "rootfile").
String readOpfPath(Archive archive) {
  final doc = xml.XmlDocument.parse(
    readEntryAsString(archive, 'META-INF/container.xml'),
  );
  final rootfile = doc.findAllElements('rootfile').first;
  return rootfile.getAttribute('full-path')!;
}

/// Parses the OPF `<manifest>`: `id -> {href, media-type, properties}`, with
/// `href` resolved relative to the archive root.
Map<String, ManifestItem> parseManifest(
  xml.XmlDocument opfDoc,
  String opfBasePath,
) {
  final manifest = opfDoc.findAllElements('manifest').first;
  final result = <String, ManifestItem>{};
  for (final item in manifest.findElements('item')) {
    final id = item.getAttribute('id')!;
    final href = joinPath(opfBasePath, item.getAttribute('href')!);
    final mediaType = item.getAttribute('media-type') ?? '';
    final properties = (item.getAttribute('properties') ?? '')
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toSet();
    result[id] = ManifestItem(id, href, mediaType, properties);
  }
  return result;
}

/// The manifest item for this EPUB's cover image: EPUB3's
/// `<item properties="cover-image">` (the identical `properties`-`Set`
/// pattern `EpubImporter` already uses for `properties.contains('nav')`),
/// falling back to EPUB2's `<metadata><meta name="cover" content="ITEM_ID">`.
/// `null` if neither is declared -- a common, honest case (not every EPUB
/// has a cover), not a parse error.
ManifestItem? findCoverManifestItem(
  xml.XmlDocument opfDoc,
  Map<String, ManifestItem> manifest,
) {
  for (final item in manifest.values) {
    if (item.properties.contains('cover-image')) return item;
  }
  final metadataElements = opfDoc.findAllElements('metadata');
  if (metadataElements.isEmpty) return null;
  for (final meta in metadataElements.first.findElements('meta')) {
    if (meta.getAttribute('name') == 'cover') {
      return manifest[meta.getAttribute('content')];
    }
  }
  return null;
}

/// Parses the OPF `<spine>` into the linear reading order of chapter content
/// hrefs — this, not the TOC, is ground truth for chapter *content* order (a
/// TOC can nest, omit, or reorder entries relative to it).
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

/// The book title from OPF `<dc:title>`, or `null` if absent/blank.
/// Namespace-robust (`namespaceUri: '*'`): matches by local name `title` so
/// this doesn't depend on `dc` being the literal prefix bound to the Dublin
/// Core namespace, even though it always is in practice.
String? parseOpfTitle(xml.XmlDocument opfDoc) {
  final titles = opfDoc.findAllElements('title', namespaceUri: '*');
  if (titles.isEmpty) return null;
  final text = titles.first.innerText.trim();
  return text.isEmpty ? null : text;
}

/// EPUB3 chapter list: the manifest item with `properties="nav"`, parsed as
/// XHTML, walked for `<nav epub:type="toc"><ol><li><a href="...">Label</a>`.
List<TocEntry> parseNavToc(xml.XmlDocument navDoc, String navBasePath) {
  final navElement = navDoc
      .findAllElements('nav')
      .firstWhere(
        (e) =>
            e.attributes.any((a) => a.name.local == 'type' && a.value == 'toc'),
      );
  return navElement
      .findAllElements('a')
      .map(
        (a) => TocEntry(
          a.innerText.trim(),
          joinPath(navBasePath, a.getAttribute('href')!),
        ),
      )
      .toList();
}

/// EPUB2 legacy chapter list: `navMap/navPoint` (recursively nestable in the
/// source, walked flat here since `Chapter` doesn't model TOC nesting),
/// `navLabel/text` for the label, `content/@src` for the target.
List<TocEntry> parseNcxToc(xml.XmlDocument ncxDoc, String ncxBasePath) {
  return ncxDoc.findAllElements('navPoint').map((navPoint) {
    final label = navPoint
        .findElements('navLabel')
        .first
        .findElements('text')
        .first
        .innerText
        .trim();
    final src = navPoint.findElements('content').first.getAttribute('src')!;
    return TocEntry(label, joinPath(ncxBasePath, src));
  }).toList();
}
