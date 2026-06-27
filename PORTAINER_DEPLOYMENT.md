# Portainer Deployment mit GitHub Actions

Das Docker Image wird automatisch durch GitHub Actions gebaut und zu ghcr.io gepusht. **Kein lokales Bauen nötig!**

## Setup (einmalig)

### 1. GitHub Secret hinzufügen

GitHub Repo → **Settings → Secrets and variables → Actions**

Neues Secret hinzufügen:
- **Name**: `SUPABASE_PUBLISHABLE_KEY`
- **Value**: Dein Supabase Public Key (z.B. `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`)

Das war's! GitHub Actions nutzt dieses Secret automatisch beim Build.

### 2. GitHub Container Registry Token (optional, für private Repos)

Falls dein Repo privat ist, brauchst du einen PAT:
- GitHub → **Settings → Developer settings → Personal access tokens → Tokens (classic)**
- Scope: `write:packages`, `read:packages`
- Token kopieren und im Repo Secret speichern

## Deployment in Portainer

### Schritt 1: Im Portainer Web Editor

**Stacks → Add Stack → Web Editor**

Kopiere diese docker-compose.yml:

```yaml
version: '3.8'

services:
  ai-time-planning:
    image: ghcr.io/hezumbu23/ai-time-plannning:${TAG:-main}
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

### Schritt 2: Environment Variables

Unter dem Editor, im **Environment** Feld:

```
PORT=8080
TAG=main
```

### Schritt 3: Deploy

Klick **Deploy** → App lädt automatisch die neueste Version von ghcr.io

## Image Tags

GitHub Actions erzeugt automatisch Tags:

| Trigger | Tag |
|---------|-----|
| Push zu `main` | `ghcr.io/.../ai-time-plannning:main` |
| Tag `v1.0.0` | `ghcr.io/.../ai-time-plannning:v1.0.0`, `1.0`, `latest` |
| Commit SHA | `ghcr.io/.../ai-time-plannning:main-abc1234` |

## Workflow mit Updates

1. **Code ändern** → Git Push zu main
2. **GitHub Actions** baut automatisch das Image
3. **In Portainer**: Stack updaten
   - `TAG=main` bleibt gleich (oder `TAG=v1.0.0` für Release)
   - **Update** klicken → zieht neue Version

Das war's! 🚀

## Troubleshooting

**Build schlägt fehl?**
- GitHub Repo → **Actions** → Workflow Log prüfen
- Meist: `SUPABASE_PUBLISHABLE_KEY` Secret nicht gesetzt

**Image ist nicht erreichbar?**
- Repo muss **Public** sein (oder PAT mit `read:packages`)
- Warte ~1 min nach Push, bis Image verfügbar ist

**Portainer findet Image nicht?**
```bash
# Im Portainer Container Shell:
docker pull ghcr.io/hezumbu23/ai-time-plannning:main
```

## GitHub Actions Workflow

Die Workflow Datei: `.github/workflows/docker-build.yml`

Baut automatisch auf:
- ✅ Push zu `main`
- ✅ Git Tags (`v*`)
- ✅ Manual Trigger (Actions UI)

## Weitere Optionen

### Specific Port in Portainer
```yaml
# In Portainer Environment:
PORT=3000
TAG=main
```

### Mit Private Registry (falls gewünscht)
Ersetze `ghcr.io` mit deiner Registry (z.B. Docker Hub, Harbor, etc.)

---

**Zusammengefasst:**
- ✅ GitHub Actions baut → ghcr.io pusht
- ✅ Portainer pullt von ghcr.io
- ✅ Environment Vars im Portainer editieren
- ✅ Keine lokalen Builds nötig
