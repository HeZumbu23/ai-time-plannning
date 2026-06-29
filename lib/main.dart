import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';

import 'config/supabase_client.dart';
import 'router.dart';

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
