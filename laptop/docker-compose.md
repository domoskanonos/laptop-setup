# docker-compose

```bash
# In das docker-compose.yaml des gewünschten Geräts wechseln
cd laptop     # Desktop + GPU (ComfyUI, TTS)
# oder
cd server     # Headless (Jellyfin, Immich, ...)

# Starten im Hintergrund (daemon mode)
docker compose up -d

# Logs anzeigen
docker compose logs -f

# Stoppen
docker compose down

# Status
docker compose ps
```
