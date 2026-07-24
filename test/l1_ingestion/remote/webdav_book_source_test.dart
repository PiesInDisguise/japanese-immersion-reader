// Plain `test()`, no real network -- http.Client.send is overridden with a
// canned in-memory response, same pattern as grammar_explanation_client_test.dart.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:japanese_immersion_reader/l1_ingestion/remote/webdav_book_source.dart';

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
    );
  }

  @override
  void close() {}
}

const _propfindResponse = '''
<?xml version="1.0" encoding="utf-8"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/books/</d:href>
    <d:propstat>
      <d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/books/My%20Novel.epub</d:href>
    <d:propstat>
      <d:prop><d:resourcetype/></d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/books/readme.txt</d:href>
    <d:propstat>
      <d:prop><d:resourcetype/></d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
''';

void main() {
  group('WebDavBookSource', () {
    test('lists only book files, skipping the directory and non-book files', () async {
      final fake = _FakeHttpClient(statusCode: 207, body: _propfindResponse);
      final source = WebDavBookSource(
        baseUrl: 'https://example.com/books/',
        httpClient: fake,
      );

      final books = await source.listBooks();

      expect(books, hasLength(1));
      expect(books.single.title, 'My Novel.epub');
      expect(
        books.single.downloadUrl,
        'https://example.com/books/My%20Novel.epub',
      );
      expect(books.single.id, '/books/My%20Novel.epub');
    });

    test('sends a PROPFIND request with Depth: 1', () async {
      final fake = _FakeHttpClient(statusCode: 207, body: _propfindResponse);
      final source = WebDavBookSource(
        baseUrl: 'https://example.com/books/',
        httpClient: fake,
      );

      await source.listBooks();

      expect(fake.lastRequest!.method, 'PROPFIND');
      expect(fake.lastRequest!.headers['Depth'], '1');
    });

    test('sends HTTP Basic auth when credentials are supplied', () async {
      final fake = _FakeHttpClient(statusCode: 207, body: _propfindResponse);
      final source = WebDavBookSource(
        baseUrl: 'https://example.com/books/',
        username: 'alice',
        password: 'secret',
        httpClient: fake,
      );

      await source.listBooks();

      final expected =
          'Basic ${base64Encode(utf8.encode('alice:secret'))}';
      expect(fake.lastRequest!.headers['Authorization'], expected);
    });

    test('omits Authorization when no credentials are given', () async {
      final fake = _FakeHttpClient(statusCode: 207, body: _propfindResponse);
      final source = WebDavBookSource(
        baseUrl: 'https://example.com/books/',
        httpClient: fake,
      );

      await source.listBooks();

      expect(fake.lastRequest!.headers.containsKey('Authorization'), isFalse);
    });

    test('throws when the server does not return 207', () async {
      final fake = _FakeHttpClient(statusCode: 404, body: '');
      final source = WebDavBookSource(
        baseUrl: 'https://example.com/books/',
        httpClient: fake,
      );

      await expectLater(source.listBooks(), throwsStateError);
    });
  });
}
