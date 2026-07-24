import 'dart:io';

import 'package:flutter/material.dart';
import 'package:japanese_immersion_reader/l1_ingestion/remote/opds_book_source.dart';
import 'package:japanese_immersion_reader/l1_ingestion/remote/remote_book_downloader.dart';
import 'package:japanese_immersion_reader/l1_ingestion/remote/remote_book_source.dart';
import 'package:japanese_immersion_reader/l1_ingestion/remote/webdav_book_source.dart';

enum _SourceKind { webdav, opds }

/// Spec §5's remote-book-source browser: connect to a WebDAV directory or
/// an OPDS catalog feed, list what it has, and download one -- pops with
/// the downloaded local [File] (via [Navigator.pop]) so the caller
/// (`HomeScreen`) can import it exactly like a sideloaded file, without
/// this screen needing to know anything about EPUB/PDF parsing itself.
///
/// Doesn't persist the entered URL/credentials anywhere (spec's own framing
/// is "designed as an interface from day one", not "with full settings
/// integration day one") -- re-enter them each time for now.
class RemoteBrowseScreen extends StatefulWidget {
  const RemoteBrowseScreen({super.key});

  @override
  State<RemoteBrowseScreen> createState() => _RemoteBrowseScreenState();
}

class _RemoteBrowseScreenState extends State<RemoteBrowseScreen> {
  _SourceKind _kind = _SourceKind.webdav;
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _connecting = false;
  String? _connectError;
  List<RemoteBookEntry>? _books;
  String? _downloadingEntryId;

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  RemoteBookSource _buildSource() {
    final url = _urlController.text.trim();
    return switch (_kind) {
      _SourceKind.webdav => WebDavBookSource(
        baseUrl: url,
        username: _usernameController.text.trim().isEmpty
            ? null
            : _usernameController.text.trim(),
        password: _passwordController.text.isEmpty
            ? null
            : _passwordController.text,
      ),
      _SourceKind.opds => OpdsBookSource(feedUrl: url),
    };
  }

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _connectError = null;
      _books = null;
    });
    try {
      final books = await _buildSource().listBooks();
      if (!mounted) return;
      setState(() => _books = books);
    } catch (e) {
      if (!mounted) return;
      setState(() => _connectError = '$e');
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _downloadAndReturn(RemoteBookEntry entry) async {
    setState(() => _downloadingEntryId = entry.id);
    try {
      final file = await const RemoteBookDownloader().download(entry);
      if (mounted) Navigator.of(context).pop(file);
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloadingEntryId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Remote source')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<_SourceKind>(
              segments: const [
                ButtonSegment(value: _SourceKind.webdav, label: Text('WebDAV')),
                ButtonSegment(value: _SourceKind.opds, label: Text('OPDS')),
              ],
              selected: {_kind},
              onSelectionChanged: (selection) =>
                  setState(() => _kind = selection.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: _kind == _SourceKind.webdav
                    ? 'WebDAV directory URL'
                    : 'OPDS feed URL',
                border: const OutlineInputBorder(),
              ),
            ),
            if (_kind == _SourceKind.webdav) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _connecting ? null : _connect,
              child: _connecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Connect'),
            ),
            if (_connectError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _connectError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(child: _buildBookList()),
          ],
        ),
      ),
    );
  }

  Widget _buildBookList() {
    final books = _books;
    if (books == null) return const SizedBox.shrink();
    if (books.isEmpty) {
      return const Center(child: Text('No books found at this source.'));
    }
    return ListView.separated(
      itemCount: books.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final book = books[index];
        final downloading = _downloadingEntryId == book.id;
        return ListTile(
          title: Text(book.title),
          subtitle: book.author == null ? null : Text(book.author!),
          trailing: downloading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined),
          onTap: _downloadingEntryId == null
              ? () => _downloadAndReturn(book)
              : null,
        );
      },
    );
  }
}
