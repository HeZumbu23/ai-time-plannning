# ---- Build-Stage: Flutter Web kompilieren ----
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

RUN git config --global --add safe.directory /app

COPY pubspec.yaml ./
COPY . .

RUN flutter create --platforms=web . \
 && flutter pub get \
 && flutter build web --debug --pwa-strategy=none --no-minify \
     --dart-define=SUPABASE_PUBLISHABLE_KEY=SUPABASE_KEY_PLACEHOLDER

# ---- Runtime-Stage: Nginx ----
FROM nginx:alpine

RUN apk add --no-cache socat python3 py3-pip \
    && pip3 install --no-cache-dir --break-system-packages qrcode

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY qr-trigger.sh /usr/local/bin/qr-trigger.sh

RUN chmod +x /docker-entrypoint.sh /usr/local/bin/qr-trigger.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
