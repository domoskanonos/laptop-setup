# Video-Tagger + Organizer

Taggt, ordnet und bereitet nachträglich einen Ordner mit rohen Videodateien für Jellyfin auf.
Holt echte Serienposter von TMDB, generiert Episode-Thumbnails und legt alles in der Jellyfin-kompatiblen Series/Movies-Struktur ab.

## Parameter

| Platzhalter | Pflicht | Beschreibung |
|---|---|---|
| `QUELLE` | ja | Ordner mit den rohen Videos (z.B. `./vids/garfield`) |
| `SERIE` | nein | Serien-/Filmname (wenn nicht angegeben, aus Dateinamen extrahiert) |
| `TYP` | nein | `series` (Default) oder `movies` |

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

### 2. TMDB-Metadaten holen

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
  TMDB_OVERVIEW=$(python3 -c "import json; print(json.load(open('/tmp/tmdb_series.json')).get('overview','') or '')")
fi
```

### 3. Poster von TMDB + Zielverzeichnis

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
  curl -s "https://api.themoviedb.org/3/tv/$TMDB_ID/season/1?api_key=$TMDB_API_KEY&language=de" -o /tmp/tmdb_season.json
  SP=$(python3 -c "import json; print(json.load(open('/tmp/tmdb_season.json')).get('poster_path','') or '')")
  if [ -n "$SP" ]; then
    curl -s "https://image.tmdb.org/t/p/w500$SP" -o "$TARGET_DIR/Season 01/season-poster.jpg"
    cp "$TARGET_DIR/Season 01/season-poster.jpg" "$TARGET_DIR/Season 01/thumb.jpg"
  fi
fi
```

### 4. Verzeichnisstruktur (Ziel)

**Bei `TYP=series`:**
```
~/Videos/Series/SERIE/
├── poster.jpg                      ← TMDB-Serienposter
├── fanart.jpg                      ← TMDB-Hintergrund
├── Season 01/
│   ├── season-poster.jpg           ← TMDB-Staffelposter
│   ├── thumb.jpg                   ← Jellyfin-Staffel-Thumb
│   ├── SERIE - S01E01 - TITEL.mp4
│   ├── SERIE - S01E01 - TITEL-thumb.jpg     ← Episode-Thumbnail (400x600)
│   ├── SERIE - S01E01 - TITEL-backdrop.jpg  ← Episode-Backdrop (9:16 Hochkant 540x960)
│   ├── SERIE - S01E02 - TITEL.mp4
│   └── SERIE - S01E02 - TITEL-thumb.jpg
```

**Bei `TYP=movies`:**
```
~/Videos/Movies/SERIE (JAHR)/
├── poster.jpg
├── fanart.jpg
└── SERIE (JAHR).mp4
```

### 5. Metadaten + Covers + Episode-Description + Backdrop (pro Datei)

**Variante A: series**
```bash
# Synopsis kommt aus Schritt 2 (TMDB_OVERVIEW)
for FILE in sortierte Liste; do
  dur=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$FILE" 2>/dev/null || echo "600")
  thumb_time=$(python3 -c "print(int($dur * 0.15))")

  # Embedded Cover für attached_pic
  ffmpeg -y -ss "$thumb_time" -i "$FILE" -frames:v 1 -q:v 2 /tmp/ep_cover.jpg

  # Metadaten + Cover + Synopsis schreiben
  ffmpeg -y -i "$FILE" -i /tmp/ep_cover.jpg \
    -map 0:v -map 0:a -map 1 -c copy \
    -metadata title="EPISODENTITEL" \
    -metadata show="SERIE" \
    -metadata episode_id="S01EXX" \
    -metadata season_number="1" \
    -metadata date="$TMDB_YEAR" \
    -metadata genre="$TMDB_GENRES" \
    -metadata synopsis="$TMDB_OVERVIEW" \
    -metadata comment="TMDB: ★ $TMDB_RATING" \
    -metadata:s:v:1 title="Album Cover" \
    -disposition:v:1 attached_pic \
    "$TARGET_DIR/Season 01/SERIE - S01EXX - EPISODENTITEL.mp4"

  # Externes Episode-Thumbnail (400x600, Jellyfin-Episodenansicht)
  ffmpeg -y -ss "$thumb_time" -i "$FILE" -frames:v 1 -q:v 2 \
    -vf "scale=400:600:force_original_aspect_ratio=decrease,pad=400:600:(ow-iw)/2:(oh-ih)/2:color=black" \
    "$TARGET_DIR/Season 01/SERIE - S01EXX - EPISODENTITEL-thumb.jpg"

  # Externes Episode-Backdrop (9:16 Hochkant 540x960, Jellyfin-Detailansicht)
  ffmpeg -y -ss "$thumb_time" -i "$FILE" -frames:v 1 -q:v 2 \
    -vf "crop=ih*9/16:ih:(iw-ih*9/16)/2:0,scale=540:960" \
    "$TARGET_DIR/Season 01/SERIE - S01EXX - EPISODENTITEL-backdrop.jpg"

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

### 6. Abschluss

- Tabelle: Quelle → Ziel (im Series/Movies-Pfad)
- Existieren: `poster.jpg`, `fanart.jpg`, `Season XX/thumb.jpg`?
- Pro Episode: `*-thumb.jpg` + `*-backdrop.jpg` vorhanden? (prüfen, Liste zeigen)
- Synopsis via ffprobe prüfen (Stichprobe)
- Gelöschte Quelldateien

## Jellyfin-Cover-Strategie

| Datei | Wofür | Quelle |
|---|---|---|
| `poster.jpg` | Serien-Poster (Übersicht) | TMDB |
| `fanart.jpg` | Hintergrund (Detailansicht) | TMDB |
| `Season XX/thumb.jpg` | Staffel-Thumbnail | TMDB |
| `Season XX/season-poster.jpg` | Staffel-Poster | TMDB |
| `*-thumb.jpg` pro Episode | Episoden-Vorschaubild (Folgenansicht) | Frame aus Video bei 15% |
| `*-backdrop.jpg` pro Episode | Episoden-Hintergrund (Detailansicht) | Frame aus Video bei 15% (9:16 center-crop, 540x960) |
| embedded `synopsis` in Datei | Episoden-Beschreibung | TMDB-Serien-Overview |
| embedded `attached_pic` | Fallback-Cover in Datei selbst | Frame aus Video bei 15% |

→ **embedded + extern = beides vorhanden** – Jellyfin zeigt Thumbnail + Backdrop + Beschreibung in der Episodenansicht.

## Jellyfin-Einrichtung

| Bibliothek | Typ | Pfad |
|---|---|---|
| Series | TV Shows | `~/Videos/Series` |
| Movies | Movies | `~/Videos/Movies` |

Nach dem Scannen: **Bibliothek aktualisieren** in Jellyfin.

## Vorheriger Schritt

Falls du die Videos noch nicht hast, vorher den Downloader laufen lassen:

```
@mediathekwebview
Serie: Garfield
```

Dann `videotagger` auf den `./downloads/Garfield`-Ordner loslassen.

## Nächster Schritt: Komprimierung

Falls du die Dateien noch mit HEVC komprimieren willst, nutze den separaten Prompt:

```
@videokomprimierer
QUELLE: ~/Videos/Series/Garfield/Season 01/
```

## Wichtige Hinweise

- TMDB-Key in `~/.bashrc` als `export TMDB_API_KEY="..."` setzen
- `-map 0:v -map 0:a` statt `-map 0` (sonst `codec none`-Fehler)
- `episode_id="S01E05"` statt `episode_number`
- Für reines Taggen wird `-c copy` verwendet → kein Qualitätsverlust
