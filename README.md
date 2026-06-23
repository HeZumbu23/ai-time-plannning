# TODO & Coaching

Persönliches TODO- und Coaching-System als Flutter-App (Web + Android) mit
Supabase-Backend.

## Features (Stand)

- **Supabase Auth** (Email/Passwort, Single User) mit RLS-geschütztem Backend
- **Login-Screen**
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
    auth_service.dart       # Supabase Auth Wrapper
    task_service.dart       # Queries auf tasks
    project_service.dart    # Queries auf projects
  screens/
    login_screen.dart
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

## Starten

```bash
# Web
flutter run -d chrome

# Android (Gerät/Emulator angeschlossen)
flutter run -d <device-id>
```

## Build

```bash
flutter build web        # Output: build/web/
flutter build apk        # Output: build/app/outputs/flutter-apk/
```

## Konfiguration

URL und Anon-Key stehen in `lib/config/supabase_config.dart`. Der Anon-Key ist
ein öffentlicher Client-Key (Schutz erfolgt über RLS). Für abweichende
Umgebungen kann man ihn beim Start überschreiben:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://... \
  --dart-define=SUPABASE_ANON_KEY=...
```

## Backend

- Supabase-Projekt: `vnfkkujtkbgkqafbbipj` (eu-central-1)
- Tabellen: `tasks`, `projects`, `ideen`, `sport_log`, `profile`
- RLS ist aktiv → Zugriff nur nach Login (Supabase Auth)

### Hinweis zu Auth

Single-User: Der Benutzer muss einmalig im Supabase Dashboard
(*Authentication → Users*) angelegt werden (oder via Sign-up, falls aktiviert).
Danach Login über E-Mail/Passwort im Login-Screen.
