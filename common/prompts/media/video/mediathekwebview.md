# MediathekViewWeb Downloader + Metadaten + TMDB-Cover

Lade eine Serie von https://mediathekviewweb.de/ in HD-Qualität herunter, schreibe Metadaten + TMDB-Poster in jede Datei. Fertig für Jellyfin/Plex/Emby.

## Parameter

| Platzhalter | Pflicht | Beschreibung |
|---|---|---|
| `SERIE` | ja | Serien- oder Filmname (z.B. `Garfield`, `Pippi Langstrumpf`) |
| `TYP` | nein | `series` (Default) oder `movies` |

## Voraussetzung: TMDB-API-Key

1. Auf https://www.themoviedb.org/settings/api registrieren → **API-Key (v3)** kopieren
2. In `~/.bashrc` eintragen: `export TMDB_API_KEY="dein_v3_key"`
3. Neu einloggen oder `source ~/.bashrc`

## Vorgehen

### 0. TMDB-API-Key laden (falls noch nicht in Env)

```bash
if [ -z "$TMDB_API_KEY" ] && [ -f ~/.bashrc ]; then
  export TMDB_API_KEY=$(grep 'TMDB_API_KEY' ~/.bashrc | grep -o '"[^"]*"' | head -1 | tr -d '"')
fi
if [ -z "$TMDB_API_KEY" ]; then
  echo "FEHLER: TMDB_API_KEY nicht gesetzt. Siehe Voraussetzung."
  exit 1
fi

# Typ setzen
TYP="${TYP:-series}"
```

### 1. Suche über MediathekViewWeb-API

```bash
curl -s 'https://mediathekviewweb.de/api/query' \
  -H 'Content-Type: application/json' \
  -d '{
    "queries": [{"fields": ["title", "topic"], "query": "SERIE"}],
    "sortBy": "timestamp",
    "sortOrder": "desc",
    "size": 200
  }' -o /tmp/mv_results.json
```

### 2. Nur HD-Ergebnisse filtern

- `url_video_hd` muss existieren und nicht leer sein
- Bei `TYP=series`: Aus `topic` die Staffel parsen ("Garfield Staffel 4" → Season 04)
- Aus `channel` den Sender notieren
- Doppelte Titel anhand der `id` deduplizieren (gleiche Episode von KiKA und HR → größere behalten)

### 3. TMDB-Metadaten holen

```bash
curl -s "https://api.themoviedb.org/3/search/tv?api_key=$TMDB_API_KEY&query=SERIE&language=de" -o /tmp/tmdb_search.json

TMDB_ID=$(python3 -c "
import json
with open('/tmp/tmdb_search.json') as f:
    d = json.load(f)
results = d.get('results', [])
if results:
    best = max(results, key=lambda r: r.get('popularity', 0) * r.get('vote_count', 0))
    print(best['id'])
")

if [ -n "$TMDB_ID" ]; then
  curl -s "https://api.themoviedb.org/3/tv/$TMDB_ID?api_key=$TMDB_API_KEY&language=de" -o /tmp/tmdb_series.json
  TMDB_TITLE=$(python3 -c "import json; print(json.load(open('/tmp/tmdb_series.json')).get('name',''))")
  TMDB_YEAR=$(python3 -c "import json; print(json.load(open('/tmp/tmdb_series.json')).get('first_air_date','')[:4])")
  TMDB_OVERVIEW=$(python3 -c "import json; print(json.load(open('/tmp/tmdb_series.json')).get('overview',''))")
  TMDB_GENRES=$(python3 -c "import json; d=json.load(open('/tmp/tmdb_series.json')); print(', '.join(g['name'] for g in d.get('genres',[])))")
  TMDB_POSTER=$(python3 -c "import json; print(json.load(open('/tmp/tmdb_series.json')).get('poster_path','') or '')")
  TMDB_BACKDROP=$(python3 -c "import json; print(json.load(open('/tmp/tmdb_series.json')).get('backdrop_path','') or '')")
  TMDB_RATING=$(python3 -c "import json; print(json.load(open('/tmp/tmdb_series.json')).get('vote_average',''))")
  echo "  TMDB: $TMDB_TITLE ($TMDB_YEAR) | $TMDB_GENRES | ★ $TMDB_RATING"
fi
```

### 4. Poster von TMDB runterladen

```bash
if [ "$TYP" = "series" ]; then
  ROOT_DIR="Series"
else
  ROOT_DIR="Movies"
fi

TARGET_DIR="$ROOT_DIR/SERIE"
if [ "$TYP" = "movies" ] && [ -n "$TMDB_YEAR" ]; then
  TARGET_DIR="$ROOT_DIR/SERIE ($TMDB_YEAR)"
fi
mkdir -p "$TARGET_DIR"

if [ -n "$TMDB_POSTER" ]; then
  curl -s "https://image.tmdb.org/t/p/w500$TMDB_POSTER" -o "$TARGET_DIR/poster.jpg"
  [ -n "$TMDB_BACKDROP" ] && curl -s "https://image.tmdb.org/t/p/w1280$TMDB_BACKDROP" -o "$TARGET_DIR/fanart.jpg"
fi
```

### 5. Verzeichnisstruktur

**Bei `TYP=series` (Default):**
```
Series/SERIE/
├── poster.jpg
├── fanart.jpg
├── Season 01/
│   ├── season-poster.jpg
│   ├── thumb.jpg
│   ├── SERIE - S01E01 - EPISODENTITEL.mp4
│   └── SERIE - S01E02 - EPISODENTITEL.mp4
```

- Staffel aus `topic` parsen (Regex: `Staffel (\d+)`)
- Episoden fortlaufend nach `timestamp` nummerieren
- Fallback: Season 01

**Bei `TYP=movies`:**
```
Movies/SERIE (JAHR)/
├── poster.jpg
├── fanart.jpg
└── SERIE (JAHR).mp4
```

### 6. Season-Poster von TMDB (nur series)

```bash
if [ "$TYP" = "series" ]; then
  for SEASON_DIR in "$TARGET_DIR"/Season*; do
    [ -d "$SEASON_DIR" ] || continue
    S=$(basename "$SEASON_DIR" | grep -oP '\d+')
    [ -z "$S" ] && continue
    curl -s "https://api.themoviedb.org/3/tv/$TMDB_ID/season/$S?api_key=$TMDB_API_KEY&language=de" -o /tmp/tmdb_season.json
    SP=$(python3 -c "import json; print(json.load(open('/tmp/tmdb_season.json')).get('poster_path','') or '')")
    if [ -n "$SP" ]; then
      curl -s "https://image.tmdb.org/t/p/w500$SP" -o "$SEASON_DIR/season-poster.jpg"
      cp "$SEASON_DIR/season-poster.jpg" "$SEASON_DIR/thumb.jpg"
    fi
  done
fi
```

### 7. Download + Metadaten (pro Episode / pro Film)

**Variante A: `TYP=series`**
```bash
TARGET="$TARGET_DIR/Season SXX/SERIE - SXXEYY - EPISODENTITEL.mp4"
mkdir -p "$(dirname "$TARGET")"

DUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$QUELL_URL" 2>/dev/null || echo "600")
ffmpeg -y -ss "$(python3 -c "print(int($DUR * 0.1))")" -i "$QUELL_URL" -frames:v 1 -q:v 2 /tmp/ep_cover.jpg

ffmpeg -y -user_agent 'Mozilla/5.0' -i "$HD_URL" \
  -i /tmp/ep_cover.jpg \
  -map 0:v -map 0:a -map 1 \
  -c copy -bsf:a aac_adtstoasc \
  -metadata title="EPISODENTITEL" \
  -metadata show="SERIE" \
  -metadata episode_id="SXXEYY" \
  -metadata season_number="SXX" \
  -metadata date="$TMDB_YEAR" \
  -metadata genre="$TMDB_GENRES" \
  -metadata synopsis="KURZBESCHREIBUNG" \
  -metadata comment="Sender: CHANNEL | TMDB: ★ $TMDB_RATING" \
  -metadata:s:v:1 title="Album Cover" \
  -metadata:s:v:1 comment="Cover (front)" \
  -disposition:v:1 attached_pic \
  "$TARGET"
```

**Variante B: `TYP=movies`**
```bash
TARGET="$TARGET_DIR/SERIE ($TMDB_YEAR).mp4"
mkdir -p "$(dirname "$TARGET")"

ffmpeg -y -user_agent 'Mozilla/5.0' -i "$HD_URL" \
  -i "$TARGET_DIR/poster.jpg" \
  -map 0:v -map 0:a -map 1 \
  -c copy -bsf:a aac_adtstoasc \
  -metadata title="SERIE" \
  -metadata date="$TMDB_YEAR" \
  -metadata genre="$TMDB_GENRES" \
  -metadata synopsis="$TMDB_OVERVIEW" \
  -metadata comment="TMDB: ★ $TMDB_RATING" \
  -metadata:s:v:1 title="Album Cover" \
  -metadata:s:v:1 comment="Cover (front)" \
  -disposition:v:1 attached_pic \
  "$TARGET"
```

### 8. Prüfung

- Dateien vorhanden mit > 100 KB
- `poster.jpg` + `fanart.jpg` existieren
- Bei series: `Season XX/thumb.jpg` + `season-poster.jpg` existieren
- Per Stichprobe: Tags via ffprobe sichtbar
- Auflösung 1280x720 oder 1920x1080

## Jellyfin-Einrichtung

Nach dem Download in Jellyfin zwei Bibliotheken anlegen:

| Bibliothek | Typ | Pfad |
|---|---|---|
| Series | TV Shows | `/home/laptop/Videos/Series` |
| Movies | Movies | `/home/laptop/Videos/Movies` |

Dann **Bibliothek scannen** → Poster werden von den lokalen `poster.jpg` geladen.

## Wichtige Hinweise

- TMDB-Key in `~/.bashrc` als `export TMDB_API_KEY="..."` setzen
- ORF/SRF sind oft geo-blocked → überspringen
- `-map 0:v -map 0:a` statt `-map 0` (sonst `codec none`-Fehler)
- `episode_number` wird nicht unterstützt → `episode_id="S01E05"`
