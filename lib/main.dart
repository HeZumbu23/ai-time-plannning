import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

import 'config/supabase_client.dart';
import 'router.dart';
import 'services/auth_notifier.dart';
import 'services/key_storage.dart';
import 'services/session_storage.dart';

const _supabaseUrl = 'https://vnfkkujtkbgkqafbbipj.supabase.co';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WebView platform for web
  if (kIsWeb) {
    try {
      await webviewFlutterWebPluginLibraryUnsafelyInitialize();
    } catch (_) {
      // Platform implementation already initialized
    }
  }

  // Web/Docker: compile-time key (replaced by sed at container start).
  var key = const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  // Android/runtime: key stored in SharedPreferences (entered via setup screen).
  if (key.isEmpty) {
    key = await KeyStorage.loadKey() ?? '';
  }

  if (key.isNotEmpty) {
    final client = SupabaseClient(_supabaseUrl, key);
    initSupabaseClient(client);
    authNotifier.attach(client);

    // Restore persisted session on Android after app restart.
    final savedSession = await SessionStorage.load();
    if (savedSession != null) {
      try {
        await client.auth.recoverSession(savedSession);
      } catch (_) {
        await SessionStorage.clear();
      }
    }

    // Persist session changes to SharedPreferences.
    client.auth.onAuthStateChange.listen((state) {
      if (state.session != null) {
        SessionStorage.save(state.session!);
      } else {
        SessionStorage.clear();
      }
    });
  }

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI Time Planning - Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D5AFE)),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
