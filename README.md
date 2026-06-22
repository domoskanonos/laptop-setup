# Laptop Setup (Ubuntu 26.04)

Dieses Repository verwendet wieder ein normales Bash-Installationsskript: [setup.sh](/home/laptop/_dev/repositories/laptop-setup/setup.sh).

## Voraussetzungen

- Ubuntu 26.04 oder ein kompatibles Debian/Ubuntu-System
- Ein normaler Benutzer mit sudo-Rechten
- Internetverbindung
- Eine vorhandene SSH-Key-Datei unter dem in `.env` konfigurierten Pfad

## Konfiguration

Beispieldatei kopieren und anpassen:

    cp .env.example .env

In `.env` konfigurierst du:

- `GIT_USER_NAME`
- `GIT_USER_EMAIL`
- `SSH_KEY_PATH`
- `OLLAMA_DEFAULT_MODEL`
- `HERMES_DASHBOARD_HOST`
- `HERMES_DASHBOARD_PORT`
- `HERMES_DASHBOARD_BASIC_AUTH_USERNAME`
- `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD`
- `HERMES_DASHBOARD_BASIC_AUTH_SECRET`

Das Skript liest nur diese Variablen aus `.env`. Unbekannte Eintraege werden ignoriert.

## Ausfuehrung

Im Repository:

    chmod +x setup.sh
    ./setup.sh

Oder auf einem frischen System direkt:

    curl -fsSL https://raw.githubusercontent.com/domoskanonos/laptop-setup/main/setup.sh -o setup.sh
    chmod +x setup.sh
    ./setup.sh

Ohne `.env` nutzt das Skript die eingebauten Defaults.

## Was installiert wird

- Basispakete: `curl`, `git`, `wget`, `openssh-server`, `snapd`
- OpenSSH-Dienst
- Visual Studio Code ueber den Ubuntu App-Store-/Snap-Weg (`code --classic`)
- Git-Global-Config aus `.env`
- Ollama inklusive Standardmodell
- Hermes Agent in `$HOME/.local/bin/hermes`
- Hermes Dashboard als Daemon (`systemd --user`) mit GUI-Zugriff

## Verhalten des Skripts

- Kann mehrfach ausgefuehrt werden
- Installiert und laedt Dinge nur nach, wenn sie noch fehlen
- Aendert Git nur bei abweichenden Werten
- Prueft den SSH-Key und setzt Berechtigungen
- Zieht das Ollama-Modell nur, wenn es noch fehlt

- Ignoriert ungueltige oder nicht erlaubte `.env`-Variablen
- Verwendet Retry-Logik fuer Snap- und Ollama-Downloads
- Gibt bei Paketen, Snaps, Diensten, Git, Ollama und Hermes klar aus, ob etwas bereits vorhanden ist oder neu eingerichtet wird
- Hermes wird ueber den offiziellen Installer eingerichtet
- Hermes Dashboard wird als User-Dienst `hermes-dashboard.service` aktiviert
- Fuer LAN-Zugriff wird standardmaessig auf `0.0.0.0:9119` gebunden
- Login-Daten fuer die Dashboard-GUI liegen in `~/.hermes/.env` (`HERMES_DASHBOARD_BASIC_AUTH_*`)

## Hermes GUI auf anderen Geraeten im Netzwerk

Nach dem Setup laeuft Hermes als Daemon und ist im Netzwerk erreichbar. Beispiel:

    http://<IP-DEINES-RECHNERS>:9119

Die Zugangsdaten stehen in:

    ~/.hermes/.env

Dienst-Management:

    systemctl --user status hermes-dashboard.service
    systemctl --user restart hermes-dashboard.service
    systemctl --user stop hermes-dashboard.service

Nach der Installation kannst du das Web-Dashboard mit folgendem Befehl starten:

    # nicht noetig, da nun als Daemon eingerichtet
    systemctl --user restart hermes-dashboard.service