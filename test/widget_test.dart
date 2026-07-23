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
  });
}
