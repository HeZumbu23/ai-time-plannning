# TODO & Coaching

Persönliches TODO- und Coaching-System als Flutter-App (Web + Android) mit
Supabase-Backend.

## Features (Stand)

- **Kein Login** – RLS ist deaktiviert, der Anon-Key greift direkt
- **Haupt-Navigation**: Tagesplan · Wochenplan · Backlog · Projekte
  (NavigationRail auf breiten Screens, NavigationBar auf schmalen)
- **Tagesplan**: Tasks für heute (`planned_day = today`) + offene Next Actions
- **Wochenplan**: Tasks der Kalenderwoche (`planned_week`), mit Wochen-Navigation
- **Backlog**: offene Tasks ohne Tagesplanung
- **Projekte**: Projektliste → Detailansicht mit Projekt-Tasks
- Tasks per Checkbox als **erledigt** markieren (`status = 'done'`, setzt `done_at`)
- Next-Action-Flag direkt umschaltbar

## Projektstruktur

```
lib/
  main.dart                 # App-Einstieg, Supabase.initialize, AuthGate
  config/
    supabase_config.dart    # URL + Anon-Key (per --dart-define überschreibbar)
  models/
    task.dart               # Task-Model (tasks-Tabelle)
    project.dart            # Project-Model (projects-Tabelle)
  services/
    task_service.dart       # Queries auf tasks
    project_service.dart    # Queries auf projects
  screens/
    home_shell.dart         # Navigation
    tagesplan_screen.dart
    wochenplan_screen.dart
    backlog_screen.dart
    projekte_screen.dart
  widgets/
    task_tile.dart          # Task-Zeile mit Checkbox + Tags
    status_views.dart       # Empty/Error/SectionHeader
web/                        # Web-Target
```

## Einrichtung

> Diese Umgebung hatte kein Flutter-SDK installiert, daher wurden die
> **Plattform-Ordner** (`android/`, Web-Icons, `linux/`, etc.) noch **nicht**
> generiert. Den Quellcode (`lib/`), `pubspec.yaml` und `web/index.html` gibt es
> bereits. Einmalig lokal ausführen:

```bash
# 1. Fehlende Plattform-Scaffolds ergänzen (überschreibt lib/ NICHT)
flutter create --platforms=web,android --org de.kerch .

# 2. Abhängigkeiten holen
flutter pub get
```

## Konfiguration (Anon-Key)

Der Anon-Key wird **nicht eingecheckt**, sondern beim Build per `--dart-define`
injiziert (`lib/config/supabase_config.dart` liest ihn via
`String.fromEnvironment`). Die Projekt-URL hat einen Default, der Key nicht –
ohne Key zeigt die App einen Hinweis-Screen.

Bezugsquellen je nach Umgebung:
- **Lokal**: `--dart-define` beim `flutter run`/`build`
- **CI**: GitHub-Secret `SUPABASE_ANON_KEY` (Repo → Settings → Secrets → Actions)
- **Docker**: build-arg `SUPABASE_ANON_KEY`

## Starten

```bash
# Web
flutter run -d chrome --dart-define=SUPABASE_ANON_KEY=<key>

# Android (Gerät/Emulator angeschlossen)
flutter run -d <device-id> --dart-define=SUPABASE_ANON_KEY=<key>
```

Bequemer für lokal: eine **gitignorierte** `dart_defines.json` anlegen …

```json
{ "SUPABASE_ANON_KEY": "<key>" }
```

… und damit starten: `flutter run --dart-define-from-file=dart_defines.json`

## Build

```bash
flutter build web --release --dart-define=SUPABASE_ANON_KEY=<key>
flutter build apk --release --dart-define=SUPABASE_ANON_KEY=<key>
```

## Backend

- Supabase-Projekt: `vnfkkujtkbgkqafbbipj` (eu-central-1)
- Tabellen: `tasks`, `projects`, `ideen`, `sport_log`, `profile`
- RLS ist **deaktiviert** → die App greift direkt mit dem Anon-Key zu (kein Login)

## CI/CD (GitHub Actions)

In `.github/workflows/`:

| Workflow | Trigger | Zweck |
|----------|---------|-------|
| `automerge.yml` | Push auf `claude/**` | Merged den Branch automatisch nach `main` |
| `build-android.yml` | Push auf `main`, manuell | Baut `app-release.apk` (Artifact) |
| `build-web.yml` | Push auf `main`, manuell | Baut die Web-App (`build/web` als Artifact) |

Die Build-Workflows erzeugen die Plattform-Scaffolds zur Laufzeit via
`flutter create`, da `android/` nicht eingecheckt ist.

## Web-App via Docker deployen

`Dockerfile` (Multi-Stage: Flutter-Build → nginx) und `nginx.conf` liegen im
Repo-Root.

```bash
# Image bauen (Anon-Key als build-arg, landet nicht im Repo)
docker build --build-arg SUPABASE_ANON_KEY=<key> -t todo-coaching-web .

# Container starten → http://localhost:8080
docker run -d -p 8080:80 --name todo-web todo-coaching-web
```

Oder via Compose (Key aus Umgebung bzw. `.env`):

```bash
export SUPABASE_ANON_KEY=<key>      # oder in .env (gitignoriert)
docker compose up -d --build
```

Der erste Build dauert etwas (Flutter-Toolchain im Image). Das fertige Image
enthält nur die statischen Web-Assets hinter nginx (klein & schnell). nginx ist
für SPA-Routing konfiguriert (`try_files … /index.html`).

