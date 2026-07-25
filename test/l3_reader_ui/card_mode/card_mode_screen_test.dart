import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/services.dart';
import 'package:japanese_immersion_reader/app/settings_repository.dart';
import 'package:japanese_immersion_reader/core/ids/stable_id.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/card_mode_controller.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/card_mode_screen.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/token_gloss_view.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/word_lookup_sheet.dart';

import 'card_mode_test_helpers.dart';

void main() {
  const cardArea = Key('cardModeCardArea');

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

  Future<void> pumpScreen(WidgetTester tester) => pumpCardModeScreen(
    tester,
    document: buildTestDocument(),
    tokenizer: tokenizer,
    dictionaryRepository: dictionaryRepository,
    wordCollectionRepository: wordCollectionRepository,
  );

  group('loading and error states', () {
    testWidgets('shows a loading indicator until the tokenizer resolves', (
      tester,
    ) async {
      final tokenizerCompleter = Completer<FakeTokenizer>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentDocumentProvider.overrideWith(
              () => FixedCurrentDocument(buildTestDocument()),
            ),
            tokenizerProvider.overrideWith((ref) => tokenizerCompleter.future),
            dictionaryRepositoryProvider.overrideWithValue(
              dictionaryRepository,
            ),
            wordCollectionRepositoryProvider.overrideWithValue(
              wordCollectionRepository,
            ),
          ],
          child: const MaterialApp(home: CardModeScreen()),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);

      tokenizerCompleter.complete(tokenizer);
      await tester.pumpAndSettle();

      expect(find.text('Card 1 of 3'), findsOneWidget);
    });

    testWidgets('shows a graceful error view when no document is loaded', (
      tester,
    ) async {
      await pumpCardModeScreen(
        tester,
        tokenizer: tokenizer,
        dictionaryRepository: dictionaryRepository,
        wordCollectionRepository: wordCollectionRepository,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text("Couldn't load this card"), findsOneWidget);
      expect(find.textContaining('no document loaded'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    });
  });

  group('swipe navigation', () {
    testWidgets(
      'swiping up advances, swiping down retreats, both no-op at the ends',
      (tester) async {
        await pumpScreen(tester);
        await tester.pumpAndSettle();

        expect(find.text('Card 1 of 3'), findsOneWidget);
        expect(find.text('猫'), findsOneWidget);

        await tester.drag(find.byKey(cardArea), const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(find.text('Card 2 of 3'), findsOneWidget);
        expect(find.text('犬'), findsOneWidget);

        await tester.drag(find.byKey(cardArea), const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(find.text('Card 3 of 3'), findsOneWidget);
        expect(find.text('鳥'), findsOneWidget);

        // At the last card: swiping up again must no-op (hasNext is false).
        await tester.drag(find.byKey(cardArea), const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(find.text('Card 3 of 3'), findsOneWidget);

        await tester.drag(find.byKey(cardArea), const Offset(0, 200));
        await tester.pumpAndSettle();
        expect(find.text('Card 2 of 3'), findsOneWidget);

        await tester.drag(find.byKey(cardArea), const Offset(0, 200));
        await tester.pumpAndSettle();
        expect(find.text('Card 1 of 3'), findsOneWidget);

        // At the first card: swiping down again must no-op (hasPrevious is
        // false).
        await tester.drag(find.byKey(cardArea), const Offset(0, 200));
        await tester.pumpAndSettle();
        expect(find.text('Card 1 of 3'), findsOneWidget);
      },
    );
  });

  group('word lookup popup', () {
    testWidgets('tapping a word triggers lookup and shows results', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('猫'));
      await tester.pumpAndSettle();

      expect(find.byType(WordLookupSheet), findsOneWidget);
      expect(dictionaryRepository.lookupCalls, ['猫']);
      expect(find.textContaining('cat; feline'), findsOneWidget);
      expect(find.text('ねこ'), findsOneWidget);
    });

    testWidgets(
      'shows a graceful empty state when there is no dictionary entry',
      (tester) async {
        await pumpScreen(tester);
        await tester.pumpAndSettle();

        // No fixture is registered for 走る in `dictionaryRepository`.
        await tester.tap(find.text('走る'));
        await tester.pumpAndSettle();

        expect(find.byType(WordLookupSheet), findsOneWidget);
        expect(
          find.textContaining('No dictionary entry found'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(FilledButton, 'Add to Collection'),
          findsOneWidget,
        );
      },
    );
  });

  group('mining and undo', () {
    testWidgets(
      "mining a word calls through to the controller and shows an undo "
      'affordance that works',
      (tester) async {
        await pumpScreen(tester);
        await tester.pumpAndSettle();

        await tester.tap(find.text('猫'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(FilledButton, 'Add to Collection'),
        );
        // Bounded pumps only from here: the SnackBar this triggers
        // auto-dismisses after several seconds, and `pumpAndSettle` would
        // fast-forward straight through that (virtual-clock) dismissal,
        // making the Undo action disappear before this test can tap it.
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
    testWidgets(
      'long-pressing a word removes it from the collection, any time',
      (tester) async {
        await pumpScreen(tester);
        await tester.pumpAndSettle();

        await tester.longPress(find.text('猫'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(wordCollectionRepository.removeCalls, hasLength(1));
        expect(wordCollectionRepository.removeCalls.single.dictForm, '猫');
        expect(wordCollectionRepository.removeCalls.single.reading, 'ネコ');
        expect(find.textContaining('Removed'), findsOneWidget);
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
              .ancestor(
                of: find.text('猫'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect(
          (catBox.decoration as BoxDecoration).color,
          defaultHighlightColor,
        );

        final particleBox = tester.widget<DecoratedBox>(
          find
              .ancestor(of: find.text('が'), matching: find.byType(DecoratedBox))
              .first,
        );
        expect(
          (particleBox.decoration as BoxDecoration).color,
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
      await pumpCardModeScreen(
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

  group('flip', () {
    testWidgets(
      'tapping empty card space flips to the token gloss, tapping again '
      'flips back',
      (tester) async {
        await pumpScreen(tester);
        await tester.pumpAndSettle();

        expect(find.byType(TokenGlossView), findsNothing);
        expect(find.text('猫'), findsOneWidget);

        final cardTopLeft = tester.getTopLeft(find.byKey(cardArea));
        await tester.tapAt(cardTopLeft + const Offset(16, 16));
        await tester.pumpAndSettle();

        expect(find.byType(TokenGlossView), findsOneWidget);
        expect(find.text('五段-ラ行;終止形-一般'), findsOneWidget);

        await tester.tapAt(cardTopLeft + const Offset(16, 16));
        await tester.pumpAndSettle();

        expect(find.byType(TokenGlossView), findsNothing);
        expect(find.text('猫'), findsOneWidget);
        expect(find.text('五段-ラ行;終止形-一般'), findsNothing);
      },
    );
  });
}
