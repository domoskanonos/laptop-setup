#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/common.sh"

if [[ -f "$SCRIPT_DIR/.env" ]]; then
    log "Lade Konfiguration aus .env"
    load_env_file "$SCRIPT_DIR/.env"
fi

[[ "$EUID" -ne 0 ]] || die "Bitte setup.sh als normaler Benutzer starten, nicht als root."

source "$SCRIPT_DIR/lib/setup-basic.sh"
setup_basic

source "$SCRIPT_DIR/lib/setup-git.sh"
setup_git

source "$SCRIPT_DIR/lib/setup-uv.sh"
setup_uv


log "Setup abgeschlossen"
