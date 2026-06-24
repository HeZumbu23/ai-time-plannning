import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_config.dart';

/// Effektive Supabase-Verbindungsdaten zur **Laufzeit**.
///
/// Reihenfolge der Auflösung:
///   1. Im Gerät gespeicherter Wert (per QR-Code / manuell eingegeben)
///   2. Build-Zeit-Default aus [SupabaseConfig] (dart-define)
///
/// Dadurch kann der Anon-Key auf einem Gerät bequem per QR gesetzt werden,
/// ohne dass er im (öffentlichen) Repo oder im Build landen muss.
class AppConfig {
  AppConfig._();

  static const _kUrl = 'supabase_url';
  static const _kAnonKey = 'supabase_anon_key';

  static String _url = SupabaseConfig.url;
  static String _anonKey = SupabaseConfig.anonKey;

  static String get url => _url;
  static String get anonKey => _anonKey;

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  /// Liest gespeicherte Werte und überschreibt damit die Build-Defaults.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUrl = prefs.getString(_kUrl);
    final storedKey = prefs.getString(_kAnonKey);
    if (storedUrl != null && storedUrl.isNotEmpty) _url = storedUrl;
    if (storedKey != null && storedKey.isNotEmpty) _anonKey = storedKey;
  }

  /// Speichert die Werte dauerhaft und aktualisiert den In-Memory-Cache.
  static Future<void> save({
    required String url,
    required String anonKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUrl, url);
    await prefs.setString(_kAnonKey, anonKey);
    _url = url;
    _anonKey = anonKey;
  }

  /// Setzt zurück auf die Build-Defaults (löscht den gespeicherten Key).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUrl);
    await prefs.remove(_kAnonKey);
    _url = SupabaseConfig.url;
    _anonKey = SupabaseConfig.anonKey;
  }

  /// Parst die per QR-Code gescannte (oder manuell eingefügte) JSON-Nutzlast.
  ///
  /// Erwartetes Format:
  /// ```json
  /// {"supabaseUrl": "https://xxxx.supabase.co", "supabaseAnonKey": "eyJ..."}
  /// ```
  /// Akzeptiert auch die Kurzschlüssel `url` und `anonKey`/`key`.
  /// Gibt `null` zurück, wenn der Inhalt kein gültiges Config-JSON ist.
  static ({String url, String anonKey})? parsePayload(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) return null;

      final url = (decoded['supabaseUrl'] ?? decoded['url'] ?? '')
          .toString()
          .trim();
      final anonKey =
          (decoded['supabaseAnonKey'] ?? decoded['anonKey'] ?? decoded['key'] ??
                  '')
              .toString()
              .trim();

      if (!url.startsWith('http') || anonKey.isEmpty) return null;
      return (url: url, anonKey: anonKey);
    } catch (_) {
      return null;
    }
  }
}
