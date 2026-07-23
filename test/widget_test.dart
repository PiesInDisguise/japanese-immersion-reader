import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_immersion_reader/main.dart';

void main() {
  testWidgets('app starts on the home screen with both load options', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: JapaneseImmersionReaderApp()),
    );

    expect(find.text('Load Sample Book'), findsOneWidget);
    expect(find.text('Import EPUB...'), findsOneWidget);
    // PdfTextImporter wiring (see home_screen.dart's _importPdf) and the
    // vertical-text manual-verification entry point (see
    // sample_content.dart's loadSampleVerticalPdf) -- this smoke test only
    // ever checks that the buttons render, the same as the two assertions
    // above; it doesn't drive a real file pick or import (that would need
    // FilePicker test infrastructure this suite doesn't have set up yet).
    expect(find.text('Import PDF...'), findsOneWidget);
    expect(find.text('Load Sample Vertical PDF'), findsOneWidget);
    // ScannedPdfImporter + RealOcrEngine wiring (see home_screen.dart's
    // _importScannedPdf) -- same render-only check as the others above.
    expect(find.text('Import Scanned PDF (OCR)...'), findsOneWidget);
  });
}
