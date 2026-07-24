import 'package:japanese_immersion_reader/core/db/database.dart';

/// Reads/writes the permanent-by-content cache for spec §8 layer 3 ("cached
/// permanently by sentence hash" -- explanations are never invalidated or
/// re-fetched once stored, since the same sentence+context text always
/// deserves the same explanation). Keyed by
/// `contentDerivedExplanationId`, computed by the caller
/// (`ReaderMiningSession`) so this repository stays a plain key/value store
/// with no opinion on what goes into the hash.
class ExplanationRepository {
  ExplanationRepository(this._db);

  final AppDatabase _db;

  Future<String?> read(String id) async {
    final row = await (_db.select(
      _db.sentenceExplanations,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
    return row?.explanation;
  }

  Future<void> write(String id, String explanation) {
    return _db
        .into(_db.sentenceExplanations)
        .insertOnConflictUpdate(
          SentenceExplanationsCompanion.insert(
            id: id,
            explanation: explanation,
            createdAt: DateTime.now(),
          ),
        );
  }
}
