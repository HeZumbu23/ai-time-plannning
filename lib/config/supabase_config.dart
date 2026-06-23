/// Supabase-Verbindungsdaten.
///
/// Der Anon-/Publishable-Key ist ein öffentlicher Client-Key und darf im
/// Frontend liegen — der eigentliche Schutz kommt aus den RLS-Policies.
///
/// Für Builds kann der Key auch via `--dart-define` überschrieben werden:
///   flutter run --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vnfkkujtkbgkqafbbipj.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZuZmtrdWp0a2Jna3FhZmJiaXBqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE1MTE2NzMsImV4cCI6MjA5NzA4NzY3M30.gQpRg1glkR4EKxqYgXT1yvEhpwkPlF-bLctfvH4s6IQ',
  );
}
