import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart' as xml;

import 'epub/epub_container.dart';
import 'pdf_scanned/pdf_page_rasterizer.dart';

/// Cover art for the Library's per-book thumbnail (not spec §4/§7's reading
/// pipeline): the EPUB's own declared cover image, or a low-res render of a
/// PDF's first page. Returns `null` -- never throws -- on any failure or
/// absence, since a missing/broken cover must never break an import; the
/// Library simply falls back to its per-source-type placeholder icon.
Future<Uint8List?> extractCoverArt(
  File file, {
  PdfPageRasterizer pdfRasterizer = const PdfrxPageRasterizer(),
}) async {
  try {
    final extension = p.extension(file.path).toLowerCase();
    if (extension == '.epub') return await _extractEpubCover(file);
    if (extension == '.pdf') return await _extractPdfCover(file, pdfRasterizer);
    return null;
  } catch (_) {
    return null;
  }
}

Future<Uint8List?> _extractEpubCover(File file) async {
  final bytes = await file.readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);
  final opfPath = readOpfPath(archive);
  final opfBasePath = dirnameOf(opfPath);
  final opfDoc = xml.XmlDocument.parse(readEntryAsString(archive, opfPath));
  final manifest = parseManifest(opfDoc, opfBasePath);
  final coverItem = findCoverManifestItem(opfDoc, manifest);
  if (coverItem == null) return null;
  return readEntryAsBytes(archive, coverItem.href);
}

/// Thumbnail width cap for a rendered PDF page-1 cover -- a full-page raster
/// at native resolution is dramatically larger than a typical embedded EPUB
/// cover, so this is downscaled; `img.copyResize` with only `width` given
/// auto-preserves aspect ratio.
const _thumbnailMaxWidth = 240;

Future<Uint8List?> _extractPdfCover(
  File file,
  PdfPageRasterizer rasterizer,
) async {
  final session = await rasterizer.open(file);
  try {
    if (session.pageCount == 0) return null;
    final page = await session.renderPage(0);
    if (page == null) return null;
    var image = img.Image.fromBytes(
      width: page.width,
      height: page.height,
      bytes: page.pixels.buffer,
      bytesOffset: page.pixels.offsetInBytes,
      order: img.ChannelOrder.bgra,
      numChannels: 4,
    );
    if (image.width > _thumbnailMaxWidth) {
      image = img.copyResize(image, width: _thumbnailMaxWidth);
    }
    return Uint8List.fromList(img.encodePng(image));
  } finally {
    await session.close();
  }
}
