Ich habe in dem Ordner /home/laptop/docker/data/makemkv/output Filme mit makemkv gerippt.
Du sollst die richtige Filmdatei aus dem Ordner auswählen und mit ffmpeg rippen.
Dabei sollst du eine möglichst hohe Qualität mit möglichst geringem Speicherverbrauch auswählen.
Das Ergebnis sollst du unter /home/laptop/Videos/Movies speichern.

Bei der Benammung sollst du die Regeln von Jellyfin, die du hier findest beachten:
https://jellyfin.org/docs/general/server/media/movies/

Ich möchte dich auch bitten die Datei mit den nötigen Metadaten und mit Cover auszustatten, so das es in Jellyfin super aussiet. Falls Metadaten oder Cover schon vorhanden sind sollen diese bleiben und benutzt werden.

Denke beim Rippen daran: Ich habe eine Nvidia 4060.
Das wird empfohlen: 
RTX 4060 AV1 Optimiert – Bester Kompromiss Qualität/Größe

ffmpeg -i input.mkv -c:v av1_nvenc -preset p7 -cq 35 \
  -multipass fullres -rc-lookahead 32 \
  -spatial-aq 1 -aq-strength 12 \
  -temporal-aq 1 -b_ref_mode middle \
  -c:a copy output.mkv

Ergebnisse für 1080p Blu-ray (~2,5h):
- ~3,5 GB pro Film
- 8-10x Echtzeit-Encode (15-20 min)
- Full-Res Multipass + Spatial/Temporal AQ lenkt Bits in Details statt Rauschen

Alternative falls Datei zu gross:
- cq 40 (nur -cq ändern) → ~1,8 GB

