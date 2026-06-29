import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';

const _supabaseUrl = 'https://vnfkkujtkbgkqafbbipj.supabase.co';
const _supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

// Globaler Client – wird in main() initialisiert wenn Key vorhanden
SupabaseClient? supabaseClient;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseKey.isNotEmpty) {
    supabaseClient = SupabaseClient(_supabaseUrl, _supabaseKey);
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
            supabaseClient != null
                ? 'Supabase Client bereit ✓'
                : 'Kein Key konfiguriert',
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
