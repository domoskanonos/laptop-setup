Ich habe in dem Ordner /home/laptop/docker/data/makemkv/output Filme mit makemkv gerippt.
Du sollst die richtige Filmdatei aus dem Ordner auswählen und mit ffmpeg rippen.
Dabei sollst du eine möglichst hohe Qualität mit möglichst geringem Speicherverbrauch auswählen.
Das Ergebnis sollst du unter /home/laptop/Videos/Movies speichern.

Bei der Benammung sollst du die Regeln von Jellyfin, die du hier findest beachten:
https://jellyfin.org/docs/general/server/media/movies/

Ich möchte dich auch bitten die Datei mit den nötigen Metadaten und mit Cover auszustatten, so das es in Jellyfin super aussiet. Falls Metadaten oder Cover schon vorhanden sind sollen diese bleiben und benutzt werden.

Erstelle auch eine dateiname.nfo mit Cast-Informationen und Profilbildern von TMDB (API-Key: 8265bd1679663a7ea12ac168da84d2e8). Rufe dafür die Credits vom Film über die TMDB API ab:

  curl -s "https://api.themoviedb.org/3/movie/<TMDB_ID>/credits?api_key=8265bd1679663a7ea12ac168da84d2e8&language=de"

Ermittle die TMDB-ID vorher über die Movie-Suche:

  curl -s "https://api.themoviedb.org/3/search/movie?api_key=8265bd1679663a7ea12ac168da84d2e8&query=<FILMTITEL>&language=de"

Füge die ersten 8-10 Hauptdarsteller mit `<name>`, `<role>` und `<thumb>` (URL: https://image.tmdb.org/t/p/original/<profile_path>) in die NFO ein. Das Cover (cover.jpg) lädst du von image.tmdb.org herunter.

Denke beim Rippen daran: Ich habe eine Nvidia 4060.
Das wird empfohlen: 
RTX 4060 AV1 Optimiert – Bester Kompromiss Qualität/Größe

Wähle vom Audio immer den besten/ersten Stream pro Sprache aus (Default-Track), konvertiere ihn nach AC-3 640 kbps 5.1 und ignoriere doppelte Tonspuren. Pro Sprache wird nur eine Spur behalten.

ffmpeg -i input.mkv -c:v av1_nvenc -preset p7 -cq 35 \
  -multipass fullres -rc-lookahead 32 \
  -spatial-aq 1 -aq-strength 12 \
  -temporal-aq 1 -b_ref_mode middle \
  -c:a ac3 -b:a 640k -c:s copy output.mkv

Ergebnisse für 1080p Blu-ray (~2,5h):
- ~3,5 GB pro Film
- 8-10x Echtzeit-Encode (15-20 min)
- Full-Res Multipass + Spatial/Temporal AQ lenkt Bits in Details statt Rauschen

Alternative falls Datei zu gross:
- cq 40 (nur -cq ändern) → ~1,8 GB

