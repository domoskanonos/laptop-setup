#!/usr/bin/env bash

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/domoskanonos/laptop-setup.git}"
TARGET_DIR="${TARGET_DIR:-$HOME/laptop-setup}"

log() {
    printf '[bootstrap] %s\n' "$1"
}

if [[ "${EUID}" -eq 0 ]]; then
    echo "Bitte bootstrap.sh als normaler Benutzer starten (nicht root)." >&2
    exit 1
fi

log "Installiere Basis-Werkzeuge (git, ansible, make)"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git ansible make

if [[ -f "./ansible/site.yml" && -f "./Makefile" ]]; then
    WORKDIR="$(pwd)"
    log "Nutze aktuelles Verzeichnis: $WORKDIR"
else
    if [[ ! -d "$TARGET_DIR/.git" ]]; then
        log "Klonen nach $TARGET_DIR"
        git clone "$REPO_URL" "$TARGET_DIR"
    else
        log "Repository bereits vorhanden, hole Updates"
        git -C "$TARGET_DIR" pull --ff-only
    fi
    WORKDIR="$TARGET_DIR"
fi

cd "$WORKDIR"

if [[ ! -f ".env" && -f ".env.example" ]]; then
    log "Erzeuge .env aus .env.example"
    cp .env.example .env
    log "Bitte .env anpassen und bootstrap.sh danach erneut starten, falls noetig"
fi

log "Installiere Ansible Collections"
make deps

log "Fuehre Playbook aus"
make apply

log "Fertig"
