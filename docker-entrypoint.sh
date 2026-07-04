#!/bin/sh

if [ -n "$SUPABASE_PUBLISHABLE_KEY" ]; then
  sed -i "s|SUPABASE_KEY_PLACEHOLDER|${SUPABASE_PUBLISHABLE_KEY}|g" \
    /usr/share/nginx/html/main.dart.js

  # Start QR trigger server on port 8081.
  # A GET /api/log-qr (from the Android app) causes qrencode to print
  # the Supabase key as an ASCII QR code to container stdout (Portainer logs).
  export QR_KEY="$SUPABASE_PUBLISHABLE_KEY"
  socat TCP-LISTEN:8081,fork,reuseaddr EXEC:/usr/local/bin/qr-trigger.sh &
fi

# Führe Datenbank-Migrationen aus (falls SUPABASE_POSTGRES_PASSWORD gesetzt)
if [ -n "$SUPABASE_POSTGRES_PASSWORD" ]; then
  sh /app/scripts/run-migrations.sh || {
    echo "⚠️  Migrations-Fehler, aber fahre mit App-Start fort..."
  }
else
  echo "⚠️  SUPABASE_POSTGRES_PASSWORD nicht gesetzt - Migrationen werden übersprungen"
  echo "    → Setze die Variable zum automatischen Ausführen von Migrationen"
fi

exec nginx -g "daemon off;"
