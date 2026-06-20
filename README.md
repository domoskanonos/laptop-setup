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

Nach der Installation kannst du das Web-Dashboard mit folgendem Befehl starten:

    hermes dashboard