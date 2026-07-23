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
/// This pass only renders the plain-string and `{type: "text"}` shapes as
/// real text -- the other shapes are real, separate UI work (a
/// structured-content renderer is a recursive tag-tree-to-widgets job, and
/// an image definition needs the dictionary's own bundled image asset;
/// neither exists yet). Those degrade to an honest, non-crashing placeholder
/// instead of being silently dropped or dumped raw, so the popup still
/// tells the user *something* was there for that sense.
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
      return '[Rich-content definition -- not yet supported]';
    }
    return '[Unsupported definition type: ${type ?? 'unknown'}]';
  }

  // A 2-tuple `[uninflectedTerm, ruleChain[]]` cross-reference, or any other
  // shape this pass doesn't specifically model -- fall back to raw JSON
  // rather than dropping it silently.
  return jsonEncode(entry);
}
