Ich möchte eine Blu-ray direkt mit makemkvcon rippen und den Hauptfilm (oder bei einer Serie die einzelnen Episoden) anschließend mit ffmpeg komprimieren.

## 0. Bestimmen: Film oder Serie?

- Der Nutzer kann es ansagen (z.B. „serie bitte rippen“) – dann ist es eine Serie.
- Sonst selbst erkennen: Du kennst Serien in der Regel selbst (Disc-Name entspricht einer bekannten Serie). Zusätzlich hilft die Disc-Analyse: Mehrere ähnlich lange Titel à ~40-60 Minuten statt einem einzelnen ~2h-Titel deuten auf eine Serie hin.
- Bei Unsicherheit den Nutzer fragen, ob es sich um einen Film oder eine Serie handelt.

Danach den passenden Ablauf ausführen: Abschnitt 1-3 für Filme, Abschnitt 4-6 für Serien.

## 1. Blu-ray (Film) mit makemkvcon rippen

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
- Prüfe die Streams vorher per `ffprobe` und passe die Stream-Indizes bzw. Sprachtags (ger/deu bzw. eng/en) entsprechend an. Verwende nach Möglichkeit explizite Stream-Indizes (z.B. -map 0:5), da Sprache-Filter wie -map 0:a:m:language:deu ALLE passenden Streams ziehen und zu Duplikaten führen können.

Beispiel-Kommando (Stream-Indizes nach ffprobe-Ergebnis anpassen):

ffmpeg -i input.mkv \
  -map 0:0 \
  -map 0:<DEU_AUDIO_INDEX> \
  -map 0:<DEU_SUB_INDEX> \
  -map 0:<ENG_SUB_INDEX> \
  -c:v av1_nvenc -preset p7 -cq 35 \
  -multipass fullres -rc-lookahead 32 \
  -spatial-aq 1 -aq-strength 12 \
  -temporal-aq 1 -b_ref_mode middle \
  -c:a ac3 -b:a 640k -c:s copy output.mkv

Füge außerdem korrekte Metadaten-Tags hinzu (z.B. -metadata:s:a:0 language=deu title="Deutsch AC3 5.1").

## 3. Metadaten, Cover und NFO (Film)

Das Ergebnis speicherst du unter /home/laptop/Videos/Movies. Die Zwischendatei in /home/laptop/Videos/Ripping löschst du nach erfolgreicher Komprimierung.

Bei der Benammung sollst du die Regeln von Jellyfin, die du hier findest beachten:
https://jellyfin.org/docs/general/server/media/movies/

Ich möchte dich auch bitten die Datei mit den nötigen Metadaten und mit Cover auszustatten, so das es in Jellyfin super aussiet. Falls Metadaten oder Cover schon vorhanden sind sollen diese bleiben und benutzt werden.

Erstelle auch eine dateiname.nfo mit Cast-Informationen und Profilbildern von TMDB (API-Key: 8265bd1679663a7ea12ac168da84d2e8). Rufe dafür die Credits vom Film über die TMDB API ab:

  curl -s "https://api.themoviedb.org/3/movie/<TMDB_ID>/credits?api_key=8265bd1679663a7ea12ac168da84d2e8&language=de"

Ermittle die TMDB-ID vorher über die Movie-Suche:

  curl -s "https://api.themoviedb.org/3/search/movie?api_key=8265bd1679663a7ea12ac168da84d2e8&query=<FILMTITEL>&language=de"

Füge die ersten 8-10 Hauptdarsteller mit `<name>`, `<role>` und `<thumb>` (URL: https://image.tmdb.org/t/p/original/<profile_path>) in die NFO ein. Das Cover (cover.jpg) lädst du von image.tmdb.org herunter.

Ablage-Struktur (Jellyfin-Filmformat):

  /home/laptop/Videos/Movies/<Filmtitel> (Jahr) [tmdbid-<ID>]/
    <Filmtitel> (Jahr) [tmdbid-<ID>].mkv
    <Filmtitel> (Jahr) [tmdbid-<ID>].nfo
    cover.jpg
    backdrop.jpg

## 4. Blu-ray (Serie) mit makemkvcon rippen

- Erkannte Laufwerke anzeigen: `makemkvcon -r info disc`
- Titel der Blu-ray auflisten: `makemkvcon -r info disc:0`
- Identifiziere die Episoden-Titel der Serie (typischerweise mehrere Titel à ~40-60 Minuten). Kurze Extras/Behind-the-Scenes überspringen. Echte Specials/Weihnachtsfolgen, die zu keiner regulären Staffel gehören, kommen in `Season 00`.
- Stelle sicher, dass der Ordner /home/laptop/Videos/Ripping existiert (falls nicht, anlegen).
- Rippe JEDE Episoden-Titelliste einzeln:
  `makemkvcon mkv disc:0 <TITLE_ID> /home/laptop/Videos/Ripping`
- Die gerippten Dateien liegen dann unter /home/laptop/Videos/Ripping.

## 5. Episoden mit ffmpeg komprimieren

Für jede gerippte MKV-Datei einzeln durchführen – identische Regeln wie beim Film (Abschnitt 2):

- Audio: NUR die deutsche Tonspur (bevorzugt 5.1), konvertiert nach AC-3 640 kbps.
- Untertitel: NUR deutsche und englische (je Sprache die erste Spur), per -c:s copy.
- Streams vorher per `ffprobe` prüfen und explizite Stream-Indizes verwenden.

ffmpeg -i episode.mkv \
  -map 0:0 \
  -map 0:<DEU_AUDIO_INDEX> \
  -map 0:<DEU_SUB_INDEX> \
  -map 0:<ENG_SUB_INDEX> \
  -c:v av1_nvenc -preset p7 -cq 35 \
  -multipass fullres -rc-lookahead 32 \
  -spatial-aq 1 -aq-strength 12 \
  -temporal-aq 1 -b_ref_mode middle \
  -c:a ac3 -b:a 640k -c:s copy output.mkv

## 6. Metadaten, Cover und NFO (Serie)

Die Zwischendateien in /home/laptop/Videos/Ripping löschst du nach erfolgreicher Komprimierung.

Bei der Benammung sollst du die Regeln von Jellyfin, die du hier findest beachten:
https://jellyfin.org/docs/general/server/media/shows/

- Ermittle die Serie per TMDB-Serie-Suche:
  `curl -s "https://api.themoviedb.org/3/search/tv?api_key=8265bd1679663a7ea12ac168da84d2e8&query=<SERIENNAME>&language=de"`
- Rufe Serien-Details, Credits und Staffeln ab:
  `curl -s "https://api.themoviedb.org/3/tv/<TMDB_ID>?api_key=8265bd1679663a7ea12ac168da84d2e8&language=de"`
  `curl -s "https://api.themoviedb.org/3/tv/<TMDB_ID>/credits?api_key=8265bd1679663a7ea12ac168da84d2e8&language=de"`
  `curl -s "https://api.themoviedb.org/3/tv/<TMDB_ID>/season/<N>?api_key=8265bd1679663a7ea12ac168da84d2e8&language=de"`
- Ordne jede gerippte Episode einer Staffel/Episodennummer zu: Vergleiche die Episodentitel der Disc mit den `name`-Feld der TMDB-Staffelabfrage. Fallback, wenn kein Titel-Abgleich möglich ist: Disc-Reihenfolge (erster Titel = E01).

Ablage-Struktur (Jellyfin-Serienformat):

  /home/laptop/Videos/Series/<Serienname> (Jahr) [tmdbid-<ID>]/
    tvshow.nfo
    poster.jpg
    backdrop.jpg
    Season 01/
      season.nfo
      poster.jpg
      <Serienname> - S01E01 - <Episodentitel>.mkv
      <Serienname> - S01E01 - <Episodentitel>.nfo
      ...
    Season 02/
      ...

- tvshow.nfo: Serien-NFO mit Root-Element `<tvshow>` (title, year, premiered, rating, plot, genre, id, tmdbid, uniqueid type="tmdb") und den ersten 8-10 Hauptdarstellern mit `<name>`, `<role>`, `<thumb>` (Profilbilder von https://image.tmdb.org/t/p/original/<profile_path>).
- season.nfo: Staffel-NFO mit Root-Element `<season>` (enthält seasonnumber).
- <Episoden>.nfo: Episoden-NFO mit Root-Element `<episodedetails>` (title, season, episode, plot, rating, aired, uniqueid type="tmdb").
- poster.jpg (Serien-Poster) und backdrop.jpg aus der TMDB-Serienabfrage (poster_path/backdrop_path) herunterladen; poster.jpg der Staffel aus der Staffelabfrage (poster_path). Basis: https://image.tmdb.org/t/p/original/

## Hinweise zum Komprimieren (gilt für Film UND Serie)

Denke beim Komprimieren daran: Ich habe eine Nvidia 4060.
Das wird empfohlen: 
RTX 4060 AV1 Optimiert – Bester Kompromiss Qualität/Größe

Ergebnisse für 1080p Blu-ray (~2,5h):
- ~3,5 GB pro Film
- 8-10x Echtzeit-Encode (15-20 min)
- Full-Res Multipass + Spatial/Temporal AQ lenkt Bits in Details statt Rauschen

Alternative falls Datei zu gross:
- cq 40 (nur -cq ändern) → ~1,8 GB
