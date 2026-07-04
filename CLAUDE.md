# AI Time Planning - Projekt-Dokumentation

## Datenbank-Migrationen

**Wichtig:** Migrationen laufen automatisch bei jedem Docker-Container-Start!

### Wie funktioniert es?

1. **Migrations-Skript**: `scripts/run-migrations.sh` wird beim Container-Start ausgeführt (vor Nginx)
2. **SQL-Dateien**: Neue Migrations werden als `YYYYMMDDHHMMSS_description.sql` in `supabase/migrations/` angelegt
3. **Tracking**: Eine interne Tabelle `_migrations` trackt, welche Migrations bereits ausgeführt wurden

### Neue Migration hinzufügen

1. Erstelle eine neue SQL-Datei in `supabase/migrations/`:
   ```
   supabase/migrations/20260705120000_your_migration_name.sql
   ```

2. Schreibe das SQL (Beispiel):
   ```sql
   CREATE TABLE public.your_table (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   
   ALTER TABLE public.your_table ENABLE ROW LEVEL SECURITY;
   ```

3. Commit und Push - beim nächsten Deploy wird es automatisch ausgeführt!

### Umgebungsvariablen erforderlich

Für automatische Migrationen in Docker **MUSST du setzen**:
```bash
SUPABASE_POSTGRES_PASSWORD=dein_postgres_passwort
```

Wo du das findest:
1. Gehe zu https://app.supabase.com → Dein Projekt
2. Settings → Database → Connection Info
3. Kopiere das **Postgres-Passwort** (oder erstelle eines neu)
4. Setze es als Umgebungsvariable beim Container-Start:
   ```bash
   docker run -e SUPABASE_POSTGRES_PASSWORD="dein_passwort" ...
   ```

**Wichtig**: Ohne diese Variable werden Migrationen übersprungen!

Optional:
- `SUPABASE_URL`: Standard ist `https://vnfkkujtkbgkqafbbipj.supabase.co`
  (Überschreiben nur wenn anderes Projekt)

### Lokal testen

```bash
supabase start
# Migrations werden von Supabase CLI verwaltet
```

Oder manuell:
```bash
psql -h your-project.postgres.supabase.co -U postgres -d postgres -f supabase/migrations/your-file.sql
```

---

## Projekt-Setup

- **Frontend**: Flutter Web (auf Nginx)
- **Backend**: Supabase Cloud
- **Deployment**: Docker → Watchtower (auto-update)

## Watchtower-Setup

Die App updated sich selbst, wenn ein neues Docker-Image verfügbar ist. Keine manuellen Deployments nötig!
