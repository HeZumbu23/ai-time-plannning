#!/bin/sh

echo "=== Starting AI Time Planning ==="
echo "Supabase Key: ${SUPABASE_PUBLISHABLE_KEY:-(empty)}"

sed -i "s|SUPABASE_KEY_PLACEHOLDER_REPLACE_AT_RUNTIME|${SUPABASE_PUBLISHABLE_KEY}|g" \
  /usr/share/nginx/html/main.dart.js

echo "=== Key injected, Starting Nginx ==="

exec nginx -g "daemon off;"
