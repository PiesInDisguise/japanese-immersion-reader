import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'remote_book_source.dart';

/// A [RemoteBookSource] over an OPDS (Open Publication Distribution System)
/// catalog feed -- spec §5's other named example alongside WebDAV. OPDS is
/// plain Atom XML: each `<entry>` describes one book, with an
/// `<link rel="http://opds-spec.org/acquisition...">` (or a plain
/// `rel="acquisition"`) pointing at the actual file. This reads one feed
/// page at a time -- **paginated catalogs** (`<link rel="next">`) aren't
/// followed automatically, matching this pass's scope.
class OpdsBookSource implements RemoteBookSource {
  OpdsBookSource({required this.feedUrl, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final String feedUrl;
  final http.Client _httpClient;

  @override
  Future<List<RemoteBookEntry>> listBooks() async {
    final uri = Uri.parse(feedUrl);
    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      throw StateError(
        'OpdsBookSource: GET $feedUrl returned HTTP ${response.statusCode}; '
        'expected 200.',
      );
    }

    final document = XmlDocument.parse(response.body);
    final entries = <RemoteBookEntry>[];
    for (final entry in document.findAllElements('entry', namespaceUri: '*')) {
      final acquisitionLink = _acquisitionLink(entry);
      if (acquisitionLink == null) continue;

      final titleElements = entry.findElements('title', namespaceUri: '*');
      final title = titleElements.isEmpty
          ? 'Untitled'
          : titleElements.first.innerText.trim();

      final idElements = entry.findElements('id', namespaceUri: '*');
      final id = idElements.isEmpty ? title : idElements.first.innerText.trim();

      entries.add(
        RemoteBookEntry(
          id: id,
          title: title,
          author: _authorName(entry),
          downloadUrl: uri.resolve(acquisitionLink).toString(),
        ),
      );
    }
    return entries;
  }

  /// An OPDS acquisition link's `rel` is usually the full
  /// `http://opds-spec.org/acquisition` URI (sometimes with a suffix like
  /// `/open-access`), but some minimal feeds just use a bare `rel`
  /// containing "acquisition" -- matched loosely for both.
  String? _acquisitionLink(XmlElement entry) {
    for (final link in entry.findElements('link', namespaceUri: '*')) {
      final rel = link.getAttribute('rel') ?? '';
      if (rel.contains('acquisition')) {
        return link.getAttribute('href');
      }
    }
    return null;
  }

  String? _authorName(XmlElement entry) {
    final authorElements = entry.findElements('author', namespaceUri: '*');
    if (authorElements.isEmpty) return null;
    final nameElements = authorElements.first.findElements(
      'name',
      namespaceUri: '*',
    );
    if (nameElements.isEmpty) return null;
    return nameElements.first.innerText.trim();
  }
}
