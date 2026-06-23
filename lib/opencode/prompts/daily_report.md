# Daily Report – Prompt for LLM

Erstelle einen täglichen Report (Daily Report) im EPUB-Format. Der Report soll die folgenden drei Informationsblöcke enthalten und in einem ansprechenden, lesbaren Layout formatiert werden.

## Datenquellen / Abzufragende Informationen

1. **Veranstaltungen in der Nähe von Dortmund (heutiger Tag)**
   - Suche mit einer Web-Suche nach Events, Konzerten, Ausstellungen oder sonstigen Veranstaltungen in Dortmund und Umgebung für das heutige Datum.
   - Gib eine kurze Liste mit Titel, Ort und ggf. Uhrzeit/Uhrzeitrahmen aus.

2. **Aktueller Bitcoin-Kurs**
   - Rufe den aktuellen Bitcoin-Kurs in EUR ab (z. B. über eine Web-Suche oder eine API wie CoinGecko / CoinDesk).
   - Gib den Preis, die 24h-Veränderung in Prozent und den Zeitpunkt der Abfrage an.

3. **Aktuelle Temperatur in Dortmund**
   - Ermittle die aktuelle Temperatur in Dortmund (z. B. via Web-Suche oder Open-Meteo-API).
   - Gib die Temperatur in °C sowie eine kurze Wetterbeschreibung (z. B. „sonnig“, „bewölkt“, „Regen“) an.

## Ausgabe

- Konvertiere den Report ins **EPUB-Format** (z. B. mit MCP Pandoc).
- Speichere die Datei unter:  
  `~/Dokumente/daily-report_<YYYY-MM-DD>.epub`
- Der Dateiname soll das aktuelle Datum im ISO-Format (YYYY-MM-DD) enthalten.

## Formatierung

- Verwende eine klare Überschriftenstruktur:
  - `# Daily Report – <Datum>`
  - `## Veranstaltungen in Dortmund`
  - `## Bitcoin Kurs`
  - `## Wetter in Dortmund`
- Jeder Abschnitt soll durch einen lesbaren Fließtext oder eine knappe Liste dargestellt werden.
- Füge am Ende einen Footer mit dem Erstellungsdatum und -uhrzeit ein.

## Beispielhafter Ablauf (als Empfehlung für das LLM)

1. Datum ermitteln (heute).
2. Web-Suche nach Veranstaltungen in Dortmund heute → Ergebnisse parsen.
3. Web-Suche / API-Abfrage für Bitcoin-Kurs in EUR.
4. Web-Suche / API-Abfrage für aktuelle Temperatur in Dortmund.
5. Aus den gesammelten Daten einen Markdown-Text erstellen.
6. Markdown mit MCP Pandoc nach EPUB konvertieren:  
   `~/Dokumente/daily-report_<DATUM>.epub`
7. Erfolgsmeldung ausgeben.
