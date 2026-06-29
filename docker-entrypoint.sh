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

exec nginx -g "daemon off;"
