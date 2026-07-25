import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/settings_repository.dart';
import 'package:japanese_immersion_reader/core/ids/stable_id.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/card_mode_screen.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/token_gloss_view.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/word_lookup_sheet.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/document_mode/document_mode_controller.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/document_mode/document_mode_screen.dart';

import '../card_mode/card_mode_test_helpers.dart';

void main() {
  // Every token in a Document Mode sentence row carries onTap, onDoubleTap,
  // *and* onLongPress on the same GestureDetector (see
  // `document_mode_screen.dart`'s own rationale on `_SentenceRowView`).
  // Flutter's gesture arena won't fire a lone `onTap` until it's sure a
  // second tap isn't coming, i.e. until `kDoubleTapTimeout` (300ms) has
  // elapsed with no follow-up tap -- so any test exercising a *single* tap
  // must pump past that window before asserting on its effect.
  const doubleTapTimeout = Duration(milliseconds: 300);

  late FakeTokenizer tokenizer;
  late FakeDictionaryRepository dictionaryRepository;
  late FakeWordCollectionRepository wordCollectionRepository;

  setUp(() {
    tokenizer = buildTestTokenizer();
    dictionaryRepository = FakeDictionaryRepository({
      '猫': [buildCatLookupHit()],
    });
    wordCollectionRepository = FakeWordCollectionRepository();
  });

  Future<void> pumpScreen(WidgetTester tester) => pumpDocumentModeScreen(
    tester,
    document: buildTestDocument(),
    tokenizer: tokenizer,
    dictionaryRepository: dictionaryRepository,
    wordCollectionRepository: wordCollectionRepository,
  );

  group('loading and error states', () {
    testWidgets('shows a graceful error view when no document is loaded', (
      tester,
    ) async {
      await pumpDocumentModeScreen(
        tester,
        tokenizer: tokenizer,
        dictionaryRepository: dictionaryRepository,
        wordCollectionRepository: wordCollectionRepository,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text("Couldn't load this document"), findsOneWidget);
      expect(find.textContaining('no document loaded'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    });
  });

  group('rendering', () {
    testWidgets('renders real tokens for multiple sentences at once', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('Chapter 1'), findsOneWidget);
      // Unlike Card Mode's one-card-at-a-time view, every sentence in the
      // (short, test) document is tokenized and on screen simultaneously.
      expect(find.text('猫'), findsOneWidget);
      expect(find.text('犬'), findsOneWidget);
      expect(find.text('鳥'), findsOneWidget);
    });
  });

  group('word lookup and mining', () {
    testWidgets(
      'tapping a token opens the lookup popup, and mining shows an undo '
      'affordance that works',
      (tester) async {
        await pumpScreen(tester);
        await tester.pumpAndSettle();

        await tester.tap(find.text('猫'));
        await tester.pump(doubleTapTimeout);
        await tester.pumpAndSettle();

        expect(find.byType(WordLookupSheet), findsOneWidget);
        expect(dictionaryRepository.lookupCalls, ['猫']);
        expect(find.textContaining('cat; feline'), findsOneWidget);

        await tester.tap(
          find.widgetWithText(FilledButton, 'Add to Collection'),
        );
        // Bounded pumps only from here: the SnackBar this triggers
        // auto-dismisses after several seconds, and `pumpAndSettle` would
        // fast-forward straight through that (virtual-clock) dismissal,
        // making the Undo action disappear before this test can tap it --
        // mirrors `card_mode_screen_test.dart`'s own reasoning.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(WordLookupSheet), findsNothing);
        expect(wordCollectionRepository.mineCalls, hasLength(1));
        expect(wordCollectionRepository.mineCalls.single.dictForm, '猫');
        expect(wordCollectionRepository.mineCalls.single.reading, 'ネコ');
        expect(wordCollectionRepository.mineCalls.single.senseIds, [1]);
        expect(find.text('Undo'), findsOneWidget);

        await tester.tap(find.text('Undo'));
        await tester.pump();

        expect(wordCollectionRepository.undoCalls, hasLength(1));
        expect(wordCollectionRepository.undoCalls.single.entryId, '猫|ネコ');
      },
    );
  });

  group('long-press remove', () {
    testWidgets('long-pressing a token removes it from the collection', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      await tester.longPress(find.text('猫'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(wordCollectionRepository.removeCalls, hasLength(1));
      expect(wordCollectionRepository.removeCalls.single.dictForm, '猫');
      expect(wordCollectionRepository.removeCalls.single.reading, 'ネコ');
      expect(find.textContaining('Removed'), findsOneWidget);
    });
  });

  group('grammar breakdown popup', () {
    testWidgets(
      'double-tapping a token opens a grammar breakdown of its containing '
      'sentence, as a popup',
      (tester) async {
        await pumpScreen(tester);
        await tester.pumpAndSettle();

        // Simulate a double tap: two quick taps at the same location, well
        // within kDoubleTapTimeout of each other.
        await tester.tap(find.text('走る'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('走る'));
        await tester.pumpAndSettle();

        expect(find.byType(TokenGlossView), findsOneWidget);
        // 走る's own inflection field...
        expect(find.text('五段-ラ行;終止形-一般'), findsOneWidget);
        // ...and proof this is the *containing sentence's* full breakdown,
        // not just the double-tapped token: 猫's reading, which appears
        // nowhere else on screen (the document list behind the popup shows
        // only surface text).
        expect(find.text('ネコ'), findsOneWidget);

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        expect(find.byType(TokenGlossView), findsNothing);
      },
    );
  });

  group('word highlighting', () {
    testWidgets(
      'a collected word is highlighted with the default color; an '
      'uncollected word is not',
      (tester) async {
        await pumpScreen(tester);
        await tester.pumpAndSettle();

        wordCollectionRepository.emitCollectedWordIds({
          contentDerivedWordId(dictForm: '猫', reading: 'ネコ'),
        });
        await tester.pumpAndSettle();

        final catBox = tester.widget<DecoratedBox>(
          find
              .ancestor(of: find.text('猫'), matching: find.byType(DecoratedBox))
              .first,
        );
        expect(
          (catBox.decoration as BoxDecoration).color,
          defaultHighlightColor,
        );

        final dogBox = tester.widget<DecoratedBox>(
          find
              .ancestor(of: find.text('犬'), matching: find.byType(DecoratedBox))
              .first,
        );
        expect(
          (dogBox.decoration as BoxDecoration).color,
          Colors.transparent,
        );
      },
    );

    testWidgets('highlight uses the Settings-configured color, not a '
        'hardcoded default', (tester) async {
      const customColor = Color(0xFF3388CC);
      final settingsRepository = FakeSettingsRepository(
        const AppSettings(
          llmApiKey: null,
          llmExplanationsEnabled: true,
          ttsEnabled: false,
          pitchAccentAudioEnabled: false,
          highlightColor: customColor,
        ),
      );
      await pumpDocumentModeScreen(
        tester,
        document: buildTestDocument(),
        tokenizer: tokenizer,
        dictionaryRepository: dictionaryRepository,
        wordCollectionRepository: wordCollectionRepository,
        settingsRepository: settingsRepository,
      );
      await tester.pumpAndSettle();

      wordCollectionRepository.emitCollectedWordIds({
        contentDerivedWordId(dictForm: '猫', reading: 'ネコ'),
      });
      await tester.pumpAndSettle();

      final catBox = tester.widget<DecoratedBox>(
        find
            .ancestor(of: find.text('猫'), matching: find.byType(DecoratedBox))
            .first,
      );
      expect((catBox.decoration as BoxDecoration).color, customColor);
    });
  });

  group('mode switching', () {
    testWidgets('the Document Mode switch button navigates to Card Mode', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Switch to Card Mode'));
      await tester.pumpAndSettle();

      expect(find.byType(CardModeScreen), findsOneWidget);
      expect(find.byType(DocumentModeScreen), findsNothing);
    });

    testWidgets('the Card Mode switch button navigates to Document Mode', (
      tester,
    ) async {
      await pumpCardModeScreen(
        tester,
        document: buildTestDocument(),
        tokenizer: tokenizer,
        dictionaryRepository: dictionaryRepository,
        wordCollectionRepository: wordCollectionRepository,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Switch to Document Mode'));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentModeScreen), findsOneWidget);
      expect(find.byType(CardModeScreen), findsNothing);
    });
  });

  group('reading position sync (spec §5)', () {
    testWidgets(
      'switching to Card Mode resumes at whatever sentence Document Mode '
      'last reported as visible, not always the first card',
      (tester) async {
        await pumpScreen(tester);
        await tester.pumpAndSettle();

        // Bypasses real scroll-gesture simulation (which would depend on the
        // real test viewport size actually being small enough to need
        // scrolling for this short document) and instead calls the same
        // method `_DocumentModeBodyState._handleScroll` calls, to test the
        // actual cross-controller contract this session's work exists for:
        // does writing here really get read back correctly by
        // CardModeController.build() on the other side of a mode switch.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(DocumentModeScreen)),
        );
        container
            .read(documentModeControllerProvider.notifier)
            .reportVisibleSentence('sent-2');

        await tester.tap(find.byTooltip('Switch to Card Mode'));
        await tester.pumpAndSettle();

        expect(find.byType(CardModeScreen), findsOneWidget);
        // buildTestDocument's sentences are sent-0/sent-1/sent-2 in order,
        // so sent-2 is card index 2 -- "Card 3 of 3", not "Card 1 of 3".
        expect(find.text('Card 3 of 3'), findsOneWidget);
      },
    );
  });
}
