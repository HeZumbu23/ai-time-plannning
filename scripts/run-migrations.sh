#!/bin/sh

set -e

SUPABASE_URL="${SUPABASE_URL:-https://vnfkkujtkbgkqafbbipj.supabase.co}"
SUPABASE_POSTGRES_PASSWORD="${SUPABASE_POSTGRES_PASSWORD}"

echo "🔧 Migrations-Setup:"
echo "  SUPABASE_URL: $SUPABASE_URL"

if [ -z "$SUPABASE_POSTGRES_PASSWORD" ]; then
  echo "⚠️  SUPABASE_POSTGRES_PASSWORD nicht gesetzt - Migrationen werden übersprungen"
  echo "    → Bitte Umgebungsvariable setzen: export SUPABASE_POSTGRES_PASSWORD='...'"
  exit 0
fi

# Extrahiere Project-ID
PROJECT_ID=$(echo "$SUPABASE_URL" | sed -E 's|https://([^.]+)\.supabase\.co.*|\1|')

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Konnte Project-ID aus SUPABASE_URL nicht extrahieren"
  exit 1
fi

DB_HOST="${PROJECT_ID}.postgres.supabase.co"
DB_PORT="5432"
DB_USER="postgres"
DB_NAME="postgres"

export PGPASSWORD="$SUPABASE_POSTGRES_PASSWORD"

echo "  DB_HOST: $DB_HOST"
echo "  DB_USER: $DB_USER"
echo ""

# Teste Datenbankverbindung
echo "🔌 Teste Datenbankverbindung..."
if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" 2>/dev/null >/dev/null; then
  echo "❌ Kann keine Verbindung zur Datenbank herstellen"
  echo "   Host: $DB_HOST"
  echo "   User: $DB_USER"
  echo "   Prüfe das SUPABASE_POSTGRES_PASSWORD und die Netzwerkkonnektivität"
  exit 1
fi
echo "✓ Datenbankverbindung erfolgreich"
echo ""

echo "🚀 Starte Datenbank-Migrationen..."

MIGRATIONS_DIR="$(dirname "$0")/../supabase/migrations"

if [ ! -d "$MIGRATIONS_DIR" ]; then
  echo "❌ Migrations-Verzeichnis nicht gefunden: $MIGRATIONS_DIR"
  exit 1
fi

# Erstelle Migrations-Tabelle
echo "  → Erstelle Tracking-Tabelle..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" <<'EOSQL' 2>&1 | grep -v "already exists" || true
CREATE TABLE IF NOT EXISTS public._migrations (
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
EOSQL

EXECUTED_COUNT=0
SKIPPED_COUNT=0
FAILED_COUNT=0

# Sortierte Migrationen ausführen
for migration_file in $(find "$MIGRATIONS_DIR" -name '*.sql' -type f | sort); do
  filename=$(basename "$migration_file")

  # Prüfe, ob Migration bereits ausgeführt wurde
  already_run=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(1) FROM public._migrations WHERE name = '$filename';" 2>/dev/null | tr -d ' ')

  if [ "$already_run" -gt 0 ]; then
    echo "  ✓ $filename (bereits ausgeführt)"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    continue
  fi

  echo "  ⏳ $filename..."

  # Führe Migration aus
  if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$migration_file" 2>&1; then
    # Markiere Migration als ausgeführt
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "INSERT INTO public._migrations (name) VALUES ('$filename');" 2>/dev/null
    echo "  ✓ $filename"
    EXECUTED_COUNT=$((EXECUTED_COUNT + 1))
  else
    echo "  ✗ $filename FEHLER"
    FAILED_COUNT=$((FAILED_COUNT + 1))
  fi
done

echo ""
echo "📊 Migrations-Zusammenfassung:"
echo "  Neue Migrationen: $EXECUTED_COUNT"
echo "  Bereits ausgeführt: $SKIPPED_COUNT"
echo "  Fehler: $FAILED_COUNT"

if [ "$FAILED_COUNT" -gt 0 ]; then
  echo ""
  echo "⚠️  Einige Migrationen sind fehlgeschlagen!"
  exit 1
fi

echo ""
echo "✅ Migrations abgeschlossen"

