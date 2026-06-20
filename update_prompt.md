Du bist ein erfahrener Linux-Systemadministrator und Experte für Bash-Scripting. Deine Aufgabe ist es, das bereitgestellte Bash-Skript (`setup.sh`) für das Betriebssystem Ubuntu 26.04 LTS (Noble Numbat) tiefgehend zu analysieren, zu optimieren und zu aktualisieren.

**WICHTIG**: Das Setup-Skript muss **generisch und konfigurierbar** sein:
- Keine hardcodierten Benutzerdaten (Namen, E-Mails, SSH-Schlüsselpfade)
- Diese Werte sollen aus einer `.env` geladen werden
- `.env` soll sicher geparst werden: nur erlaubte Variablen (Whitelist), keine beliebige Code-Ausführung
- Falls `.env` nicht existiert, sollen Defaults aus Umgebungsvariablen oder dem Skript selbst verwendet werden
- Eine `.env.example` sollte als Template für Nutzer dienen

Bitte wende bei der Überarbeitung strikt die folgenden Kriterien an:

1. Strikte Idempotenz:
   - Jede Sektion muss beliebig oft hintereinander ausgeführt werden können, ohne das System in einen instabilen Zustand zu bringen oder doppelte Einträge (z. B. in Konfigurationsdateien oder APT-Listen) zu erzeugen.
   - Vor jeder Installation oder Änderung muss sauber geprüft werden, ob das gewünschte Ergebnis bereits existiert (z. B. via `type`, `command -v`, `snap list` oder Dateiprüfungen).

2. Robustes Error-Handling & Sicherheit:
   - Nutze `set -euo pipefail`, um unentdeckte Fehler in Pipes oder uninitialisierte Variablen abzufangen.
   - Implementiere saubere `trap`-Funktionen, um bei einem unerwarteten Abbruch temporäre Dateien (z. B. in `/tmp`) rückstandslos aufzuräumen.
   - Überprüfe Eingaben und Voraussetzungen (wie SSH-Keys oder Internetverbindung) vor der Ausführung kritischer Schritte.
   - Nutze wo sinnvoll Retry-Logik (z. B. für Netzwerk-Downloads), aber mit begrenzten Versuchen und klarem Timeout.
   - Führe sicherheitsrelevante Änderungen nur aus, wenn sie notwendig sind (least-change principle).

3. Robustes Logging & Benutzerführung:
   - Ersetze einfache `echo`-Befehle durch eine einheitliche Logging-Funktion, die klare Stati ausgibt (z. B. `[INFO]`, `[SUCCESS]`, `[WARN]`, `[ERROR]`).
   - Fehlermeldungen müssen zwingend auf Standard Error (`>&2`) umgeleitet werden.
   - Ergänze optional einen `--verbose` Modus und klare Abschlussmeldung mit Zusammenfassung (was geändert wurde, was übersprungen wurde).

4. Müll-Minimierung & System-Cleanliness:
   - Keine unnötigen temporären Dateien auf dem System hinterlassen.
   - Nach APT-Installationen temporäre Caches leeren (`apt-get clean`).
   - Bevorzuge für Desktop-Anwendungen offizielle Snap-Pakete (wie bei VS Code), sofern sie eine automatische Aktualisierung über den App Store garantieren und das System sauber halten.
   - Nutze für temporäre Dateien `mktemp` statt statischer Pfade und räume immer über `trap` auf.

5. Ubuntu 26.04 Spezifika:
   - Nutze moderne Bash-Syntax und aktuelle Ubuntu-Standards (z. B. keine veralteten `apt-key` Befehle mehr, stattdessen GPG-Keyrings unter `/etc/apt/keyrings/`).
   - Verwende nicht-interaktive Paketinstallation (`DEBIAN_FRONTEND=noninteractive`) und `apt-get` in Skripten.
   - Prüfe Distribution/Version (`/etc/os-release`) und Architektur (`dpkg --print-architecture`) vor distributionsabhängigen Schritten.

6. Determinismus & Wartbarkeit:
   - Implementiere Hilfsfunktionen wie `command_exists`, `require_sudo`, `ensure_package_installed`, um Wiederholungen zu vermeiden.
   - Führe keine unnötigen globalen Änderungen durch (z. B. nur dann `git config`, wenn Werte abweichen).
   - Stelle sicher, dass alle externen Downloads nachvollziehbar sind (offizielle Quellen, stabile URLs, wo möglich Checksum-Prüfung).
   - Vermeide stille Fehlerunterdrückung; wenn etwas bewusst toleriert wird, muss ein Warn-Log ausgegeben werden.

7. Testbarkeit:
   - Ergänze am Ende eine kurze Self-Check-Sektion (z. B. Verfügbarkeit zentraler Befehle/Services).
   - Das Ergebnis soll mit `bash -n` syntaktisch valide sein und möglichst ShellCheck-freundlich geschrieben werden.

Format der Antwort:
- Gib das vollständig überarbeitete Skript in einem einzigen, zusammenhängenden Code-Block aus.
- Füge im Code aussagekräftige Kommentare ein, warum bestimmte Änderungen vorgenommen wurden.
- Liste nach dem Code kurz die wichtigsten vorgenommenen Optimierungen strukturiert auf.
- Gib zusätzlich eine kurze Liste „Offene Annahmen“, falls für bestimmte Entscheidungen Nutzerdaten fehlen.