import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';

import 'config/supabase_client.dart';
import 'router.dart';
import 'services/auth_notifier.dart';
import 'services/key_storage.dart';
import 'services/session_storage.dart';

const _supabaseUrl = 'https://vnfkkujtkbgkqafbbipj.supabase.co';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web/Docker: compile-time key (replaced by sed at container start).
  var key = const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  // Android/runtime: key stored in SharedPreferences (entered via setup screen).
  if (key.isEmpty) {
    key = await KeyStorage.loadKey() ?? '';
  }

  if (key.isNotEmpty) {
    final client = SupabaseClient(
      _supabaseUrl,
      key,
      authOptions: AuthClientOptions(localStorage: SharedPrefsSessionStorage()),
    );
    initSupabaseClient(client);
    authNotifier.attach(client);
  }

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ai-time-plannning',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D5AFE)),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
