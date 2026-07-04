#!/bin/sh

# Migrationen automatisch ausführen
# Umgebungsvariablen erforderlich: SUPABASE_URL, SUPABASE_POSTGRES_PASSWORD

SUPABASE_URL="${SUPABASE_URL:-https://vnfkkujtkbgkqafbbipj.supabase.co}"
SUPABASE_POSTGRES_PASSWORD="${SUPABASE_POSTGRES_PASSWORD}"

if [ -z "$SUPABASE_POSTGRES_PASSWORD" ]; then
  echo "⚠️  SUPABASE_POSTGRES_PASSWORD nicht gesetzt - Migrationen werden übersprungen"
  exit 0
fi

# Extrahiere Project-ID aus URL
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

echo "🚀 Starte Datenbank-Migrationen..."

MIGRATIONS_DIR="$(dirname "$0")/../supabase/migrations"

# Stelle sicher, dass die Migrations-Tabelle existiert
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" <<EOF 2>/dev/null
CREATE TABLE IF NOT EXISTS public._migrations (
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
EOF

if [ $? -ne 0 ]; then
  echo "⚠️  Konnte Migrations-Tabelle nicht erstellen"
fi

EXECUTED_COUNT=0

# Sortierte Migrationen ausführen
for migration_file in $(find "$MIGRATIONS_DIR" -name '*.sql' -type f | sort); do
  filename=$(basename "$migration_file")

  # Prüfe, ob Migration bereits ausgeführt wurde
  already_run=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT 1 FROM public._migrations WHERE name = '$filename' LIMIT 1;" 2>/dev/null)

  if [ "$already_run" = " 1" ]; then
    echo "  ✓ $filename (bereits ausgeführt)"
    continue
  fi

  echo "  ⏳ $filename..."

  # Führe Migration aus
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$migration_file" >/dev/null 2>&1

  if [ $? -eq 0 ]; then
    # Markiere Migration als ausgeführt
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "INSERT INTO public._migrations (name) VALUES ('$filename');" >/dev/null 2>&1
    echo "  ✓ $filename"
    EXECUTED_COUNT=$((EXECUTED_COUNT + 1))
  else
    echo "  ✗ $filename FEHLER"
  fi
done

echo ""
echo "✅ $EXECUTED_COUNT neue Migration(en) ausgeführt"

