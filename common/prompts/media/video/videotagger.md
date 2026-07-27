# Video-Tagger + Organizer + optionaler Komprimierer

Taggt, ordnet und komprimiert nachträglich einen Ordner mit heruntergeladenen Videodateien.

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

Erkennen ob eine Episode auf mehrere Dateien aufgeteilt ist (z.B. `Teil 1`, `Teil 2` oder `_1_`, `_2_` oder ` 1`, ` 2`  oder `1 `, `2 ` oder `(1)`, `(2)`) und mit ffmpeg concat zu einer Datei zusammenführen.

**Erkennungslogik:**
1. Aus jedem Dateinamen den Teil-Suffix entfernen: `- Teil (\d+)`, `_(\d+)_`, `\((\d+)\)`, `Teil (\d+)` am Ende des Titels
2. Files mit gleichem Base-Namen (ohne Teil-Suffix) gruppieren
3. Gruppen mit 2+ Files → Parts derselben Episode → sortieren nach Teilnummer

**Ablauf pro Gruppe:**
```bash
# Dateien nach Teilnummer sortieren
FILES=(
  "KiKA_Pippi Langstrumpf_Pippi auf der Walz (1).mp4"
  "KiKA_Pippi Langstrumpf_Pippi auf der Walz (2).mp4"
)

# Concat-Dateiliste erstellen
CONCAT_FILE=$(mktemp)
for f in "${FILES[@]}"; do
  echo "file '$(realpath "$f")'" >> "$CONCAT_FILE"
done

# Zusammenführen (Stream Copy, kein Re-Encode → kein Qualitätsverlust)
ffmpeg -y -f concat -safe 0 -i "$CONCAT_FILE" -c copy \
  "QUELLE/KiKA_Pippi Langstrumpf_Pippi auf der Walz.mp4"
rm "$CONCAT_FILE"

# Einzelteile löschen
rm "${FILES[@]}"
```

**Hinweise:**
- `-f concat -c copy` funktioniert nur wenn alle Parts identische Codec-Parameter haben (gleiche Auflösung, gleiches Codec-Profile) – bei ARD/ORF-MP4s ist das meist der Fall
- Falls Fehler (codec mismatch) → mit Re-Encode versuchen: `ffmpeg -y -f concat -safe 0 -i "$CONCAT_FILE" -c:v h264_nvenc -cq 20 -c:a aac "ZIEL.mp4"`
- Die Metadaten + Cover werden erst in Schritt 4 auf das zusammengeführte Video geschrieben

### 3. Verzeichnisstruktur anlegen

```
vids/SERIE/Season SXX/SERIE - SXXEYY - EPISODENTITEL.mp4
```

- Wenn kein Staffel-/Episoden-Parsing möglich → chronologisch sortieren nach Dateidatum
- Fallback: Season 01, Episoden fortlaufend (E01, E02, ...)
- Bestehende Dateien nicht überschreiben

### 4. Metadaten + Cover schreiben

Pro Datei:

```bash
# Thumbnail extrahieren (10% des Videos)
DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "EINGANG.mp4")
THUMB_TIME=$(python3 -c "print(int($DURATION * 0.1))")

ffmpeg -y -ss "$THUMB_TIME" -i "EINGANG.mp4" -frames:v 1 -q:v 2 /tmp/cover.jpg

# Metadaten + Cover in MP4 schreiben
ffmpeg -y -i "EINGANG.mp4" -i /tmp/cover.jpg \
  -map 0 -map 1 \
  -c copy \
  -metadata title="EPISODENTITEL" \
  -metadata show="SERIE" \
  -metadata episode_id="SXXEYY" \
  -metadata season_number="SXX" \
  -metadata comment="Quelle: MediathekViewWeb" \
  -metadata:s:v:1 title="Album Cover" \
  -metadata:s:v:1 comment="Cover (front)" \
  -disposition:v:1 attached_pic \
  "vids/SERIE/Season SXX/SERIE - SXXEYY - EPISODENTITEL.mp4"

rm -f /tmp/cover.jpg
rm -f "EINGANG.mp4"  # nur löschen wenn erfolgreich
```

### 5. Optional: Komprimierung mit HEVC NVENC

Nur wenn `KOMPRIMIEREN=ja` und folgende Bedingungen erfüllt:
- Datei > 100 MB (kleinere lohnt nicht)
- Noch nicht HEVC-codiert (prüfen mit `ffprobe -v quiet -select_streams v:0 -show_entries stream=codec_name`)
- Voraussichtliche Ersparnis > 30%

```bash
# Bitrate ermitteln
ORIG_SIZE=$(stat --format=%s "EINGANG.mp4")
ORIG_BITRATE=$(ffprobe -v quiet -show_entries format=bit_rate -of csv=p=0 "EINGANG.mp4")

# Wenn Bitrate < 1.5 Mbps → überspringen (schon klein)
if (( $(echo "$ORIG_BITRATE < 1500000" | bc -l) )); then
  echo "  -> Übersprungen: Bitrate ${ORIG_BITRATE} zu niedrig"
  continue
fi

# Komprimieren mit hoher Qualität
ffmpeg -y -hwaccel cuda -i "EINGANG.mp4" \
  -c:v hevc_nvenc -preset p6 -cq 20 -rc constqp \
  -c:a aac -b:a 128k \
  "VORSCHLAG.mkv"

# Wenn < 70% der Originalgröße → ersetzen, sonst Original behalten
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

### 6. Abschluss

- Tabelle der verarbeiteten Dateien ausgeben (Quelle → Ziel + Größe)
- Bei Komprimierung: Ersparnis pro Datei und gesamt anzeigen
- Gelöschte Quelldateien auflisten

## Wichtige Hinweise

- NVENC erfordert NVIDIA GPU (prüfen mit `ffmpeg -encoders 2>/dev/null | grep hevc_nvenc`)
- Ohne GPU fällt `-c:v libx265` Software-Encoding extrem langsam aus → in dem Fall Kompression überspringen
- `episode_number` wird von ffmpegs MP4-Muxer nicht unterstützt → stattdessen `episode_id="S01E05"` verwenden
- Für reines Taggen (ohne Kompression) wird `-c copy` verwendet → kein Qualitätsverlust, schnell
