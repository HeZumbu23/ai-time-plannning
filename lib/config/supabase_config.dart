/// Supabase-Verbindungsdaten.
///
/// Der Anon-/Publishable-Key wird **nicht** im Code eingecheckt, sondern beim
/// Build per `--dart-define` (bzw. CI-Secret / Docker build-arg) injiziert:
///
///   flutter run -d chrome --dart-define=SUPABASE_ANON_KEY=...
///
/// Alternativ gebündelt aus einer (gitignorierten) Datei:
///   flutter run --dart-define-from-file=dart_defines.json
///
/// Hinweis: In einer Client-App landet der Key am Ende ohnehin sichtbar im
/// ausgelieferten Bundle – der eigentliche Schutz muss über RLS kommen.
/// Das Auslagern hier verhindert nur, dass der Key im Git-Repo liegt.
class SupabaseConfig {
  SupabaseConfig._();

  /// Die Projekt-URL ist nicht geheim und darf einen Default haben.
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vnfkkujtkbgkqafbbipj.supabase.co',
  );

  /// Kein Default – muss zur Build-Zeit gesetzt werden.
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
