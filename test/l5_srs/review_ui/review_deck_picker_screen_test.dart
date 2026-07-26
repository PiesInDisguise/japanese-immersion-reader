import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/document_repository.dart';
import 'package:japanese_immersion_reader/app/services.dart';
import 'package:japanese_immersion_reader/core/db/database.dart';
import 'package:japanese_immersion_reader/l2_linguistics/dictionary/dictionary_repository.dart';
import 'package:japanese_immersion_reader/l2_linguistics/grammar/grammar_matcher.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/grammar_collection_repository.dart';
import 'package:japanese_immersion_reader/l4_mining/collection/word_collection_repository.dart';
import 'package:japanese_immersion_reader/l5_srs/review_ui/review_deck_picker_screen.dart';
import 'package:japanese_immersion_reader/l5_srs/review_ui/review_screen.dart';

import '../../l3_reader_ui/card_mode/card_mode_test_helpers.dart'
    show FakeSettingsRepository;

AppDatabase? _sharedInertDatabase;
AppDatabase _inertDatabase() => _sharedInertDatabase ??= AppDatabase();

class FakeDocumentRepository extends DocumentRepository {
  FakeDocumentRepository(this._documents) : super(_inertDatabase());

  final List<DocumentRow> _documents;

  @override
  Future<List<DocumentRow>> listDocuments() async => _documents;

  @override
  Future<String?> sentenceContent(String sentenceId) async => null;
}

/// Due counts are entirely test-controlled, keyed by book id. Also
/// overrides [latestSightingSentenceId] (always `null`) -- irrelevant to
/// this screen's own behavior, but the two tests that navigate into a real
/// [ReviewScreen] need `ReviewController.build()` to resolve without
/// touching a real, unmocked database.
class FakeWordCollectionRepository extends WordCollectionRepository {
  FakeWordCollectionRepository({this.allDue = const [], this.byWork = const {}})
    : super(_inertDatabase());

  final List<DueWord> allDue;
  final Map<String, List<DueWord>> byWork;

  @override
  Future<List<DueWord>> due({DateTime? now}) async => allDue;

  @override
  Future<List<DueWord>> dueForWork(String workId, {DateTime? now}) async =>
      byWork[workId] ?? const [];

  @override
  Future<String?> latestSightingSentenceId(String id) async => null;
}

class FakeGrammarCollectionRepository extends GrammarCollectionRepository {
  FakeGrammarCollectionRepository({
    this.allDue = const [],
    this.byWork = const {},
  }) : super(_inertDatabase());

  final List<DueGrammar> allDue;
  final Map<String, List<DueGrammar>> byWork;

  @override
  Future<List<DueGrammar>> due({DateTime? now}) async => allDue;

  @override
  Future<List<DueGrammar>> dueForWork(String workId, {DateTime? now}) async =>
      byWork[workId] ?? const [];

  @override
  Future<String?> latestSightingSentenceId(String id) async => null;
}

class FakeDictionaryRepository extends DictionaryRepository {
  FakeDictionaryRepository() : super(_inertDatabase());

  @override
  Future<List<DictionaryLookupHit>> lookup({
    required String dictForm,
    required String surfaceForm,
    String? reading,
  }) async => const [];
}

DocumentRow _row({required String id, required String title}) {
  final now = DateTime.utc(2026, 1, 1);
  return DocumentRow(
    id: id,
    title: title,
    sourceType: 'epub',
    addedAt: now,
    updatedAt: now,
  );
}

DueWord _dueWord(String id) => DueWord(
  id: id,
  dictForm: id,
  reading: id,
  senseIds: const [],
  due: DateTime.utc(2026, 1, 1),
);

/// Pumps [ReviewDeckPickerScreen] with the full provider-override set every
/// test here needs -- including the ones [ReviewController.build] itself
/// touches (`grammarDatabaseProvider`, `settingsRepositoryProvider`,
/// `dictionaryRepositoryProvider`), since two tests below tap all the way
/// through into a real [ReviewScreen]. Without these, that would reach
/// `grammarDatabaseProvider`'s real bundled-asset load via `rootBundle` --
/// the documented `testWidgets`+`rootBundle` hang -- even for tests that
/// never actually reach `ReviewScreen` (this screen's own `_load` never
/// touches those providers, so this is purely for the navigation tests'
/// benefit, applied everywhere for one consistent override list).
Future<void> _pumpPickerScreen(
  WidgetTester tester, {
  required List<DocumentRow> documents,
  FakeWordCollectionRepository? wordRepository,
  FakeGrammarCollectionRepository? grammarRepository,
  List<NavigatorObserver> navigatorObservers = const [],
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        documentRepositoryProvider.overrideWithValue(
          FakeDocumentRepository(documents),
        ),
        wordCollectionRepositoryProvider.overrideWithValue(
          wordRepository ?? FakeWordCollectionRepository(),
        ),
        grammarCollectionRepositoryProvider.overrideWithValue(
          grammarRepository ?? FakeGrammarCollectionRepository(),
        ),
        dictionaryRepositoryProvider.overrideWithValue(
          FakeDictionaryRepository(),
        ),
        grammarDatabaseProvider.overrideWith(
          (ref) async => GrammarMatcher(const []),
        ),
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
      ],
      child: MaterialApp(
        navigatorObservers: navigatorObservers,
        home: const ReviewDeckPickerScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('shows an "All" tile plus one tile per book', (tester) async {
    await _pumpPickerScreen(
      tester,
      documents: [
        _row(id: 'doc-1', title: 'First Book'),
        _row(id: 'doc-2', title: 'Second Book'),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('First Book'), findsOneWidget);
    expect(find.text('Second Book'), findsOneWidget);
  });

  testWidgets('the "All" tile\'s due count sums words and grammar points', (
    tester,
  ) async {
    await _pumpPickerScreen(
      tester,
      documents: const [],
      wordRepository: FakeWordCollectionRepository(
        allDue: [_dueWord('w1'), _dueWord('w2')],
      ),
      grammarRepository: FakeGrammarCollectionRepository(
        allDue: [
          DueGrammar(
            id: 'g1',
            grammarPointId: 'point-a',
            due: DateTime.utc(2026, 1, 1),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets(
    'a book tile shows its own dueForWork count, not the "All" count',
    (tester) async {
      await _pumpPickerScreen(
        tester,
        documents: [_row(id: 'doc-1', title: 'First Book')],
        wordRepository: FakeWordCollectionRepository(
          allDue: [_dueWord('w1'), _dueWord('w2'), _dueWord('w3')],
          byWork: {
            'doc-1': [_dueWord('w1')],
          },
        ),
      );
      await tester.pumpAndSettle();

      // "3" for All, "1" for the book -- not "3" for both.
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    },
  );

  testWidgets('a book with nothing due has no badge and can\'t be tapped', (
    tester,
  ) async {
    String? pushedRouteLabel;
    await _pumpPickerScreen(
      tester,
      documents: [_row(id: 'doc-1', title: 'Empty Book')],
      navigatorObservers: [
        _RouteNameRecorder((name) => pushedRouteLabel = name),
      ],
    );
    await tester.pumpAndSettle();

    // No due count anywhere for this book -- no badge text at all besides
    // the title.
    expect(find.text('0'), findsNothing);

    await tester.tap(find.text('Empty Book'));
    await tester.pumpAndSettle();

    // Tapping did nothing -- still on the picker screen, no ReviewScreen
    // pushed.
    expect(find.byType(ReviewDeckPickerScreen), findsOneWidget);
    expect(find.byType(ReviewScreen), findsNothing);
    expect(pushedRouteLabel, isNull);
  });

  testWidgets('tapping "All" opens the unscoped ReviewScreen', (tester) async {
    await _pumpPickerScreen(tester, documents: const []);
    await tester.pumpAndSettle();

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    final reviewScreen = tester.widget<ReviewScreen>(find.byType(ReviewScreen));
    expect(reviewScreen.workId, isNull);
  });

  testWidgets('tapping a book with due items opens ReviewScreen scoped to it', (
    tester,
  ) async {
    await _pumpPickerScreen(
      tester,
      documents: [_row(id: 'doc-1', title: 'First Book')],
      wordRepository: FakeWordCollectionRepository(
        byWork: {
          'doc-1': [_dueWord('w1')],
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('First Book'));
    await tester.pumpAndSettle();

    final reviewScreen = tester.widget<ReviewScreen>(find.byType(ReviewScreen));
    expect(reviewScreen.workId, 'doc-1');
    expect(reviewScreen.deckTitle, 'First Book');
  });
}

/// Records the name of whatever route gets pushed after the initial one --
/// used only to prove tapping a disabled tile pushes nothing at all.
class _RouteNameRecorder extends NavigatorObserver {
  _RouteNameRecorder(this.onPush);

  final ValueChanged<String?> onPush;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) onPush(route.settings.name);
  }
}
