import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';

import 'config/supabase_client.dart';
import 'screens/home_shell.dart';

const _supabaseUrl = 'https://vnfkkujtkbgkqafbbipj.supabase.co';
const _supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseKey.isNotEmpty) {
    initSupabaseClient(SupabaseClient(_supabaseUrl, _supabaseKey));
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
      home: _supabaseKey.isNotEmpty ? const HomeShell() : const _NoKeyScreen(),
    );
  }
}

class _NoKeyScreen extends StatelessWidget {
  const _NoKeyScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Kein Supabase Key konfiguriert.\n\n'
            'SUPABASE_PUBLISHABLE_KEY Umgebungsvariable in Portainer setzen.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
