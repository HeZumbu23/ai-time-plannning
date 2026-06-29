# ---- Build-Stage: Flutter Web kompilieren ----
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

RUN git config --global --add safe.directory /app

COPY pubspec.yaml ./
COPY . .

RUN flutter create --platforms=web . \
 && flutter pub get \
 && flutter build web --release --pwa-strategy=none \
     --dart-define=SUPABASE_PUBLISHABLE_KEY=SUPABASE_KEY_PLACEHOLDER

# ---- Runtime-Stage: Nginx ----
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
