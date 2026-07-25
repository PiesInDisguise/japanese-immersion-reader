import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:japanese_immersion_reader/l1_ingestion/cover_art_extractor.dart';
import 'package:japanese_immersion_reader/l1_ingestion/pdf_scanned/pdf_page_rasterizer.dart';

class _ThrowingPdfPageRasterizer implements PdfPageRasterizer {
  @override
  Future<PdfPageRasterizerSession> open(File file) {
    throw StateError('_ThrowingPdfPageRasterizer.open should not succeed');
  }
}

void main() {
  group('EPUB cover extraction', () {
    test('EPUB3 properties="cover-image" returns the manifest item\'s exact '
        'bytes', () async {
      final bytes = await extractCoverArt(
        File('assets/fixtures/epub_cover_epub3.epub'),
      );

      expect(bytes, isNotNull);
      expect(String.fromCharCodes(bytes!), 'FAKE_COVER_BYTES');
    });

    test('EPUB2 <meta name="cover"> fallback returns the same bytes', () async {
      final bytes = await extractCoverArt(
        File('assets/fixtures/epub_cover_epub2.epub'),
      );

      expect(bytes, isNotNull);
      expect(String.fromCharCodes(bytes!), 'FAKE_COVER_BYTES');
    });

    test('an EPUB with no cover declared returns null, not an error', () async {
      final bytes = await extractCoverArt(
        File('assets/fixtures/epub_plain_text.epub'),
      );

      expect(bytes, isNull);
    });

    test('a malformed/corrupt file returns null', () async {
      final bytes = await extractCoverArt(
        File('assets/fixtures/epub_malformed.epub'),
      );

      // epub_malformed.epub has a broken chapter body but a well-formed
      // container/OPF -- no cover-image property or EPUB2 <meta name="cover">
      // is declared, so this exercises the "no cover" path, not a thrown
      // exception. A genuinely unparseable file is covered by the next test.
      expect(bytes, isNull);
    });

    test('a file that isn\'t a real zip archive returns null', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'cover_art_extractor_test_',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final notAZip = File('${tempDir.path}/not_a_real.epub');
      await notAZip.writeAsBytes([1, 2, 3, 4]);

      expect(await extractCoverArt(notAZip), isNull);
    });
  });

  group('PDF cover extraction', () {
    test('renders page 1 of a real PDF as a small PNG', () async {
      final bytes = await extractCoverArt(
        File('assets/fixtures/synthetic_horizontal_ja.pdf'),
      );

      expect(bytes, isNotNull);
      final image = img.decodePng(bytes!);
      expect(image, isNotNull);
      expect(image!.width, lessThanOrEqualTo(240));
    });

    test('a rasterizer that fails to open returns null, not an error', () async {
      final bytes = await extractCoverArt(
        File('assets/fixtures/synthetic_horizontal_ja.pdf'),
        pdfRasterizer: _ThrowingPdfPageRasterizer(),
      );

      expect(bytes, isNull);
    });
  });

  test('an unsupported extension returns null', () async {
    final bytes = await extractCoverArt(File('some/path/book.txt'));
    expect(bytes, isNull);
  });
}
