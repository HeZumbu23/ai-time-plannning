import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Supabase-Verbindungsdaten.
/// 
/// Web: Lädt config.json (generiert von docker-entrypoint.sh)
/// Android: Nutzt hardcoded Werte
class SupabaseConfig {
  SupabaseConfig._();

  static late final String url;
  static late final String anonKey;

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
      final response = await http.get(Uri.parse('/config.json'));
      if (response.statusCode == 200) {
        final config = jsonDecode(response.body);
        url = config['supabaseUrl'] ?? 'https://vnfkkujtkbgkqafbbipj.supabase.co';
        anonKey = config['supabaseAnonKey'] ?? '';
        print('✓ Config loaded: $url');
      } else {
        print('✗ Config not found (HTTP ${response.statusCode})');
      }
    } catch (e) {
      print('✗ Config load error: $e');
    }
  }

  static void _initNative() {
    // Android/iOS: hardcoded
    url = 'https://vnfkkujtkbgkqafbbipj.supabase.co';
    anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZuZmtrdWp0a2Jna3FhZmJiaXBqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDEwNjk5NzgsImV4cCI6MTczMjYwNTk3OH0.t5LjWrLqFB8VT-RNJRU6N6HwHPcLQy5STU1Y-Yj_TGo';
  }

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
