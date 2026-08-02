Ich möchte eine Blu-ray direkt mit makemkvcon rippen und den Hauptfilm anschließend mit ffmpeg komprimieren.

## 1. Blu-ray mit makemkvcon rippen

- Erkannte Laufwerke anzeigen: `makemkvcon -r info disc`
- Titel der Blu-ray auflisten: `makemkvcon -r info disc:0`
- Wähle daraus IMMER nur den deutschen Hauptfilm aus. Das ist in der Regel die längste Titelliste (größte Dauer). Rippe niemals alle Titel, sondern nur diesen einen.
- Stelle sicher, dass der Ordner /home/laptop/Videos/Ripping existiert (falls nicht, anlegen).
- Rippe nur den gewählten Titel:
  `makemkvcon mkv disc:0 <TITLE_ID> /home/laptop/Videos/Ripping`
- Die gerippte Datei liegt dann unter /home/laptop/Videos/Ripping (z.B. NAME_t00.mkv).

## 2. Hauptfilm mit ffmpeg komprimieren

Wähle die gerippte MKV-Datei aus und komprimiere sie mit möglichst hoher Qualität bei möglichst geringem Speicherverbrauch.

- Audio: NUR die deutsche Tonspur verwenden. Wähle den besten deutschen Stream (bevorzugt 5.1) und konvertiere ihn nach AC-3 640 kbps 5.1. Alle anderen Sprachen und doppelte Tonspuren werden verworfen.
- Untertitel: NUR deutsche und englische Untertitel behalten (je Sprache die erste Spur), den Rest verwerfen. Untertitel werden kopiert (-c:s copy).
- Prüfe die Streams vorher per `ffprobe` und passe die Stream-Indizes bzw. Sprachtags (ger/deu bzw. eng/en) entsprechend an.

Beispiel-Kommando:

ffmpeg -i input.mkv \
  -map 0:v:0 \
  -map 0:a:m:language:ger \
  -map 0:s:m:language:ger \
  -map 0:s:m:language:eng \
  -c:v av1_nvenc -preset p7 -cq 35 \
  -multipass fullres -rc-lookahead 32 \
  -spatial-aq 1 -aq-strength 12 \
  -temporal-aq 1 -b_ref_mode middle \
  -c:a ac3 -b:a 640k -c:s copy output.mkv

Das Ergebnis speicherst du unter /home/laptop/Videos/Movies. Die Zwischendatei in /home/laptop/Videos/Ripping löschst du nach erfolgreicher Komprimierung.

Bei der Benammung sollst du die Regeln von Jellyfin, die du hier findest beachten:
https://jellyfin.org/docs/general/server/media/movies/

Ich möchte dich auch bitten die Datei mit den nötigen Metadaten und mit Cover auszustatten, so das es in Jellyfin super aussiet. Falls Metadaten oder Cover schon vorhanden sind sollen diese bleiben und benutzt werden.

Erstelle auch eine dateiname.nfo mit Cast-Informationen und Profilbildern von TMDB (API-Key: 8265bd1679663a7ea12ac168da84d2e8). Rufe dafür die Credits vom Film über die TMDB API ab:

  curl -s "https://api.themoviedb.org/3/movie/<TMDB_ID>/credits?api_key=8265bd1679663a7ea12ac168da84d2e8&language=de"

Ermittle die TMDB-ID vorher über die Movie-Suche:

  curl -s "https://api.themoviedb.org/3/search/movie?api_key=8265bd1679663a7ea12ac168da84d2e8&query=<FILMTITEL>&language=de"

Füge die ersten 8-10 Hauptdarsteller mit `<name>`, `<role>` und `<thumb>` (URL: https://image.tmdb.org/t/p/original/<profile_path>) in die NFO ein. Das Cover (cover.jpg) lädst du von image.tmdb.org herunter.

Denke beim Komprimieren daran: Ich habe eine Nvidia 4060.
Das wird empfohlen: 
RTX 4060 AV1 Optimiert – Bester Kompromiss Qualität/Größe

Ergebnisse für 1080p Blu-ray (~2,5h):
- ~3,5 GB pro Film
- 8-10x Echtzeit-Encode (15-20 min)
- Full-Res Multipass + Spatial/Temporal AQ lenkt Bits in Details statt Rauschen

Alternative falls Datei zu gross:
- cq 40 (nur -cq ändern) → ~1,8 GB
