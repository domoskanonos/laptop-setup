# Video-Tagger + Organizer + optionaler Komprimierer

Taggt, ordnet und komprimiert nachträglich einen Ordner mit heruntergeladenen Videodateien.
Holt echte Serienposter von TMDB und legt sie in der Jellyfin-kompatiblen Series/Movies-Struktur ab.

## Parameter

| Platzhalter | Pflicht | Beschreibung |
|---|---|---|
| `QUELLE` | ja | Ordner mit den Videos (z.B. `./vids/garfield`) |
| `SERIE` | nein | Serien-/Filmname (wenn nicht angegeben, aus Dateinamen extrahiert) |
| `TYP` | nein | `series` (Default) oder `movies` |
| `KOMPRIMIEREN` | nein | `ja` oder `nein` (default: `nein`) |

## Voraussetzung: TMDB-API-Key

1. Auf https://www.themoviedb.org/settings/api registrieren → **API-Key (v3)** kopieren
2. In `~/.bashrc` eintragen: `export TMDB_API_KEY="dein_v3_key"`
3. Neu einloggen oder `source ~/.bashrc`

## Vorgehen

### 0. TMDB-API-Key laden + Typ setzen

```bash
if [ -z "$TMDB_API_KEY" ] && [ -f ~/.bashrc ]; then
  export TMDB_API_KEY=$(grep 'TMDB_API_KEY' ~/.bashrc | grep -o '"[^"]*"' | head -1 | tr -d '"')
fi
[ -z "$TMDB_API_KEY" ] && { echo "FEHLER: TMDB_API_KEY nicht gesetzt"; exit 1; }

TYP="${TYP:-series}"
```

### 1. Dateien scannen + Seriennamen ermitteln

```bash
ls -1 "QUELLE"/*.mp4 QUELLE/*.mkv 2>/dev/null
```

Aus jedem Dateinamen parsen:
- Sender (Präfix vor erstem `_`, z.B. `KiKA`, `HR`, `ZDF`)
- Serienname (falls `SERIE` nicht angegeben)
- Titel/Episode

**Beispiele:**
```
KiKA_Garfield_Rollenwechsel.mp4                   → Serie: Garfield,          Titel: Rollenwechsel
HR_Garfield_Monster Odie.mp4                      → Serie: Garfield,          Titel: Monster Odie
KiKA_Pippi Langstrumpf_Pippi auf der Walz (1).mp4 → Serie: Pippi Langstrumpf, Titel: Pippi auf der Walz
```

### 2. Teil-Videos zusammenführen (nur series)

```bash
# Erkennung: - Teil 1/2, _1_/_2_, (1)/(2) am Ende des Dateinamens
# Nur concat wenn jede Part < 10 Min (sonst eigene Episoden)
# ffmpeg -f concat -safe 0 -c copy
```

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
  TMDB_GENRES=$(python3 -c "import json; d=json.load(open('/tmp/tmdb_series.json')); print(', '.join(g['name'] for g in d.get('genres',[])))")
  TMDB_POSTER=$(python3 -c "import json; print(json.load(open('/tmp/tmdb_series.json')).get('poster_path','') or '')")
  TMDB_BACKDROP=$(python3 -c "import json; print(json.load(open('/tmp/tmdb_series.json')).get('backdrop_path','') or '')")
  TMDB_RATING=$(python3 -c "import json; print(json.load(open('/tmp/tmdb_series.json')).get('vote_average',''))")
fi
```

### 4. Poster von TMDB + Zielverzeichnis

```bash
ROOT_DIR="$HOME/Videos/Series"
[ "$TYP" = "movies" ] && ROOT_DIR="$HOME/Videos/Movies"

TARGET_DIR="$ROOT_DIR/SERIE"
if [ "$TYP" = "movies" ] && [ -n "$TMDB_YEAR" ]; then
  TARGET_DIR="$ROOT_DIR/SERIE ($TMDB_YEAR)"
fi
mkdir -p "$TARGET_DIR"

if [ -n "$TMDB_POSTER" ]; then
  curl -s "https://image.tmdb.org/t/p/w500$TMDB_POSTER" -o "$TARGET_DIR/poster.jpg"
  [ -n "$TMDB_BACKDROP" ] && curl -s "https://image.tmdb.org/t/p/w1280$TMDB_BACKDROP" -o "$TARGET_DIR/fanart.jpg"
fi

# Bei series: Season-Ordner
if [ "$TYP" = "series" ]; then
  mkdir -p "$TARGET_DIR/Season 01"
  # Season-Poster von TMDB
  curl -s "https://api.themoviedb.org/3/tv/$TMDB_ID/season/1?api_key=$TMDB_API_KEY&language=de" -o /tmp/tmdb_season.json
  SP=$(python3 -c "import json; print(json.load(open('/tmp/tmdb_season.json')).get('poster_path','') or '')")
  if [ -n "$SP" ]; then
    curl -s "https://image.tmdb.org/t/p/w500$SP" -o "$TARGET_DIR/Season 01/season-poster.jpg"
    cp "$TARGET_DIR/Season 01/season-poster.jpg" "$TARGET_DIR/Season 01/thumb.jpg"
  fi
fi
```

### 5. Verzeichnisstruktur

**Bei `TYP=series`:**
```
~/Videos/Series/SERIE/
├── poster.jpg
├── fanart.jpg
├── Season 01/
│   ├── season-poster.jpg
│   ├── thumb.jpg
│   └── SERIE - S01E01 - EPISODENTITEL.ext
```

**Bei `TYP=movies`:**
```
~/Videos/Movies/SERIE (JAHR)/
├── poster.jpg
├── fanart.jpg
└── SERIE (JAHR).ext
```

### 6. Metadaten + Cover schreiben

**Variante A: series**
```bash
for FILE in sortierte Liste; do
  dur=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$FILE" 2>/dev/null || echo "600")
  ffmpeg -y -ss "$(python3 -c "print(int($dur * 0.1))")" -i "$FILE" -frames:v 1 -q:v 2 /tmp/ep_cover.jpg

  ffmpeg -y -i "$FILE" -i /tmp/ep_cover.jpg \
    -map 0:v -map 0:a -map 1 -c copy \
    -metadata title="EPISODENTITEL" \
    -metadata show="SERIE" \
    -metadata episode_id="S01EXX" \
    -metadata season_number="1" \
    -metadata date="$TMDB_YEAR" \
    -metadata genre="$TMDB_GENRES" \
    -metadata comment="TMDB: ★ $TMDB_RATING" \
    -metadata:s:v:1 title="Album Cover" \
    -disposition:v:1 attached_pic \
    "$TARGET_DIR/Season 01/SERIE - S01EXX - EPISODENTITEL.mp4"

  rm -f /tmp/ep_cover.jpg "$FILE"
done
```

**Variante B: movies**
```bash
for FILE in sortierte Liste; do
  ffmpeg -y -i "$FILE" -i "$TARGET_DIR/poster.jpg" \
    -map 0:v -map 0:a -map 1 -c copy \
    -metadata title="SERIE" \
    -metadata date="$TMDB_YEAR" \
    -metadata genre="$TMDB_GENRES" \
    -metadata synopsis="$TMDB_OVERVIEW" \
    -metadata comment="TMDB: ★ $TMDB_RATING" \
    -metadata:s:v:1 title="Album Cover" \
    -disposition:v:1 attached_pic \
    "$TARGET_DIR/SERIE ($TMDB_YEAR).mp4"

  rm -f "$FILE"
done
```

### 7. Optional: HEVC NVENC Kompression

Nur wenn `KOMPRIMIEREN=ja` und:
- Datei > 100 MB
- Bitrate > 1.5 Mbps
- Savings > 30%

```bash
ffmpeg -y -hwaccel cuda -i "EINGANG.mp4" \
  -c:v hevc_nvenc -preset p6 -cq 20 -rc constqp \
  -c:a aac -b:a 128k \
  "VORSCHLAG.mkv"
```

### 8. Abschluss

- Tabelle: Quelle → Ziel (im Series/Movies-Pfad)
- Existieren `poster.jpg`, `fanart.jpg`, `Season XX/thumb.jpg`?
- Ersparnis bei Kompression
- Gelöschte Quelldateien

## Jellyfin-Einrichtung

| Bibliothek | Typ | Pfad |
|---|---|---|
| Series | TV Shows | `~/Videos/Series` |
| Movies | Movies | `~/Videos/Movies` |

Nach dem Scannen: **Bibliothek aktualisieren** in Jellyfin.

## Vorheriger Schritt

Dieser Prompt verarbeitet Roh-Downloads. Falls du die Videos noch nicht hast:

```
@mediathekwebview
Serie: Garfield
```

Dann `videotagger` auf den `./downloads/Garfield`-Ordner loslassen.

## Wichtige Hinweise

- TMDB-Key in `~/.bashrc` als `export TMDB_API_KEY="..."` setzen
- `-map 0:v -map 0:a` statt `-map 0` (sonst `codec none`-Fehler)
- `episode_id="S01E05"` statt `episode_number`
- NVENC erfordert NVIDIA GPU
