# MediathekViewWeb Downloader + Metadaten + Struktur

Lade eine Serie von https://mediathekviewweb.de/ in HD-Qualität herunter, schreibe Metadaten in die MP4-Dateien und ordne sie in die korrekte Verzeichnisstruktur ein.

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
- Doppelte Titel anhand der `id` deduplizieren (gleiche Episode von KiKA und HR)

### 3. Verzeichnisstruktur anlegen

```
vids/SERIE_NAME/Season SXX/SERIE_NAME - SXXEYY - EPISODENTITEL.mp4
```

Beispiele:
```
vids/Garfield/Season 01/Garfield - S01E01 - Rollenwechsel.mp4
vids/Pippi Langstrumpf/Season 01/Pippi Langstrumpf - S01E01 - Pippis neue Freunde.mp4
```

- Staffel aus `topic` parsen (Regex: `Staffel (\d+)`)
- Episodennummer: fortlaufend nach `timestamp` (Sendetermin) sortieren
- Fallback: Season 01 wenn keine Staffel parselbar

### 4. Download + Metadaten + Cover

Für jeden Treffer mit `url_video_hd`:

```bash
mkdir -p "vids/SERIE/Season SXX"

# Thumbnail extrahieren (Frame bei 5 Min oder 10%)
ffmpeg -y -ss 300 -i "QUELL_URL" -frames:v 1 -q:v 2 /tmp/cover.jpg

# MP4 herunterladen + Metadaten schreiben + Cover einbetten
if [[ "$HD_URL" == *.m3u8 ]]; then
  # HLS (ORF/ZDF) → ffmpeg
  ffmpeg -y -user_agent 'Mozilla/5.0' \
    -i "$HD_URL" \
    -i /tmp/cover.jpg \
    -map 0 -map 1 \
    -c copy -bsf:a aac_adtstoasc \
    -metadata title="EPISODENTITEL" \
    -metadata show="SERIE" \
    -metadata episode_id="SXXEYY" \
    -metadata season_number="SXX" \
    -metadata genre="Animation/Kinder" \
    -metadata comment="Sender: CHANNEL" \
    -metadata:s:v:1 title="Album Cover" \
    -metadata:s:v:1 comment="Cover (front)" \
    -disposition:v:1 attached_pic \
    "ZIEL.mp4"
else
  # Direkter MP4-Link (KiKA/ARD) → wget + tagging
  wget -q -O /tmp/raw.mp4 "$HD_URL"
  ffmpeg -y -i /tmp/raw.mp4 -i /tmp/cover.jpg \
    -map 0 -map 1 \
    -c copy \
    -metadata title="EPISODENTITEL" \
    -metadata show="SERIE" \
    -metadata episode_id="SXXEYY" \
    -metadata season_number="SXX" \
    -metadata genre="Animation/Kinder" \
    -metadata comment="Sender: CHANNEL" \
    -metadata:s:v:1 title="Album Cover" \
    -metadata:s:v:1 comment="Cover (front)" \
    -disposition:v:1 attached_pic \
    "ZIEL.mp4"
  rm -f /tmp/raw.mp4
fi

rm -f /tmp/cover.jpg
```

### 5. Prüfung

- Alle Zieldateien existieren mit > 100 KB
- Per Stichprobe ffprobe: Tags sichtbar (title, show, episode_id, season_number)
- Per Stichprobe: attached_pic Stream vorhanden (cover)
- Auflösung per Stichprobe prüfen (sollte 1280x720 oder 1920x1080 sein)

## Wichtige Hinweise

- ORF (Österreich) und SRF (Schweiz) sind oft geo-blocked → entweder überspringen oder mit entsprechendem `-headers "Referer: https://on.orf.at/"` versuchen
- ZDF-tivi liefert oft kein HD (`url_video_hd` fehlt) → nur KiKA/ARD/ORF/ZDF-Hauptsender nehmen
- `episode_number` wird von ffmpegs MP4-Muxer nicht unterstützt → stattdessen `episode_id="S01E05"` verwenden
