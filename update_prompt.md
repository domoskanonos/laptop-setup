Du bist ein erfahrener Linux-Systemadministrator und Experte für Bash-Scripting. Deine Aufgabe ist es, das bereitgestellte Bash-Skript (`setup.sh`) für das Betriebssystem Ubuntu 26.04 LTS (Noble Numbat) tiefgehend zu analysieren, zu optimieren und zu aktualisieren.

Bitte wende bei der Überarbeitung strikt die folgenden Kriterien an:

1. Strikte Idempotenz:
   - Jede Sektion muss beliebig oft hintereinander ausgeführt werden können, ohne das System in einen instabilen Zustand zu bringen oder doppelte Einträge (z. B. in Konfigurationsdateien oder APT-Listen) zu erzeugen.
   - Vor jeder Installation oder Änderung muss sauber geprüft werden, ob das gewünschte Ergebnis bereits existiert (z. B. via `type`, `command -v`, `snap list` oder Dateiprüfungen).

2. Robustes Error-Handling & Sicherheit:
   - Nutze `set -euo pipefail`, um unentdeckte Fehler in Pipes oder uninitialisierte Variablen abzufangen.
   - Implementiere saubere `trap`-Funktionen, um bei einem unerwarteten Abbruch temporäre Dateien (z. B. in `/tmp`) rückstandslos aufzuräumen.
   - Überprüfe Eingaben und Voraussetzungen (wie SSH-Keys oder Internetverbindung) vor der Ausführung kritischer Schritte.

3. Robustes Logging & Benutzerführung:
   - Ersetze einfache `echo`-Befehle durch eine einheitliche Logging-Funktion, die klare Stati ausgibt (z. B. `[INFO]`, `[SUCCESS]`, `[WARN]`, `[ERROR]`).
   - Fehlermeldungen müssen zwingend auf Standard Error (`>&2`) umgeleitet werden.

4. Müll-Minimierung & System-Cleanliness:
   - Keine unnötigen temporären Dateien auf dem System hinterlassen.
   - Nach APT-Installationen temporäre Caches leeren (`apt-get clean`).
   - Bevorzuge für Desktop-Anwendungen offizielle Snap-Pakete (wie bei VS Code), sofern sie eine automatische Aktualisierung über den App Store garantieren und das System sauber halten.

5. Ubuntu 26.04 Spezifika:
   - Nutze moderne Bash-Syntax und aktuelle Ubuntu-Standards (z. B. keine veralteten `apt-key` Befehle mehr, stattdessen GPG-Keyrings unter `/etc/apt/keyrings/`).

Format der Antwort:
- Gib das vollständig überarbeitete Skript in einem einzigen, zusammenhängenden Code-Block aus.
- Füge im Code aussagekräftige Kommentare ein, warum bestimmte Änderungen vorgenommen wurden.
- Liste nach dem Code kurz die wichtigsten vorgenommenen Optimierungen strukturiert auf.