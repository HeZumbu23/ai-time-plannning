/// Supabase-Verbindungsdaten.
///
/// Der Publishable-Key wird **nicht** im Code eingecheckt, sondern beim
/// Build per `--dart-define` (bzw. CI-Variable / Docker build-arg) injiziert:
///
///   flutter run -d chrome --dart-define=SUPABASE_PUBLISHABLE_KEY=...
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

  /// Kein Default – wird zur Build-Zeit gesetzt. Heißt SDK-seitig weiterhin
  /// `anonKey`, hält aber den modernen Publishable Key (`sb_publishable_…`).
  static const String anonKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
