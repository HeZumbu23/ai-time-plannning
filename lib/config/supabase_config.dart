/// Supabase-Verbindungsdaten.
///
/// Web: Key wird von docker-entrypoint.sh zur Laufzeit in main.dart.js injiziert
///      (Platzhalter SUPABASE_KEY_PLACEHOLDER wird ersetzt).
/// Android: Key wird per --dart-define beim Build eingebettet.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vnfkkujtkbgkqafbbipj.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
