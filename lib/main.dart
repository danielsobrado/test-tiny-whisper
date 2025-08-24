import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const TinyWhisperTesterApp());
}

class TinyWhisperTesterApp extends StatelessWidget {
  const TinyWhisperTesterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tiny Whisper Tester',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}