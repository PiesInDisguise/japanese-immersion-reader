import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_theme.dart';
import 'app/home_screen.dart';
import 'app/services.dart';

void main() {
  runApp(const ProviderScope(child: JapaneseImmersionReaderApp()));
}

class JapaneseImmersionReaderApp extends ConsumerWidget {
  const JapaneseImmersionReaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value;

    return MaterialApp(
      title: 'Japanese Immersion Reader',
      theme: settings == null ? defaultAppTheme : buildAppTheme(settings),
      // App-wide font-size scaling (`AppSettings.fontScale`) -- applied here
      // via a `MediaQuery` override rather than per-widget, so every screen
      // gets it for free with no per-screen wiring.
      builder: (context, child) {
        final fontScale = settings?.fontScale ?? 1.0;
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(fontScale)),
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}
