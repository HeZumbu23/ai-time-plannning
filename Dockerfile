# ---- Build-Stage: Flutter Web kompilieren ----
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Git-Sicherheitscheck im Container abschalten
RUN git config --global --add safe.directory /app

# Erst nur pubspec für besseres Layer-Caching
COPY pubspec.yaml ./
COPY . .

# Web-Scaffold ergänzen, Dependencies holen, Release-Build
RUN flutter create --platforms=web . \
 && flutter pub get \
 && flutter build web --release

# ---- Runtime-Stage: statisch via nginx ausliefern ----
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
