#!/bin/sh

echo "=== Starting AI Time Planning ==="
echo "Supabase URL: ${SUPABASE_URL:-https://vnfkkujtkbgkqafbbipj.supabase.co}"
echo "Supabase Key: ${SUPABASE_PUBLISHABLE_KEY:-(empty)}"

# Generiere config.json
cat > /usr/share/nginx/html/config.json << JSONEOF
{
  "supabaseUrl": "${SUPABASE_URL:-https://vnfkkujtkbgkqafbbipj.supabase.co}",
  "supabaseAnonKey": "${SUPABASE_PUBLISHABLE_KEY}"
}
JSONEOF

echo ""
echo "=== config.json generated ==="
cat /usr/share/nginx/html/config.json
echo ""
echo "=== Starting Nginx ==="

# Starte nginx
exec nginx -g "daemon off;"
