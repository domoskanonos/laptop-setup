# Video-Tagger + Organizer + optionaler Komprimierer

Taggt, ordnet und komprimiert nachträglich einen Ordner mit heruntergeladenen Videodateien.
Schreibt Jellyfin-kompatible Metadaten + externe Cover-Dateien (`poster.jpg`, `thumb.jpg`).

## Parameter

| Platzhalter | Pflicht | Beschreibung |
|---|---|---|
| `QUELLE` | ja | Ordner mit den Videos (z.B. `./vids/pipi`) |
| `SERIE` | nein | Serienname (wenn nicht angegeben, aus Dateinamen extrahiert) |
| `KOMPRIMIEREN` | nein | `ja` oder `nein` (default: `nein`) |

## Vorgehen

### 1. Dateien scannen + Seriennamen ermitteln

```bash
ls -1 "QUELLE"/*.mp4 QUELLE/*.mkv 2>/dev/null
```

Aus jedem Dateinamen parsen:
- Sender (Präfix vor erstem `_`, z.B. `KiKA`, `HR`, `ZDF`)
- Serienname (falls `SERIE` nicht angegeben): aus dem Dateinamen die gemeinsame Topic extrahieren (z.B. aus `KiKA_Pippi Langstrumpf_Pippi auf der Walz.mp4` → `Pippi Langstrumpf`, aus `HR_Garfield_Monster Odie.mp4` → `Garfield`)

**Seriennamen-Extraktion aus Dateinamen:**
```
Muster: SENDER_SERIE_EPISODENTITEL
KiKA_Garfield_Rollenwechsel.mp4       → Serie: Garfield,      Titel: Rollenwechsel
HR_Garfield_Monster Odie.mp4          → Serie: Garfield,      Titel: Monster Odie
KiKA_Pippi Langstrumpf_Pippi auf der Walz (1).mp4 → Serie: Pippi Langstrumpf, Titel: Pippi auf der Walz (1)
```

### 2. Teil-Videos zusammenführen

Erkennen ob eine Episode auf mehrere Dateien aufgeteilt ist (z.B. `- Teil 1`, `- Teil 2` oder `_1_`, `_2_` oder `(1)`, `(2)`) und mit ffmpeg concat zu einer Datei zusammenführen.

**Erkennungslogik:**
1. Aus jedem Dateinamen den Teil-Suffix entfernen: `- Teil (\d+)`, `_(\d+)_`, `\((\d+)\)`, `Teil (\d+)` am Ende des Titels
2. Files mit gleichem Base-Namen (ohne Teil-Suffix) gruppieren
3. Gruppen mit 2+ Files → Parts derselben Episode → nur zusammenführen wenn jede Part < 10 Min (sonst sind es eigene Episoden)

**Ablauf pro Gruppe:**
```bash
FILES=( sortierte Liste der Parts )

CONCAT_FILE=$(mktemp)
for f in "${FILES[@]}"; do
  echo "file '$(realpath "$f")'" >> "$CONCAT_FILE"
done

# Zusammenführen (Stream Copy → kein Qualitätsverlust)
ffmpeg -y -f concat -safe 0 -i "$CONCAT_FILE" -c copy \
  "QUELLE/EPISODENTITEL.mp4"
rm "$CONCAT_FILE"
rm "${FILES[@]}"
```

**Hinweise:**
- `-f concat -c copy` nur wenn alle Parts identische Codec-Parameter haben (ARD/ORF-MP4s: meist der Fall)
- Falls Fehler (codec mismatch) → mit Re-Encode versuchen: `ffmpeg -y -f concat -safe 0 -i "$CONCAT_FILE" -c:v h264_nvenc -cq 20 -c:a aac "ZIEL.mp4"`
- Die Metadaten + Cover werden erst in Schritt 4 auf das zusammengeführte Video geschrieben

### 3. Verzeichnisstruktur + externe Cover anlegen

```
QUELLE/SERIE/
├── poster.jpg              ← Jellyfin: Serien-Poster (wird in Schritt 5 erzeugt)
├── Season 01/
│   ├── thumb.jpg           ← Jellyfin: Staffel-Thumbnail (wird in Schritt 5 erzeugt)
│   ├── SERIE - S01E01 - EPISODENTITEL.mp4
│   └── SERIE - S01E01 - EPISODENTITEL-thumb.jpg (optional: Episoden-Thumbnail)
```

- Wenn kein Staffel-/Episoden-Parsing möglich → chronologisch sortieren nach Dateidatum
- Fallback: Season 01, Episoden fortlaufend (E01, E02, ...)
- Bestehende Dateien nicht überschreiben

### 4. Metadaten + Cover schreiben (pro Datei)

```bash
# Thumbnail extrahieren (10% des Videos)
DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "EINGANG.mp4")
THUMB_TIME=$(python3 -c "print(int($DURATION * 0.1))")

ffmpeg -y -ss "$THUMB_TIME" -i "EINGANG.mp4" -frames:v 1 -q:v 2 /tmp/ep_cover.jpg

# Metadaten + Cover in MP4 schreiben (nur v+a Streams mappen → kein codec-none-Fehler!)
ffmpeg -y -i "EINGANG.mp4" -i /tmp/ep_cover.jpg \
  -map 0:v -map 0:a -map 1 \
  -c copy \
  -metadata title="EPISODENTITEL" \
  -metadata show="SERIE" \
  -metadata episode_id="SXXEYY" \
  -metadata season_number="SXX" \
  -metadata date="JAHR" \
  -metadata genre="Animation/Kinder" \
  -metadata synopsis="BESCHREIBUNG" \
  -metadata comment="Quelle: MediathekViewWeb" \
  -metadata:s:v:1 title="Album Cover" \
  -metadata:s:v:1 comment="Cover (front)" \
  -disposition:v:1 attached_pic \
  "vids/SERIE/Season SXX/SERIE - SXXEYY - EPISODENTITEL.mp4"

# Auch externes Episoden-Thumbnail speichern (Jellyfin kompatibel)
cp /tmp/ep_cover.jpg "$(dirname "$ZIEL")/SERIE - SXXEYY - EPISODENTITEL-thumb.jpg"

rm -f /tmp/ep_cover.jpg
rm -f "EINGANG.mp4"  # nur löschen wenn erfolgreich
```

### 5. Externe Poster + Season-Thumbnails (nach allen Dateien)

Nachdem alle Episoden einer Serie verarbeitet sind:

```bash
SERIES_DIR="vids/SERIE"

# Serien-Poster aus erstem Frame der ersten Episode
FIRST_EP=$(find "$SERIES_DIR" -name "*.mp4" -o -name "*.mkv" | sort | head -1)
if [ -n "$FIRST_EP" ]; then
  DUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$FIRST_EP")
  THUMB_TIME=$(python3 -c "print(int($DUR * 0.15))")
  ffmpeg -y -ss "$THUMB_TIME" -i "$FIRST_EP" -frames:v 1 \
    -vf "scale=400:600:force_original_aspect_ratio=decrease,pad=400:600:(ow-iw)/2:(oh-ih)/2" \
    "$SERIES_DIR/poster.jpg"

  # Season-Thumbnail für jede Season
  for SEASON_DIR in "$SERIES_DIR"/Season*; do
    if [ -d "$SEASON_DIR" ]; then
      SEASON_EP=$(find "$SEASON_DIR" -name "*.mp4" -o -name "*.mkv" | sort | head -1)
      if [ -n "$SEASON_EP" ]; then
        SDUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$SEASON_EP")
        STHUMB=$(python3 -c "print(int($SDUR * 0.15))")
        ffmpeg -y -ss "$STHUMB" -i "$SEASON_EP" -frames:v 1 \
          -vf "scale=400:600:force_original_aspect_ratio=decrease,pad=400:600:(ow-iw)/2:(oh-ih)/2" \
          "$SEASON_DIR/thumb.jpg"
      fi
    fi
  done
fi
```

Optional: Über TMDB-API bessere Poster laden (falls `$TMDB_API_KEY` gesetzt):
```bash
TMDB_URL=$(curl -s "https://api.themoviedb.org/3/search/tv?api_key=$TMDB_API_KEY&query=SERIE&language=de" | python3 -c "import json,sys; d=json.load(sys.stdin); r=d.get('results',[]); print(r[0]['poster_path'] if r else '')")
[ -n "$TMDB_URL" ] && curl -s "https://image.tmdb.org/t/p/w500$TMDB_URL" -o "$SERIES_DIR/poster.jpg"
```

### 6. Optional: Komprimierung mit HEVC NVENC

Nur wenn `KOMPRIMIEREN=ja` und folgende Bedingungen erfüllt:
- Datei > 100 MB (kleinere lohnt nicht)
- Noch nicht HEVC-codiert (prüfen mit `ffprobe -v quiet -select_streams v:0 -show_entries stream=codec_name`)
- Voraussichtliche Ersparnis > 30%

```bash
ORIG_SIZE=$(stat --format=%s "EINGANG.mp4")
ORIG_BITRATE=$(ffprobe -v quiet -show_entries format=bit_rate -of csv=p=0 "EINGANG.mp4")

if (( $(echo "$ORIG_BITRATE < 1500000" | bc -l) )); then
  echo "  -> Übersprungen: Bitrate ${ORIG_BITRATE} zu niedrig"
  continue
fi

# Komprimieren mit hoher Qualität
ffmpeg -y -hwaccel cuda -i "EINGANG.mp4" \
  -c:v hevc_nvenc -preset p6 -cq 20 -rc constqp \
  -c:a aac -b:a 128k \
  "VORSCHLAG.mkv"

COMP_SIZE=$(stat --format=%s "VORSCHLAG.mkv")
SAVING=$(python3 -c "print(f'{(1-$COMP_SIZE/$ORIG_SIZE)*100:.1f}')")

if (( $(echo "$COMP_SIZE < $ORIG_SIZE * 0.7" | bc -l) )); then
  mv "VORSCHLAG.mkv" "vids/SERIE/Season SXX/SERIE - SXXEYY - EPISODENTITEL.mkv"
  echo "  -> Komprimiert: ${ORIG_SIZE}MB → ${COMP_SIZE}MB (${SAVING}% Ersparnis)"
else
  rm -f "VORSCHLAG.mkv"
  echo "  -> Nicht komprimiert: nur ${SAVING}% Ersparnis (Schwelle: 30%)"
fi
```

**Qualitäts-Parameter:**
- `-cq 18`: nahezu verlustfrei (sehr konservativ)
- `-cq 20`: ausgezeichnete Qualität, gute Kompression (empfohlen)
- `-cq 22`: gute Qualität, mehr Kompression

→ Standard `-cq 20` verwenden für den besten Kompromiss.

### 7. Abschluss

- Tabelle der verarbeiteten Dateien ausgeben (Quelle → Ziel + Größe + Auflösung + Codec)
- Bei Komprimierung: Ersparnis pro Datei und gesamt anzeigen
- Existieren `poster.jpg` und `thumb.jpg`? → prüfen und anzeigen
- Gelöschte Quelldateien auflisten

## Jellyfin-Hinweise

- `poster.jpg` im Serien-Root → Jellyfin liest es als Serien-Poster
- `Season XX/thumb.jpg` → Jellyfin liest es als Staffel-Thumbnail
- Embedded `attached_pic` → Jellyfin liest es, externes `poster.jpg` hat aber Vorrang
- `season_number` + `episode_id` (embedded) + `SxxExx` im Dateinamen → Jellyfin erkennt Episoden
- Falls Jellyfin trotzdem kein Cover zeigt → `Bibliothek scannen` (Metadaten aktualisieren) auslösen

## Wichtige Hinweise

- NVENC erfordert NVIDIA GPU (prüfen mit `ffmpeg -encoders 2>/dev/null | grep hevc_nvenc`)
- Ohne GPU fällt `-c:v libx265` Software-Encoding extrem langsam aus → in dem Fall Kompression überspringen
- `episode_number` wird von ffmpegs MP4-Muxer nicht unterstützt → stattdessen `episode_id="S01E05"` verwenden
- Für reines Taggen (ohne Kompression) wird `-c copy` verwendet → kein Qualitätsverlust, schnell
- Immer `-map 0:v -map 0:a` statt `-map 0` verwenden → sonst bricht ffmpeg an Zeitcode-Spuren (`codec none`) ab
