# MediathekViewWeb Downloader + Metadaten + Struktur + Jellyfin-Cover

Lade eine Serie von https://mediathekviewweb.de/ in HD-Qualität herunter, schreibe Metadaten + Cover in jede Datei und lege externe Jellyfin-kompatible Cover-Dateien an.

## Parameter

| Platzhalter | Beschreibung |
|---|---|
| `SERIE` | Serienname (z.B. `Garfield`, `Pippi Langstrumpf`) |

## Vorgehen

### 1. Suche über API

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

### 2. Nur HD-Ergebnisse filtern + Staffel parsen

- `url_video_hd` muss existieren und nicht leer sein
- Aus `topic` die Staffel parsen: "Garfield Staffel 4" → Season 04, "Pippi Langstrumpf" → Season 01
- Aus `channel` den Sender notieren
- Doppelte Titel anhand der `id` deduplizieren (gleiche Episode von KiKA und HR → größere behalten)

### 3. Verzeichnisstruktur + externe Cover anlegen

```
vids/SERIE_NAME/
├── poster.jpg                 ← Jellyfin: Serien-Poster (Frame aus erster Episode)
├── Season 01/
│   ├── thumb.jpg              ← Jellyfin: Staffel-Thumbnail
│   ├── SERIE_NAME - S01E01 - EPISODENTITEL.mp4
│   └── SERIE_NAME - S01E02 - EPISODENTITEL.mp4
```

- Staffel aus `topic` parsen (Regex: `Staffel (\d+)`)
- Episodennummer: fortlaufend nach `timestamp` (Sendetermin) sortieren
- Fallback: Season 01 wenn keine Staffel parselbar

### 4. Download + Metadaten + Cover (pro Episode)

Für jeden Treffer mit `url_video_hd`:

```bash
TARGET="vids/SERIE/Season SXX/SERIE - SXXEYY - EPISODENTITEL.mp4"
mkdir -p "$(dirname "$TARGET")"

# Cover-Thumbnail extrahieren (Frame bei 10%)
ffmpeg -y -ss "$(python3 -c "print(int($(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$QUELL_URL") * 0.1))")" \
  -i "$QUELL_URL" -frames:v 1 -q:v 2 /tmp/ep_cover.jpg

# MP4 herunterladen, taggen, Cover einbetten (nur v+a Streams, kein Zeitcode!)
if [[ "$HD_URL" == *.m3u8 ]]; then
  ffmpeg -y -user_agent 'Mozilla/5.0' -i "$HD_URL" \
    -i /tmp/ep_cover.jpg \
    -map 0:v -map 0:a -map 1 \
    -c copy -bsf:a aac_adtstoasc \
    -metadata title="EPISODENTITEL" \
    -metadata show="SERIE" \
    -metadata episode_id="SXXEYY" \
    -metadata season_number="SXX" \
    -metadata date="JAHR" \
    -metadata genre="Animation/Kinder" \
    -metadata synopsis="KURZBESCHREIBUNG" \
    -metadata comment="Sender: CHANNEL" \
    -metadata:s:v:1 title="Album Cover" \
    -metadata:s:v:1 comment="Cover (front)" \
    -disposition:v:1 attached_pic \
    "$TARGET"
else
  wget -q -O /tmp/raw.mp4 "$HD_URL"
  ffmpeg -y -i /tmp/raw.mp4 -i /tmp/ep_cover.jpg \
    -map 0:v -map 0:a -map 1 \
    -c copy \
    -metadata title="EPISODENTITEL" \
    -metadata show="SERIE" \
    -metadata episode_id="SXXEYY" \
    -metadata season_number="SXX" \
    -metadata date="JAHR" \
    -metadata genre="Animation/Kinder" \
    -metadata synopsis="KURZBESCHREIBUNG" \
    -metadata comment="Sender: CHANNEL" \
    -metadata:s:v:1 title="Album Cover" \
    -metadata:s:v:1 comment="Cover (front)" \
    -disposition:v:1 attached_pic \
    "$TARGET"
  rm -f /tmp/raw.mp4
fi

# Einzelframe-Cover nachmetadata-wieder als ep_cover.jpg in Season-Ordner → Jellyfin nutzt das als Episode-Thumbnail
cp /tmp/ep_cover.jpg "$(dirname "$TARGET")/$TARGET_NAME-thumb.jpg"
rm -f /tmp/ep_cover.jpg
```

### 5. Externe Poster + Thumbnails (nach allen Downloads)

Nachdem alle Episoden einer Serie fertig sind:

```bash
SERIES_DIR="vids/SERIE"

# Series-Poster aus erstem Frame der ersten Episode
FIRST_EP=$(find "$SERIES_DIR" -name "*.mp4" -o -name "*.mkv" | sort | head -1)
if [ -n "$FIRST_EP" ]; then
  DUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$FIRST_EP")
  THUMB_TIME=$(python3 -c "print(int($DUR * 0.15))")
  ffmpeg -y -ss "$THUMB_TIME" -i "$FIRST_EP" -frames:v 1 -vf "scale=400:600:force_original_aspect_ratio=decrease,pad=400:600:(ow-iw)/2:(oh-ih)/2" \
    "$SERIES_DIR/poster.jpg"
  
  # Season-Thumbnail für jede Season
  for SEASON_DIR in "$SERIES_DIR"/Season*; do
    if [ -d "$SEASON_DIR" ]; then
      SEASON_EP=$(find "$SEASON_DIR" -name "*.mp4" -o -name "*.mkv" | sort | head -1)
      if [ -n "$SEASON_EP" ]; then
        SDUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$SEASON_EP")
        STHUMB=$(python3 -c "print(int($SDUR * 0.15))")
        ffmpeg -y -ss "$STHUMB" -i "$SEASON_EP" -frames:v 1 -vf "scale=400:600:force_original_aspect_ratio=decrease,pad=400:600:(ow-iw)/2:(oh-ih)/2" \
          "$SEASON_DIR/thumb.jpg"
      fi
    fi
  done
fi
```

Wenn TMDB-API-Key verfügbar ist (`echo $TMDB_API_KEY`), alternativ von TMDB laden:
```bash
# TMDB-Suche nach Serie
TMDB_URL=$(curl -s "https://api.themoviedb.org/3/search/tv?api_key=$TMDB_API_KEY&query=SERIE&language=de" | python3 -c "import json,sys; d=json.load(sys.stdin); results=d.get('results',[]); print(results[0]['poster_path'] if results else '')")
if [ -n "$TMDB_URL" ]; then
  curl -s "https://image.tmdb.org/t/p/w500$TMDB_URL" -o "$SERIES_DIR/poster.jpg"
fi
```

### 6. Prüfung

- Alle Zieldateien existieren mit > 100 KB
- Per Stichprobe ffprobe: Tags sichtbar (title, show, episode_id, season_number, synopsis, date)
- Per Stichprobe: attached_pic Stream vorhanden (embedded Cover)
- `poster.jpg` und `thumb.jpg` existieren in den Verzeichnissen
- Auflösung per Stichprobe prüfen (sollte 1280x720 oder 1920x1080 sein)

## Jellyfin-Hinweise

- `poster.jpg` im Serien-Root → Jellyfin: Serien-Poster
- `Season XX/thumb.jpg` → Jellyfin: Staffel-Thumbnail
- `Season XX/*-thumb.jpg` → Jellyfin: Episoden-Thumbnail (optional)
- Embedded `attached_pic` → Jellyfin liest es, externes `poster.jpg` hat aber Vorrang
- `season_number` und `episode_id` → Jellyfin nutzt `SxxExx` aus Dateinamen + embedded Tags
- Falls Jellyfin trotzdem kein Cover zeigt → `Bibliothek scannen` (Metadaten aktualisieren) in Jellyfin auslösen

## Wichtige Hinweise

- ORF (Österreich) und SRF (Schweiz) sind oft geo-blocked → entweder überspringen oder mit `-headers "Referer: https://on.orf.at/"` versuchen
- ZDF-tivi liefert oft kein HD (`url_video_hd` fehlt) → nur KiKA/ARD/ORF/ZDF-Hauptsender nehmen
- `episode_number` wird von ffmpegs MP4-Muxer nicht unterstützt → stattdessen `episode_id="S01E05"` verwenden
- Immer `-map 0:v -map 0:a` statt `-map 0` verwenden → sonst bricht ffmpeg an Zeitcode-Spuren (`codec none`) ab
