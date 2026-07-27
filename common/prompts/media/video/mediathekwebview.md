# MediathekViewWeb Downloader (nur Download)

Lade eine Serie von https://mediathekviewweb.de/ in HD-Qualität herunter.
Nur der rohe Download – keine Metadaten, keine Cover, keine Verzeichnisstruktur.
Danach mit dem `videotagger`-Prompt verarbeiten.

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

### 2. Nur HD-Ergebnisse filtern

- `url_video_hd` muss existieren und nicht leer sein
- Aus `channel` + `topic` + `title` den Dateinamen bauen
- Doppelte Titel anhand der `id` deduplizieren (gleiche Episode von KiKA und HR → größere behalten)

### 3. Herunterladen in `./downloads/SERIE/`

```bash
DOWNLOAD_DIR="./downloads/SERIE"
mkdir -p "$DOWNLOAD_DIR"

for each result with url_video_hd; do
  # Dateiname: SENDER_SERIE_EPISODENTITEL.mp4
  FILENAME=$(python3 -c "
import re
ch = 'CHANNEL'
topic = 'TOPIC'
title = 'TITLE'
name = f'{ch}_{topic}_{title}'
name = re.sub(r'[^\w\-_., ]', '_', name)
name = re.sub(r'\s+', ' ', name).strip()[:100]
print(name)
")

  if [[ "$HD_URL" == *.m3u8 ]]; then
    # HLS (ORF/ZDF) → ffmpeg
    ffmpeg -y -user_agent 'Mozilla/5.0' -i "$HD_URL" \
      -c copy -bsf:a aac_adtstoasc \
      "$DOWNLOAD_DIR/$FILENAME.mp4"
  else
    # Direkter MP4-Link → wget
    wget -q -O "$DOWNLOAD_DIR/$FILENAME.mp4" "$HD_URL"
  fi

  echo "  OK: $FILENAME.mp4 ($(du -h $DOWNLOAD_DIR/$FILENAME.mp4 | cut -f1))"
done
```

### 4. Prüfung

- Alle Dateien existieren in `./downloads/SERIE/`
- Keine < 100 KB (abgebrochene Downloads)

## Nächster Schritt

Danach den `videotagger`-Prompt aufrufen:

```
@videotagger
QUELLE: ./downloads/SERIE
TYP: series
KOMPRIMIEREN: ja
```

## Wichtige Hinweise

- ORF (Österreich) und SRF (Schweiz) sind oft geo-blocked → überspringen
- ZDF-tivi liefert oft kein HD (`url_video_hd` fehlt)
- HLS (m3u8) wird mit ffmpeg geladen, direkte MP4s mit wget
- Keine Tags, keine Cover, keine Struktur – das macht der videotagger
