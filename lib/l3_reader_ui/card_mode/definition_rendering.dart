import 'dart:convert';

/// Renders one [DictionaryTermEntry.definitionsJson] payload (a JSON-encoded
/// list of Yomitan definition variants -- see docs/research/r5-dictionary.md
/// §1) into plain display strings, one per array entry.
///
/// Yomitan's `term_bank` definitions array is heterogeneous by design: each
/// entry is *any* of a plain string, `{type: "text", text}`, `{type: "image",
/// ...}`, `{type: "structured-content", content}` (a recursive HTML-like
/// tree -- typically how monolingual dictionaries like 新明解 format richly
/// formatted entries), or a 2-tuple `[uninflectedTerm, ruleChain[]]`
/// cross-reference.
///
/// Renders plain-string, `{type: "text"}`, and `{type: "structured-content"}`
/// shapes as real text -- structured-content (JMdict's own Yomitan
/// conversion uses this pervasively, not just monolingual dictionaries, so
/// leaving it as a placeholder meant most real lookups showed no usable
/// definition at all) is flattened to plain text: every node's nested
/// `content` is walked recursively and concatenated, with list items
/// (`<li>`, the shape a glossary's array of senses takes) joined by "; ".
/// This deliberately discards structure (bullet nesting, styling, links) --
/// a real tag-tree-to-widgets renderer is still separate, later UI work --
/// but surfaces the actual glossary text rather than hiding it.
///
/// `{type: "image"}` still degrades to an honest, non-crashing placeholder
/// (rendering it needs the dictionary's own bundled image asset, which
/// isn't resolved anywhere yet) rather than being silently dropped or
/// dumped raw, so the popup still tells the user *something* was there for
/// that sense.
///
/// Never throws: malformed JSON, an unexpected top-level shape, or a
/// definitions-array entry with a wholly unrecognized shape all degrade to
/// a readable fallback string rather than crashing the popup calling this.
List<String> parseDefinitionEntries(String definitionsJson) {
  Object? decoded;
  try {
    decoded = jsonDecode(definitionsJson);
  } on FormatException {
    return [definitionsJson];
  }

  final entries = decoded is List ? decoded : [decoded];
  return [for (final entry in entries) _renderEntry(entry)];
}

String _renderEntry(Object? entry) {
  if (entry is String) return entry;

  if (entry is Map) {
    final type = entry['type'];
    if (type == 'text') {
      final text = entry['text'];
      if (text is String) return text;
      return '[Unsupported definition: "text" entry missing its text]';
    }
    if (type == 'image') {
      return '[Image definition -- not yet supported]';
    }
    if (type == 'structured-content') {
      final text = _renderStructuredContent(entry['content']).trim();
      return text.isEmpty
          ? '[Rich-content definition had no extractable text]'
          : text;
    }
    return '[Unsupported definition type: ${type ?? 'unknown'}]';
  }

  // A 2-tuple `[uninflectedTerm, ruleChain[]]` cross-reference, or any other
  // shape this pass doesn't specifically model -- fall back to raw JSON
  // rather than dropping it silently.
  return jsonEncode(entry);
}

/// Yomitan's structured-content node shape: a leaf string, a list of
/// sibling nodes, or `{tag, content, ...other attributes}` where `content`
/// recurses (the same three shapes at every level -- see
/// docs/research/r5-dictionary.md and the class doc comment above for a
/// concrete example). `tag`/`data`/`style`/`lang`/etc. are metadata this
/// plain-text rendering ignores; only `content` is ever walked.
String _renderStructuredContent(Object? node) {
  if (node == null) return '';
  if (node is String) return node;

  if (node is List) {
    final parts = node
        .map(_renderStructuredContent)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    return parts.join('; ');
  }

  if (node is Map) {
    return _renderStructuredContent(node['content']);
  }

  return '';
}
