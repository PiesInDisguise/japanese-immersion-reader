// Plain `test()`, no real network -- http.Client.send is overridden with a
// canned in-memory response.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:japanese_immersion_reader/l1_ingestion/remote/opds_book_source.dart';

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
    );
  }

  @override
  void close() {}
}

const _opdsFeed = '''
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>My Catalog</title>
  <entry>
    <title>Sample Book</title>
    <id>urn:uuid:1234</id>
    <author><name>Jane Author</name></author>
    <link rel="http://opds-spec.org/acquisition" href="/download/1234.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <title>No Download Entry</title>
    <id>urn:uuid:5678</id>
  </entry>
</feed>
''';

void main() {
  group('OpdsBookSource', () {
    test('lists entries that have an acquisition link', () async {
      final fake = _FakeHttpClient(statusCode: 200, body: _opdsFeed);
      final source = OpdsBookSource(
        feedUrl: 'https://example.com/opds/catalog.xml',
        httpClient: fake,
      );

      final books = await source.listBooks();

      expect(books, hasLength(1));
      final book = books.single;
      expect(book.title, 'Sample Book');
      expect(book.id, 'urn:uuid:1234');
      expect(book.author, 'Jane Author');
      expect(book.downloadUrl, 'https://example.com/download/1234.epub');
    });

    test('skips entries with no acquisition link', () async {
      final fake = _FakeHttpClient(statusCode: 200, body: _opdsFeed);
      final source = OpdsBookSource(
        feedUrl: 'https://example.com/opds/catalog.xml',
        httpClient: fake,
      );

      final books = await source.listBooks();

      expect(books.map((b) => b.title), isNot(contains('No Download Entry')));
    });

    test('throws on a non-200 status', () async {
      final fake = _FakeHttpClient(statusCode: 500, body: '');
      final source = OpdsBookSource(
        feedUrl: 'https://example.com/opds/catalog.xml',
        httpClient: fake,
      );

      await expectLater(source.listBooks(), throwsStateError);
    });
  });
}
