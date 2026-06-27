#!/bin/sh
set -e

# Generiere eine config.js mit den Umgebungsvariablen
cat > /usr/share/nginx/html/config.js << JSEOF
window.appConfig = {
  supabaseUrl: '${SUPABASE_URL:-https://vnfkkujtkbgkqafbbipj.supabase.co}',
  supabaseAnonKey: '${SUPABASE_PUBLISHABLE_KEY:-}'
};
JSEOF

echo "Config generated:"
cat /usr/share/nginx/html/config.js

# Starte nginx
exec nginx -g "daemon off;"
