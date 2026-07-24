/// One downloadable book a [RemoteBookSource] found -- enough to show in a
/// picker and to fetch the actual file afterward.
class RemoteBookEntry {
  const RemoteBookEntry({
    required this.id,
    required this.title,
    required this.downloadUrl,
    this.author,
  });

  /// A stable identifier for this book *within its source* (e.g. a WebDAV
  /// href, an OPDS entry id) -- not necessarily the download URL itself,
  /// since a source could reshuffle its URL scheme without a book's
  /// identity actually changing. Used to key the local download cache
  /// (`RemoteBookDownloader`) so re-listing the same source doesn't
  /// re-download a book already fetched.
  final String id;

  final String title;
  final String? author;
  final String downloadUrl;
}

/// Spec §5's "pluggable provider interface" for remote book sources (a
/// personal media server via WebDAV, OPDS, or a custom endpoint) --
/// designed as an interface from day one, per spec, so a new source type
/// drops in without `HomeScreen`'s import flow needing to change, only a
/// new implementation of this class.
abstract class RemoteBookSource {
  /// Lists every downloadable book this source currently exposes.
  Future<List<RemoteBookEntry>> listBooks();
}
