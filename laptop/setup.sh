#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../common/common.sh"

if [[ -f "$SCRIPT_DIR/../.env" ]]; then
    log "Lade Konfiguration aus .env"
    load_env_file "$SCRIPT_DIR/../.env"
fi

[[ "$EUID" -ne 0 ]] || die "Bitte setup.sh als normaler Benutzer starten, nicht als root."

source "$SCRIPT_DIR/../common/setup-basic.sh"
setup_basic

source "$SCRIPT_DIR/../common/setup-git.sh"
setup_git

source "$SCRIPT_DIR/setup-vscode.sh"
setup_vscode

source "$SCRIPT_DIR/../common/setup-uv.sh"
setup_uv

source "$SCRIPT_DIR/setup-ollama.sh"
setup_ollama

source "$SCRIPT_DIR/setup-bambu.sh"
setup_bambu

source "$SCRIPT_DIR/setup-whatsapp.sh"
setup_whatsapp

source "$SCRIPT_DIR/setup-desktop.sh"
setup_desktop

source "$SCRIPT_DIR/../common/opencode/setup-opencode.sh"
setup_opencode

source "$SCRIPT_DIR/../common/setup-nvidia.sh"
setup_nvidia

source "$SCRIPT_DIR/../common/setup-docker.sh"
setup_docker

log "Laptop-Setup abgeschlossen"

if command_exists docker && getent group docker | grep -q "$USER"; then
    log "Starte Shell mit Docker-Zugriff — nach Beenden (exit/Ctrl+D) kehren Sie zurueck"
    sg docker -c bash
fi
