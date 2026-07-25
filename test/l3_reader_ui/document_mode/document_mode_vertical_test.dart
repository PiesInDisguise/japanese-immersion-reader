import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/app/settings_repository.dart';
import 'package:japanese_immersion_reader/core/ids/stable_id.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/token_gloss_view.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/card_mode/word_lookup_sheet.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/vertical_text/render_vertical_text.dart';
import 'package:japanese_immersion_reader/l3_reader_ui/vertical_text/vertical_text.dart';

import '../card_mode/card_mode_test_helpers.dart';

/// Document Mode's *vertical*-block rendering path
/// (`_SentenceRowView`/`VerticalSentenceView`), exercised separately from
/// `document_mode_screen_test.dart`'s all-horizontal suite. Unlike the
/// horizontal case (one `Text` widget per token, so tests can just
/// `find.text('猫')`), `VerticalTextView` paints every character itself in a
/// single leaf render object with no per-character widgets at all -- so
/// every gesture here has to target a computed screen *position* instead of
/// a `Finder`, the same way `vertical_text_view_test.dart` itself does.
void main() {
  // Matches VerticalSentenceView's current defaults (fontSize 20, 1.5x
  // factors -- see that class's doc comment for why 1.5 specifically:
  // exactly representable as a double, so this cell size is exact, not a
  // rounded approximation). 30x30 cells.
  const cell = 30.0;

  // Same arena-wide delay `document_mode_screen_test.dart` documents for the
  // horizontal case applies here too, for the same reason (see
  // VerticalSentenceView's own "gesture layering" doc comment): a
  // DoubleTapGestureRecognizer anywhere in the arena -- here, on the
  // GestureDetector VerticalSentenceView wraps around VerticalTextView --
  // holds a lone tap's resolution open until this timeout elapses.
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
    document: buildVerticalTestDocument(),
    tokenizer: tokenizer,
    dictionaryRepository: dictionaryRepository,
    wordCollectionRepository: wordCollectionRepository,
  );

  /// The screen center of character [charIndex] of whichever sentence row
  /// is keyed by [sentenceId] -- '猫が走る。' (5 characters: 猫,が,走,る,。)
  /// wraps into a single column at these defaults, with characters running
  /// top-to-bottom, so `charIndex` also equals that character's row.
  Offset centerOfChar(WidgetTester tester, String sentenceId, int charIndex) {
    final topLeft = tester.getTopLeft(
      find.descendant(
        of: find.byKey(ValueKey(sentenceId)),
        matching: find.byType(VerticalTextView),
      ),
    );
    return topLeft + Offset(cell / 2, charIndex * cell + cell / 2);
  }

  group('renders via the vertical widget, not the horizontal Wrap', () {
    testWidgets('a vertical block renders VerticalTextView for its rows', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      final sentenceFinder = find.byKey(const ValueKey('sent-v-0'));
      expect(sentenceFinder, findsOneWidget);
      expect(
        find.descendant(
          of: sentenceFinder,
          matching: find.byType(VerticalTextView),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sentenceFinder, matching: find.byType(Wrap)),
        findsNothing,
      );
    });
  });

  group('word lookup and mining', () {
    testWidgets('tapping a token opens the lookup popup for that token', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      // charIndex 0 is 猫, the sentence's first character.
      final tapPosition = centerOfChar(tester, 'sent-v-0', 0);
      await tester.tapAt(tapPosition);
      await tester.pump(doubleTapTimeout);
      await tester.pumpAndSettle();

      expect(find.byType(WordLookupSheet), findsOneWidget);
      expect(dictionaryRepository.lookupCalls, ['猫']);
      expect(find.textContaining('cat; feline'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Add to Collection'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(wordCollectionRepository.mineCalls, hasLength(1));
      expect(wordCollectionRepository.mineCalls.single.dictForm, '猫');
      expect(wordCollectionRepository.mineCalls.single.reading, 'ネコ');
    });
  });

  group('long-press remove', () {
    testWidgets('long-pressing a token removes it from the collection', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      final longPressPosition = centerOfChar(tester, 'sent-v-0', 0); // 猫
      await tester.longPressAt(longPressPosition);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(wordCollectionRepository.removeCalls, hasLength(1));
      expect(wordCollectionRepository.removeCalls.single.dictForm, '猫');
      expect(wordCollectionRepository.removeCalls.single.reading, 'ネコ');
      expect(find.textContaining('Removed'), findsOneWidget);
    });
  });

  group('word highlighting', () {
    testWidgets(
      'a collected word\'s char span is highlighted with the '
      'Settings-configured color',
      (tester) async {
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
          document: buildVerticalTestDocument(),
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

        final renderObject = tester.renderObject<RenderVerticalText>(
          find.descendant(
            of: find.byKey(const ValueKey('sent-v-0')),
            matching: find.byType(RawVerticalText),
          ),
        );
        // '猫が走る。': 猫 is charIndex 0 only.
        expect(renderObject.highlightedCharIndices, {0});
        expect(renderObject.highlightColor, customColor);
      },
    );
  });

  group('grammar breakdown popup', () {
    testWidgets(
      'double-tapping anywhere in the sentence opens a grammar breakdown '
      'of the whole containing sentence',
      (tester) async {
        await pumpScreen(tester);
        await tester.pumpAndSettle();

        // charIndex 2 sits inside 走る (charIndices 2-3), not on 猫 -- proof
        // the resulting breakdown is sentence-wide, not just this token.
        final tapPosition = centerOfChar(tester, 'sent-v-0', 2);
        await tester.tapAt(tapPosition);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tapAt(tapPosition);
        await tester.pumpAndSettle();

        expect(find.byType(TokenGlossView), findsOneWidget);
        // 走る's own inflection field...
        expect(find.text('五段-ラ行;終止形-一般'), findsOneWidget);
        // ...and proof this is the *containing sentence's* full breakdown,
        // not just the double-tapped token: 猫's reading, which appears
        // nowhere else on screen (the document list behind the popup shows
        // only painted glyphs, no separate reading text).
        expect(find.text('ネコ'), findsOneWidget);
        // Not the lookup popup -- a double-tap must not also register as a
        // per-character tap.
        expect(find.byType(WordLookupSheet), findsNothing);

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        expect(find.byType(TokenGlossView), findsNothing);
      },
    );
  });
}
