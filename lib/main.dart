import 'package:flutter/material.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ai-time-plannning',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D5AFE)),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF3D5AFE),
          foregroundColor: Colors.white,
          title: const Text('ai-time-plannning'),
        ),
        body: const Center(
          child: Text(
            'Flutter Skeleton läuft ✓',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
