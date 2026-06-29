import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = 'https://vnfkkujtkbgkqafbbipj.supabase.co';
const _supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseKey.isNotEmpty) {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseKey);
  }

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
        body: Center(
          child: Text(
            _supabaseKey.isNotEmpty
                ? 'Supabase verbunden ✓'
                : 'Kein Key konfiguriert',
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
