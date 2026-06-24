import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'screens/config_qr_screen.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Gespeicherten (oder per Build injizierten) Key laden.
  await AppConfig.load();

  if (!AppConfig.isConfigured) {
    // Kein Key vorhanden -> Einrichtung per QR-Code / manueller Eingabe.
    runApp(const SetupApp());
    return;
  }

  await _initAndRun();
}

/// Initialisiert Supabase mit den aktuellen [AppConfig]-Werten und startet die App.
Future<void> _initAndRun() async {
  await Supabase.initialize(
    url: AppConfig.url,
    anonKey: AppConfig.anonKey,
  );
  runApp(const PlannerApp());
}

ThemeData _appTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D5AFE)),
      useMaterial3: true,
    );

/// Wird gezeigt, solange noch kein Supabase-Key konfiguriert ist.
class SetupApp extends StatelessWidget {
  const SetupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO & Coaching – Einrichtung',
      debugShowCheckedModeBanner: false,
      theme: _appTheme(),
      home: const _SetupScreen(),
    );
  }
}

class _SetupScreen extends StatelessWidget {
  const _SetupScreen();

  Future<void> _startSetup(BuildContext context) async {
    final result = await Navigator.of(context).push<({String url, String anonKey})>(
      MaterialPageRoute(builder: (_) => const ConfigQrScreen()),
    );
    if (result == null) return;

    await AppConfig.save(url: result.url, anonKey: result.anonKey);
    // Supabase wurde in diesem Pfad noch nicht initialisiert -> jetzt starten.
    await _initAndRun();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner, size: 64),
              const SizedBox(height: 16),
              Text(
                'Einrichtung',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Scanne den Supabase-Config-QR-Code, um die App mit dem '
                'Backend zu verbinden. Den QR erzeugst du am PC mit '
                'tools/make_config_qr.py.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _startSetup(context),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('QR-Code scannen'),
              ),
            ],
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
      theme: _appTheme(),
      // Kein Login: RLS ist deaktiviert, der Anon-Key greift direkt.
      home: const HomeShell(),
    );
  }
}
