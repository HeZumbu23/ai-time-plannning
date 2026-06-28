import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lade Config (sync für Android, dann async für Web)
  SupabaseConfig.init();

  // Warte auf async config load (z.B. config.json für Web)
  await SupabaseConfig.waitForConfig();

  if (!SupabaseConfig.isConfigured) {
    runApp(const _ConfigErrorApp());
    return;
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const PlannerApp());
}

/// Sichtbarer Hinweis, falls der Build ohne Publishable Key gestartet wurde
/// (Repository-Variable `SUPABASE_PUBLISHABLE_KEY` nicht gesetzt).
class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Kein Supabase Publishable Key im Build.\n\n'
              'CI: Repository-Variable SUPABASE_PUBLISHABLE_KEY setzen.\n'
              'Lokal: --dart-define=SUPABASE_PUBLISHABLE_KEY=<key>',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class PlannerApp extends StatelessWidget {
  const PlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO & Coaching',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D5AFE)),
        useMaterial3: true,
      ),
      // Kein Login: RLS ist deaktiviert, der Anon-Key greift direkt.
      home: const HomeShell(),
    );
  }
}
