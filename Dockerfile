# ---- Build-Stage: Flutter Web kompilieren ----
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

RUN git config --global --add safe.directory /app

COPY pubspec.yaml ./
COPY . .

RUN flutter create --platforms=web . \
 && flutter pub get \
 && flutter build web --debug --pwa-strategy=none \
     --dart-define=SUPABASE_PUBLISHABLE_KEY=SUPABASE_KEY_PLACEHOLDER

# ---- Runtime-Stage: Nginx ----
FROM nginx:alpine

RUN apk add --no-cache socat python3 py3-pip postgresql-client \
    && pip3 install --no-cache-dir --break-system-packages qrcode

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY qr-trigger.sh /usr/local/bin/qr-trigger.sh
COPY scripts /app/scripts
COPY supabase/migrations /app/supabase/migrations

RUN chmod +x /docker-entrypoint.sh /usr/local/bin/qr-trigger.sh /app/scripts/run-migrations.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
