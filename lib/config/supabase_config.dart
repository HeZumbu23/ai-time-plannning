import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:js_interop';

/// Supabase-Verbindungsdaten.
///
/// Werden zur Runtime von config.js gelesen (injiziert vom docker-entrypoint.sh).
/// Das ermöglicht, die Umgebungsvariablen im Portainer zu konfigurieren.
class SupabaseConfig {
  SupabaseConfig._();

  static late final String url;
  static late final String anonKey;

  /// Initialisierung: Lese Config von window.appConfig (aus config.js)
  static void init() {
    final config = _getWindowConfig();
    url = config['supabaseUrl'] ?? 'https://vnfkkujtkbgkqafbbipj.supabase.co';
    anonKey = config['supabaseAnonKey'] ?? '';
  }

  static Map<String, String> _getWindowConfig() {
    try {
      final jsConfig = _getAppConfig();
      return {
        'supabaseUrl': jsConfig.supabaseUrl ?? '',
        'supabaseAnonKey': jsConfig.supabaseAnonKey ?? '',
      };
    } catch (e) {
      print('Fehler beim Lesen von config.js: $e');
      return {};
    }
  }

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

@JS('window.appConfig')
external AppConfig _getAppConfig();

@JS()
@staticInterop
class AppConfig {
  external String? get supabaseUrl;
  external String? get supabaseAnonKey;
}
