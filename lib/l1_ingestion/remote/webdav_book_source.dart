import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'remote_book_source.dart';

/// A [RemoteBookSource] over a WebDAV directory (spec §5: "a personal media
/// server, WebDAV, OPDS, or a custom endpoint") -- lists a folder's `.epub`/
/// `.pdf` files via a `PROPFIND` request (the standard WebDAV directory-
/// listing method; not a REST convenience endpoint any server adds, but
/// part of the protocol itself, so this works against any real WebDAV
/// server: Nextcloud, a NAS's built-in WebDAV, etc.) and resolves each
/// listed href against [baseUrl] for the actual download URL.
class WebDavBookSource implements RemoteBookSource {
  WebDavBookSource({
    required this.baseUrl,
    this.username,
    this.password,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final String? username;
  final String? password;
  final http.Client _httpClient;

  static const _bookExtensions = ['.epub', '.pdf'];

  @override
  Future<List<RemoteBookEntry>> listBooks() async {
    final uri = Uri.parse(baseUrl);
    final request = http.Request('PROPFIND', uri)
      ..headers['Depth'] = '1'
      ..headers['Content-Type'] = 'application/xml; charset=utf-8'
      ..body =
          '<?xml version="1.0" encoding="utf-8" ?>'
          '<D:propfind xmlns:D="DAV:"><D:prop><D:resourcetype/></D:prop>'
          '</D:propfind>';
    _applyBasicAuth(request);

    final streamed = await _httpClient.send(request);
    // WebDAV's real success code is 207 Multi-Status, not 200 -- a server
    // returning 200 to a PROPFIND would actually be unusual/wrong.
    if (streamed.statusCode != 207) {
      throw StateError(
        'WebDavBookSource: PROPFIND $baseUrl returned HTTP '
        '${streamed.statusCode}; expected 207 Multi-Status.',
      );
    }
    final body = await streamed.stream.bytesToString();
    final document = XmlDocument.parse(body);

    final entries = <RemoteBookEntry>[];
    for (final response in document.findAllElements(
      'response',
      namespaceUri: '*',
    )) {
      final hrefElements = response.findElements('href', namespaceUri: '*');
      if (hrefElements.isEmpty) continue;
      final href = hrefElements.first.innerText.trim();
      if (href.isEmpty) continue;

      final decodedPath = Uri.decodeComponent(href);
      final matchesBook = _bookExtensions.any(
        (ext) => decodedPath.toLowerCase().endsWith(ext),
      );
      if (!matchesBook) continue;

      final segments = decodedPath
          .split('/')
          .where((segment) => segment.isNotEmpty);
      final title = segments.isEmpty ? decodedPath : segments.last;

      entries.add(
        RemoteBookEntry(
          id: href,
          title: title,
          downloadUrl: uri.resolve(href).toString(),
        ),
      );
    }
    return entries;
  }

  void _applyBasicAuth(http.Request request) {
    if (username == null) return;
    final credentials = base64Encode(utf8.encode('$username:$password'));
    request.headers['Authorization'] = 'Basic $credentials';
  }
}
