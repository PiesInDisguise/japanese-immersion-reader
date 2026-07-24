import 'package:drift/drift.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';

import 'deinflector.dart';

/// Which tier of spec §10's lookup fallback chain produced a
/// [DictionaryLookupHit].
enum MatchTier { dictionaryForm, surfaceForm, deconjugation }

/// One matched dictionary entry, tagged with which installed dictionary it
/// came from (for priority ordering, and for the popup's "which dictionary
/// is this from" display) and which lookup tier produced it.
class DictionaryLookupHit {
  const DictionaryLookupHit({
    required this.term,
    required this.dictionaryId,
    required this.dictionaryTitle,
    required this.dictionaryPriority,
    required this.matchedVia,
  });

  final DictionaryTermEntry term;
  final String dictionaryId;
  final String dictionaryTitle;
  final int dictionaryPriority;
  final MatchTier matchedVia;
}

/// Implements spec §10's dictionary lookup: "keys on the dictionary form
/// from Sudachi, with fallback to surface form and a deconjugation retry."
///
/// Per docs/research/r5-dictionary.md §3, two things hold at every tier:
/// results are merged across **all enabled dictionaries** (not just the
/// first one with a hit -- the popup needs every installed dictionary's
/// entry for a term, not only the top-priority one, since other
/// dictionaries' entries are user-toggleable optional fields per spec §10),
/// and a tier is only "used" if it produces at least one hit; lower tiers
/// never run once an earlier tier succeeds.
class DictionaryRepository {
  DictionaryRepository(this._db);

  final AppDatabase _db;

  /// [dictForm]/[reading] should come from Sudachi's analysis of the tapped
  /// token (`Token.dictForm`/`Token.reading`); [surfaceForm] is the
  /// as-written text -- used both as tier-2's fallback key and as tier-3's
  /// deconjugation input, and the only thing available at all when the user
  /// drag-selects an arbitrary span Sudachi never tokenized (spec §10's
  /// "drag across characters" gesture).
  Future<List<DictionaryLookupHit>> lookup({
    required String dictForm,
    required String surfaceForm,
    String? reading,
  }) async {
    final byDictForm = await _queryAllEnabled(
      headword: dictForm,
      reading: reading,
    );
    if (byDictForm.isNotEmpty) {
      return _sortByPriority(byDictForm, MatchTier.dictionaryForm);
    }

    if (surfaceForm != dictForm) {
      final bySurfaceForm = await _queryAllEnabled(
        headword: surfaceForm,
        reading: reading,
      );
      if (bySurfaceForm.isNotEmpty) {
        return _sortByPriority(bySurfaceForm, MatchTier.surfaceForm);
      }
    }

    for (final candidate in Deinflector.deinflect(surfaceForm)) {
      final candidateHits = await _queryAllEnabled(
        headword: candidate.term,
        reading: null,
      );
      final validated = candidateHits
          .where(
            (row) => _rowRules(row).contains(candidate.rule.yomitanRuleTag),
          )
          .toList();
      if (validated.isNotEmpty) {
        return _sortByPriority(validated, MatchTier.deconjugation);
      }
    }

    return const [];
  }

  List<String> _rowRules(_MatchedRow row) =>
      row.term.rules.split(RegExp(r'\s+')).where((r) => r.isNotEmpty).toList();

  /// Matches spec/R5's tier semantics: gathers rows across every *enabled*
  /// dictionary for one match key. Deliberately two independently-indexed
  /// single-column queries (by `headword`, by `readingNormalized`) merged
  /// and de-duplicated in Dart, **not** one `headword = ? OR
  /// reading_normalized = ?` query -- see docs/research/r5-dictionary.md
  /// §2: SQLite won't reliably use two separate single-column indexes to
  /// satisfy one OR-ed WHERE clause the way a UNION of two independently
  /// indexed queries would, so the OR-ed form is avoided even though it
  /// would read more naturally.
  Future<List<_MatchedRow>> _queryAllEnabled({
    required String headword,
    required String? reading,
  }) async {
    final byHeadword = await _enabledTermsWhere(
      (terms) => terms.headword.equals(headword),
    );
    if (reading == null) return byHeadword;

    final byReading = await _enabledTermsWhere(
      (terms) => terms.readingNormalized.equals(reading),
    );

    final merged = <int, _MatchedRow>{
      for (final row in byHeadword) row.term.id: row,
    };
    for (final row in byReading) {
      merged.putIfAbsent(row.term.id, () => row);
    }
    return merged.values.toList();
  }

  Future<List<_MatchedRow>> _enabledTermsWhere(
    Expression<bool> Function($DictionaryTermEntriesTable terms) predicate,
  ) async {
    final query =
        _db.select(_db.dictionaryTermEntries).join([
            innerJoin(
              _db.dictionaries,
              _db.dictionaries.id.equalsExp(
                _db.dictionaryTermEntries.dictionaryId,
              ),
            ),
          ])
          ..where(predicate(_db.dictionaryTermEntries))
          ..where(_db.dictionaries.enabled.equals(true));

    final rows = await query.get();
    return [
      for (final row in rows)
        _MatchedRow(
          term: row.readTable(_db.dictionaryTermEntries),
          dictionary: row.readTable(_db.dictionaries),
        ),
    ];
  }

  /// Sort order: dictionary `priority` ascending (lower number = higher
  /// priority) first, then in-dictionary `score` descending (R5 §1:
  /// "negative=rarer, positive=commoner"), then `importOrder` ascending as
  /// the final tiebreaker so ties resolve to the dictionary author's own
  /// file order (see `DictionaryTermEntries.importOrder`'s doc comment).
  List<DictionaryLookupHit> _sortByPriority(
    List<_MatchedRow> rows,
    MatchTier tier,
  ) {
    final sorted = [...rows]
      ..sort((a, b) {
        final byPriority = a.dictionary.priority.compareTo(
          b.dictionary.priority,
        );
        if (byPriority != 0) return byPriority;
        final byScore = b.term.score.compareTo(a.term.score);
        if (byScore != 0) return byScore;
        return a.term.importOrder.compareTo(b.term.importOrder);
      });
    return [
      for (final row in sorted)
        DictionaryLookupHit(
          term: row.term,
          dictionaryId: row.dictionary.id,
          dictionaryTitle: row.dictionary.title,
          dictionaryPriority: row.dictionary.priority,
          matchedVia: tier,
        ),
    ];
  }

  /// Spec §14: "Dictionaries — installed list with priority ordering" --
  /// every installed dictionary, highest-priority (lowest [Dictionary.priority]
  /// value) first.
  Future<List<Dictionary>> listInstalled() {
    return (_db.select(
      _db.dictionaries,
    )..orderBy([(d) => OrderingTerm.asc(d.priority)])).get();
  }
}

class _MatchedRow {
  const _MatchedRow({required this.term, required this.dictionary});

  final DictionaryTermEntry term;
  final Dictionary dictionary;
}
