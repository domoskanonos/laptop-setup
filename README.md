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
- Visual Studio Code ueber Snap (`code --classic`)
- Git-Global-Config aus `.env`
- Ollama inklusive Standardmodell

## Verhalten des Skripts

- Kann mehrfach ausgefuehrt werden
- Installiert fehlende Pakete nach
- Aendert Git nur bei abweichenden Werten
- Prueft den SSH-Key und setzt Berechtigungen
- Zieht das Ollama-Modell nur, wenn es noch fehlt
- Ignoriert ungueltige oder nicht erlaubte `.env`-Variablen
- Verwendet Retry-Logik fuer Snap- und Ollama-Downloads