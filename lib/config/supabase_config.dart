import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Supabase-Verbindungsdaten.
/// 
/// Web: Lädt config.json (generiert von docker-entrypoint.sh)
/// Android: Nutzt hardcoded Werte
class SupabaseConfig {
  SupabaseConfig._();

  static late String url;
  static late String anonKey;

  static void init() {
    if (kIsWeb) {
      _initWeb();
    } else {
      _initNative();
    }
  }

  /// Warte auf asynchrones Laden (z.B. config.json für Web)
  static Future<void> waitForConfig() async {
    if (kIsWeb) {
      await _loadWebConfig();
    }
  }

  static void _initWeb() {
    // Für Web: Setze Defaults, config.json wird später geladen
    url = 'https://vnfkkujtkbgkqafbbipj.supabase.co';
    anonKey = '';
  }

  static Future<void> _loadWebConfig() async {
    try {
      print('⏳ Loading config.json from server...');
      final uri = Uri.parse('/config.json');
      print('📍 Request URI: $uri');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('✗ Config request timeout');
          throw Exception('Config request timeout');
        },
      );

      print('📬 Response status: ${response.statusCode}');
      print('📬 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final config = jsonDecode(response.body);
        url = config['supabaseUrl'] ?? 'https://vnfkkujtkbgkqafbbipj.supabase.co';
        anonKey = config['supabaseAnonKey'] ?? '';
        print('✓ Config loaded: $url');
        print('✓ Anon key loaded: ${anonKey.isNotEmpty ? 'yes' : 'EMPTY'}');
      } else {
        print('✗ Config not found (HTTP ${response.statusCode})');
        print('✗ Response body: ${response.body}');
      }
    } catch (e, stack) {
      print('✗ Config load error: $e');
      print('✗ Stack trace: $stack');
    }
  }

  static void _initNative() {
    // Android/iOS: hardcoded
    url = 'https://vnfkkujtkbgkqafbbipj.supabase.co';
    anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZuZmtrdWp0a2Jna3FhZmJiaXBqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDEwNjk5NzgsImV4cCI6MTczMjYwNTk3OH0.t5LjWrLqFB8VT-RNJRU6N6HwHPcLQy5STU1Y-Yj_TGo';
  }

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
