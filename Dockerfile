# ---- Build-Stage: Flutter Web kompilieren ----
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

RUN git config --global --add safe.directory /app

COPY pubspec.yaml ./
COPY . .

RUN flutter create --platforms=web . \
 && flutter pub get \
 && flutter build web --release

# ---- Runtime-Stage: Nginx ----
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY docker-entrypoint.sh /usr/local/bin/

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
