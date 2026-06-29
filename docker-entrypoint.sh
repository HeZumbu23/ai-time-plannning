#!/bin/sh

if [ -n "$SUPABASE_PUBLISHABLE_KEY" ]; then
  sed -i "s|SUPABASE_KEY_PLACEHOLDER|${SUPABASE_PUBLISHABLE_KEY}|g" \
    /usr/share/nginx/html/main.dart.js
fi

exec nginx -g "daemon off;"
