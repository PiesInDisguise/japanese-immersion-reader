import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: JapaneseImmersionReaderApp()));
}

class JapaneseImmersionReaderApp extends StatelessWidget {
  const JapaneseImmersionReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Japanese Immersion Reader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const HomeScreen(),
    );
  }
}
