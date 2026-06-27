# AI Time Planning - Deployment auf Portainer

## Voraussetzungen
- Portainer installiert und laufend
- Docker auf dem Host verfügbar
- Zugang zum Portainer Dashboard
- Die `SUPABASE_PUBLISHABLE_KEY` verfügbar

## Schritt 1: Docker Image bauen

### Option A: Lokal bauen und zu Registry pushen
```bash
# Lokal bauen
docker build \
  --build-arg SUPABASE_PUBLISHABLE_KEY="your-publishable-key-here" \
  -t ai-time-planning:latest .

# Optional: Zu Registry pushen (wenn du externe Registry nutzt)
docker tag ai-time-planning:latest your-registry/ai-time-planning:latest
docker push your-registry/ai-time-planning:latest
```

### Option B: Über Portainer bauen
1. Gehe zu **Portainer Dashboard → Stacks**
2. Klick **Add Stack**
3. **Stack Name**: `ai-time-planning`
4. **Build Method**: "Upload" oder "Git Repository"
5. Upload das gesamte Projekt oder verbinde mit Git
6. Unter "Environment Variables" folgende Variablen hinzufügen:
   ```
   SUPABASE_PUBLISHABLE_KEY=your-key-here
   PORT=8080
   REGISTRY=localhost
   TAG=latest
   ```

## Schritt 2: Portainer Web Editor

### Option 1: docker-compose.yml verwenden
1. **Portainer → Stacks → Add Stack**
2. **Paste or Load Stack file**:
```yaml
version: '3.8'
services:
  ai-time-planning:
    image: ${REGISTRY:-localhost}/ai-time-planning:${TAG:-latest}
    container_name: ai-time-planning
    ports:
      - "${PORT:-8080}:80"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3
```

3. **Environment variables** konfigurieren:
   - `REGISTRY`: z.B. `my-registry.com` oder `localhost`
   - `TAG`: z.B. `latest` oder `v1.0.0`
   - `PORT`: z.B. `8080` (Port, unter dem die App erreichbar ist)

4. **Deploy** klicken

## Schritt 3: App testen
- Öffne: `http://localhost:8080` (oder `http://your-server-ip:8080`)
- Sollte die Flutter Web App laden

## Umgebungsvariablen

| Variable | Standard | Beschreibung |
|----------|----------|-------------|
| `REGISTRY` | `localhost` | Container Registry (für Images) |
| `TAG` | `latest` | Image-Tag |
| `PORT` | `8080` | Expose Port |

## Wichtige Notizen

⚠️ **SUPABASE_PUBLISHABLE_KEY**
- Dies ist eine **Build-Time** Variable
- Sie wird in das Image kompiliert (nicht zur Runtime injiziert)
- Um die Key zu ändern, musst du ein **neues Image bauen**

✅ **Performance-Features**
- Nginx mit Gzip-Kompression
- Smart Caching für Assets (1 Jahr für gehashte Dateien)
- Service Worker Support für PWA

## Troubleshooting

### Container startet nicht
```bash
# Logs anschauen (in Portainer)
# Oder per CLI:
docker logs ai-time-planning
```

### App lädt nicht
- Prüfe: `http://localhost:8080/`
- Browser Console prüfen (F12)
- Nginx logs: `docker exec ai-time-planning cat /var/log/nginx/error.log`

### Build schlägt fehl
- Flutter dependency Fehler? → `flutter pub get` im Container
- Supabase Key fehlt? → Build arg prüfen

## Updates deployen

1. Baue neues Image:
```bash
docker build \
  --build-arg SUPABASE_PUBLISHABLE_KEY="your-key" \
  -t ai-time-planning:v1.0.1 .
```

2. In Portainer:
   - Stack updaten
   - `TAG=v1.0.1` setzen
   - Re-deploy

## Weiterführend

- **Nginx Config**: `nginx.conf`
- **Docker Multi-Stage Build**: `Dockerfile`
- **Flutter Web Docs**: https://flutter.dev/docs/get-started/web
