# Portainer Deployment mit GitHub Actions + Runtime Config

Das Docker Image wird automatisch durch GitHub Actions gebaut. Umgebungsvariablen werden **zur Runtime** injiziert - können also im Portainer ohne Rebuild geändert werden!

## Setup (einmalig)

### 1. GitHub Secret hinzufügen (optional für GitHub Actions)

Falls du GitHub Actions verwendest:
- GitHub Repo → **Settings → Secrets and variables → Actions**
- Neues Secret: `SUPABASE_PUBLISHABLE_KEY` = Dein Supabase Key

**Hinweis:** Das Secret ist optional - du kannst die Umgebungsvariablen auch direkt im Portainer setzen!

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
    environment:
      SUPABASE_URL: ${SUPABASE_URL:-https://vnfkkujtkbgkqafbbipj.supabase.co}
      SUPABASE_PUBLISHABLE_KEY: ${SUPABASE_PUBLISHABLE_KEY}
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
SUPABASE_URL=https://vnfkkujtkbgkqafbbipj.supabase.co
SUPABASE_PUBLISHABLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Wo bekommst du die Keys?**
- Supabase Dashboard → **Project Settings → API**
- `supabaseUrl`: Die Projekt-URL (z.B. `https://vnfkkujtkbgkqafbbipj.supabase.co`)
- `SUPABASE_PUBLISHABLE_KEY`: Der `anon` Public Key (beginnt mit `eyJ...` oder `sb_publishable_...`)

### Schritt 3: Deploy

Klick **Deploy** → App startet und lädt die Config aus den Env-Variablen ✅

## Updates der Config

**Umgebungsvariablen ändern (z.B. neuer Supabase Key):**

1. Im Portainer: Stack öffnen
2. **Edit Stack** oder **Update Stack**
3. Im **Environment** Feld ändern (z.B. `SUPABASE_PUBLISHABLE_KEY=neue-key`)
4. **Update** oder **Deploy** klicken

Das war's! Kein Rebuild nötig! 🚀

## Image Tags

GitHub Actions erzeugt automatisch:

| Trigger | Tag |
|---------|-----|
| Push zu `main` | `ghcr.io/.../ai-time-plannning:main` |
| Tag `v1.0.0` | `ghcr.io/.../ai-time-plannning:v1.0.0` |
| Commit SHA | `ghcr.io/.../ai-time-plannning:main-abc123` |

## Workflow

1. **Env-Var im Portainer ändern** → Update Stack
2. Container startet neu mit neuer Config
3. `docker-entrypoint.sh` generiert neue `config.js`
4. Flutter App lädt neue Config

## Troubleshooting

**App zeigt weißen Bildschirm?**
- Browser Console öffnen (F12)
- Prüfen ob `config.js` geladen wurde
- Prüfen ob `SUPABASE_PUBLISHABLE_KEY` gesetzt ist

**Image nicht erreichbar?**
- Repo muss **Public** sein (oder GitHub PAT)
- Warte ~1 min nach GitHub Actions Build

**Supabase Fehler?**
- `SUPABASE_PUBLISHABLE_KEY` prüfen (sollte nicht leer sein)
- `SUPABASE_URL` prüfen

## Logs prüfen

Im Portainer: Container Logs anschauen
```
Config generated:
window.appConfig = {
  supabaseUrl: 'https://...',
  supabaseAnonKey: 'eyJ...'
}
```

---

**Zusammengefasst:**
- ✅ GitHub Actions baut automatisch
- ✅ Config wird zur Runtime injiziert
- ✅ Umgebungsvariablen im Portainer editierbar
- ✅ Kein Rebuild für neue Keys nötig
