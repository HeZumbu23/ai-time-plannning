# TODO & Coaching

Persönliches TODO- und Coaching-System als Flutter-App (Web + Android) mit
Supabase-Backend.

## Features (Stand)

- **Kein Login** – RLS ist deaktiviert, der Anon-Key greift direkt
- **Haupt-Navigation**: Tagesplan · Wochenplan · Backlog · Projekte · Chat
  (NavigationRail auf breiten Screens, NavigationBar auf schmalen)
- **Chat mit Claude**: natürlichsprachliche Befehle für Tasks (anlegen, ändern,
  abhaken, suchen) über die Anthropic-API mit Tool-Use direkt auf Supabase.
  Der **Anthropic-API-Key** ist geheim und wird **nur lokal** im Gerät
  gespeichert (Chat-Tab → Zahnrad), nie im Build/Repo. Modellwahl: Opus 4.8 /
  Sonnet 4.6 / Haiku 4.5.
- **Tagesplan**: Tasks für heute (`planned_day = today`) + offene Next Actions
- **Wochenplan**: Tasks der Kalenderwoche (`planned_week`), mit Wochen-Navigation
- **Backlog**: offene Tasks ohne Tagesplanung
- **Projekte**: Projektliste → Detailansicht mit Projekt-Tasks
- Tasks per Checkbox als **erledigt** markieren (`status = 'done'`, setzt `done_at`)
- Next-Action-Flag direkt umschaltbar

## Projektstruktur

```
lib/
  main.dart                 # App-Einstieg, Supabase.initialize
  config/
    supabase_config.dart    # URL + Publishable Key (per --dart-define gesetzt)
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

## Konfiguration (Publishable Key)

Die App nutzt den **Publishable Key** (`sb_publishable_…`, Nachfolger des
anon-Keys). Er ist **nicht geheim** – er landet ohnehin sichtbar im Web-Bundle
bzw. in der APK. Der eigentliche Schutz käme über RLS (aktuell deaktiviert).

Der Key wird **zur Build-Zeit** per `--dart-define=SUPABASE_PUBLISHABLE_KEY`
in App **und** Web gebacken (`lib/config/supabase_config.dart` liest ihn via
`String.fromEnvironment`). Ohne Key zeigt die App einen Hinweis-Screen.

Bezugsquellen je nach Umgebung:
- **CI (Web + Android)**: Repository-**Variable** `SUPABASE_PUBLISHABLE_KEY`
  (Repo → Settings → Secrets and variables → Actions → Tab **Variables**).
  Eine *Variable* (kein Secret), weil der Wert nicht geheim ist.
- **Lokal**: `--dart-define` beim `flutter run`/`build`
- **Docker**: build-arg `SUPABASE_PUBLISHABLE_KEY`

## Starten

```bash
# Web
flutter run -d chrome --dart-define=SUPABASE_PUBLISHABLE_KEY=<key>

# Android (Gerät/Emulator angeschlossen)
flutter run -d <device-id> --dart-define=SUPABASE_PUBLISHABLE_KEY=<key>
```

Bequemer für lokal: eine **gitignorierte** `dart_defines.json` anlegen …

```json
{ "SUPABASE_PUBLISHABLE_KEY": "<key>" }
```

… und damit starten: `flutter run --dart-define-from-file=dart_defines.json`

## Build

```bash
flutter build web --release --dart-define=SUPABASE_PUBLISHABLE_KEY=<key>
flutter build apk --release --dart-define=SUPABASE_PUBLISHABLE_KEY=<key>
```

## Backend

- Supabase-Projekt: `vnfkkujtkbgkqafbbipj` (eu-central-1)
- Tabellen: `tasks`, `projects`, `ideen`, `sport_log`, `profile`
- RLS ist **deaktiviert** → die App greift direkt mit dem Publishable Key zu (kein Login)

## CI/CD (GitHub Actions)

In `.github/workflows/`:

| Workflow | Trigger | Zweck |
|----------|---------|-------|
| `automerge.yml` | Push auf `claude/**` | Merged den Branch automatisch nach `main` |
| `build-android.yml` | Push auf `main`, manuell | Baut die APK, **veröffentlicht ein GitHub-Release** + Artifact |
| `build-web.yml` | Push auf `main`, manuell | Baut die Web-App (`build/web` als Artifact) |

Die Build-Workflows erzeugen die Plattform-Scaffolds zur Laufzeit via
`flutter create`, da `android/` nicht eingecheckt ist.

## Android-App via Obtainium installieren

`build-android.yml` legt bei jedem `main`-Build ein **GitHub-Release** mit der
APK an. [Obtainium](https://github.com/ImranR98/Obtainium) kann das direkt
abonnieren und automatisch updaten:

1. Obtainium → **Add App**
2. Source-URL: `https://github.com/HeZumbu23/ai-time-plannning`
3. Obtainium erkennt die Releases und die `app-release.apk` automatisch.

> **Public Repo (empfohlen):** Ist das Repo öffentlich, funktioniert Obtainium
> **ohne Token** – kein 404. Da der Anon-Key dank QR-Einrichtung nicht mehr im
> Code/Build liegt, ist das unproblematisch.
>
> **Privates Repo:** Falls das Repo `private` bleibt, liefert GitHub ohne
> Authentifizierung **404**. Dann in Obtainium einmalig ein GitHub-Token
> hinterlegen: *Obtainium → Settings → Source-specific → GitHub →
> Personal Access Token*. Ein **fine-grained PAT** mit nur
> *Contents: Read-only* auf genau dieses Repo reicht
> (github.com → Settings → Developer settings → Fine-grained tokens).

> Workflow-**Artifacts** (der „Download"-Button im Actions-Tab) funktionieren
> für Obtainium **nicht** – die sind gezippt, brauchen Login und verfallen.
> Deshalb der Umweg über Releases.

### Stabile Signatur (für Obtainium-Updates erforderlich)

Ohne eigenen Signaturschlüssel signiert jeder CI-Lauf mit einem *neuen*
Debug-Key → Android lehnt das Update mit „Signaturkonflikt" ab. Einmalig einen
festen Keystore erzeugen und als Secrets hinterlegen:

```bash
# 1. Keystore erzeugen
keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload

# 2. Base64 für das GitHub-Secret
base64 -w0 upload.jks   # (macOS: base64 -i upload.jks)
```

Dann unter *Repo → Settings → Secrets and variables → Actions* anlegen:

| Secret | Wert |
|--------|------|
| `ANDROID_KEYSTORE_BASE64` | Base64-String aus Schritt 2 |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore-Passwort |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | Key-Passwort (oft = Keystore-Passwort) |

⚠️ **Den `upload.jks` sicher aufbewahren** und **nicht** ins Repo committen –
geht er verloren, kannst du bestehende Installationen nicht mehr updaten.
Solange die Secrets fehlen, baut der Workflow trotzdem (debug-signiert, mit
Warnung) – nur Auto-Updates über Obtainium klappen dann nicht.

## Web-App via Docker deployen

`Dockerfile` (Multi-Stage: Flutter-Build → nginx) und `nginx.conf` liegen im
Repo-Root.

```bash
# Image bauen (Publishable Key als build-arg)
docker build --build-arg SUPABASE_PUBLISHABLE_KEY=<key> -t todo-coaching-web .

# Container starten → http://localhost:8080
docker run -d -p 8080:80 --name todo-web todo-coaching-web
```

Oder via Compose (Key aus Umgebung bzw. `.env`):

```bash
export SUPABASE_PUBLISHABLE_KEY=<key>      # oder in .env (gitignoriert)
docker compose up -d --build
```

Der erste Build dauert etwas (Flutter-Toolchain im Image). Das fertige Image
enthält nur die statischen Web-Assets hinter nginx (klein & schnell). nginx ist
für SPA-Routing konfiguriert (`try_files … /index.html`).

