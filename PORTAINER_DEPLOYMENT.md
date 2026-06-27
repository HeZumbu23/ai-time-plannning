# Portainer Web Editor Deployment

Alle Konfiguration erfolgt direkt im Portainer Web Editor. **Keine Dateien im Repo nötig.**

## Schritt 1: Im Portainer Dashboard

1. **Stacks → Add Stack**
2. **Paste or Load Stack file** → Web Editor

## Schritt 2: Compose-Datei in Web Editor

Kopiere diese docker-compose.yml in den Web Editor und füge deine Werte ein:

```yaml
version: '3.8'

services:
  ai-time-planning:
    image: localhost/ai-time-planning:${TAG:-latest}
    container_name: ai-time-planning
    ports:
      - "${PORT:-8080}:80"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
```

## Schritt 3: Environment Variables im Portainer

Unter der Compose-Datei findest du **"Environment"** Feld:

```
PORT=8080
TAG=latest
SUPABASE_PUBLISHABLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Variablen erklärt

| Variable | Beispiel | Erklärung |
|----------|----------|-----------|
| `PORT` | `8080` | Port, unter dem die App erreichbar ist |
| `TAG` | `latest` oder `v1.0.0` | Docker Image Tag |
| `SUPABASE_PUBLISHABLE_KEY` | `eyJ...` | Dein Supabase Public Key (Build-Time!) |

## Schritt 4: Image vorbereiten

Bevor du im Portainer deployst, baue das Docker Image lokal:

```bash
# Mit deinem Supabase Key
docker build \
  --build-arg SUPABASE_PUBLISHABLE_KEY="your-key-here" \
  -t ai-time-planning:latest .

# Oder mit Tag
docker build \
  --build-arg SUPABASE_PUBLISHABLE_KEY="your-key-here" \
  -t ai-time-planning:v1.0.0 .
```

Das Image muss lokal oder in einer Registry verfügbar sein (z.B. für `localhost/ai-time-planning`).

## Schritt 5: Deploy

1. **Environment variables** eingetragen? ✓
2. **TAG** entspricht deinem Image? ✓
3. **Deploy** klicken

## App testen

- `http://localhost:8080` öffnen
- Sollte die Flutter Web App laden

## Updates

Wenn du änderungen machst:

1. Neues Image bauen:
```bash
docker build \
  --build-arg SUPABASE_PUBLISHABLE_KEY="your-key" \
  -t ai-time-planning:v1.0.1 .
```

2. Im Portainer:
   - Stack öffnen
   - `TAG=v1.0.1` ändern
   - **Update** klicken

## Troubleshooting

**Container startet nicht?**
```bash
docker logs ai-time-planning
```

**App lädt nicht?**
- Browser Console (F12) prüfen
- `http://localhost:8080/` im Browser aufrufen

**Build Error?**
- `SUPABASE_PUBLISHABLE_KEY` prüfen
- Flutter Dependencies: `flutter pub get`
