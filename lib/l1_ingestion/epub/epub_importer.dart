import 'dart:io';

import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:japanese_immersion_reader/core/ids/stable_id.dart';
import 'package:japanese_immersion_reader/core/models/models.dart';
import 'package:japanese_immersion_reader/l1_ingestion/importer.dart';
import 'package:xml/xml.dart' as xml;

import 'epub_container.dart';
import 'epub_ruby.dart';
import 'epub_sentence_builder.dart';

/// Parses an EPUB (2 or 3) into a normalized [Document]: unzips the
/// container, resolves `container.xml` -> OPF -> manifest/spine for chapter
/// content order, resolves `nav.xhtml`/`toc.ncx` for chapter titles, and
/// walks each chapter's XHTML body into `Block`/`Sentence`/`Token`s,
/// preserving author-supplied `<ruby>` readings verbatim rather than
/// regenerating them.
///
/// See docs/research/r1-epub.md for the parsing approach this follows and
/// the schema-gap finding that motivated `Sentence.tokens` allowing more
/// than one pre-L2 placeholder token (one per ruby-run boundary).
class EpubImporter implements Importer {
  @override
  Future<Document> import(
    File file, {
    required void Function(ImportProgress progress) onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final documentId = contentDerivedDocumentId('epub', bytes);

    final opfPath = readOpfPath(archive);
    final opfBasePath = dirnameOf(opfPath);
    final opfDoc = xml.XmlDocument.parse(readEntryAsString(archive, opfPath));
    final manifest = parseManifest(opfDoc, opfBasePath);
    final spineHrefs = parseSpine(opfDoc, manifest);
    final chapterTitles = _resolveChapterTitles(archive, manifest, spineHrefs);

    final chapters = <Chapter>[];
    final totalChapters = spineHrefs.length;

    for (var chapterIndex = 0; chapterIndex < totalChapters; chapterIndex++) {
      final content = readEntryAsString(archive, spineHrefs[chapterIndex]);
      final rawBlocks = _parseChapterBody(content);

      final blocks = <Block>[];
      for (final rawBlock in rawBlocks) {
        final tokenLists = tokenListsForBlock(rawBlock.runs);
        if (tokenLists.isEmpty) continue;

        final blockIndex = blocks.length;
        final sentences = [
          for (var s = 0; s < tokenLists.length; s++)
            Sentence(
              id: stableNodeId(documentId, [chapterIndex, blockIndex, s]),
              index: s,
              tokens: tokenLists[s],
            ),
        ];
        blocks.add(
          Block(
            id: stableNodeId(documentId, [chapterIndex, blockIndex]),
            index: blockIndex,
            kind: BlockKind.paragraph,
            sentences: sentences,
          ),
        );
      }

      chapters.add(
        Chapter(
          id: stableNodeId(documentId, [chapterIndex]),
          index: chapterIndex,
          title: chapterTitles[chapterIndex],
          blocks: blocks,
        ),
      );

      onProgress(
        ImportProgress(
          fraction: (chapterIndex + 1) / totalChapters,
          stage: ImportStage.parsing,
          currentChapterIndex: chapterIndex,
        ),
      );
    }

    onProgress(
      ImportProgress(
        fraction: 1.0,
        stage: ImportStage.done,
        currentChapterIndex: totalChapters == 0 ? null : totalChapters - 1,
      ),
    );

    return Document(
      id: documentId,
      title: parseOpfTitle(opfDoc) ?? _titleFromFileName(file),
      sourceType: DocumentSourceType.epub,
      chapters: chapters,
    );
  }

  /// Parses one chapter's XHTML body into [RawBlock]s. Tries the
  /// spec-correct `package:xml` path first; malformed/non-well-formed
  /// sideloaded EPUBs (unclosed tags, stray unescaped `&`, ...) throw an
  /// [xml.XmlException] there, so that one file falls back to
  /// `package:html`'s lenient HTML5 parser instead. See
  /// docs/research/r1-epub.md §1.
  List<RawBlock> _parseChapterBody(String content) {
    try {
      final body = xml.XmlDocument.parse(content).findAllElements('body').first;
      return extractRawBlocksXml(body);
    } on xml.XmlException {
      final body = html_parser.parse(content).body;
      return body == null ? const [] : extractRawBlocksHtml(body);
    }
  }

  /// One title per spine entry (by position), looked up from whichever TOC
  /// is available (EPUB3 nav preferred, EPUB2 `toc.ncx` fallback, `null` for
  /// every chapter if neither is present) by matching hrefs with any
  /// `#fragment` stripped. A spine file with no matching TOC entry gets a
  /// `null` title -- an honest signal, not a synthesized label.
  ///
  /// Deliberately does not attempt to sub-split one spine file into several
  /// Chapters when multiple TOC entries anchor into different parts of it --
  /// flagged in docs/research/r1-epub.md §2 as a real but unsolved edge
  /// case; the policy here is the simpler "one Chapter per spine item."
  List<String?> _resolveChapterTitles(
    Archive archive,
    Map<String, ManifestItem> manifest,
    List<String> spineHrefs,
  ) {
    final toc = _readToc(archive, manifest);
    final titleByHref = <String, String>{
      for (final entry in toc) stripFragment(entry.href): entry.label,
    };
    return [for (final href in spineHrefs) titleByHref[href]];
  }

  List<TocEntry> _readToc(Archive archive, Map<String, ManifestItem> manifest) {
    final navItem = _firstWhereOrNull(
      manifest.values,
      (m) => m.properties.contains('nav'),
    );
    if (navItem != null) {
      final navDoc = xml.XmlDocument.parse(
        readEntryAsString(archive, navItem.href),
      );
      return parseNavToc(navDoc, dirnameOf(navItem.href));
    }

    final ncxItem = _firstWhereOrNull(
      manifest.values,
      (m) => m.mediaType == 'application/x-dtbncx+xml',
    );
    if (ncxItem != null) {
      final ncxDoc = xml.XmlDocument.parse(
        readEntryAsString(archive, ncxItem.href),
      );
      return parseNcxToc(ncxDoc, dirnameOf(ncxItem.href));
    }

    return const [];
  }

  String _titleFromFileName(File file) {
    final name = file.uri.pathSegments.last;
    final dotIndex = name.lastIndexOf('.');
    return dotIndex == -1 ? name : name.substring(0, dotIndex);
  }
}

T? _firstWhereOrNull<T>(Iterable<T> iterable, bool Function(T) test) {
  for (final item in iterable) {
    if (test(item)) return item;
  }
  return null;
}
