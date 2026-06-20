#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GIT_USER_NAME="${GIT_USER_NAME:-Dominik Bruhn}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-domoskanonos@googlemail.com}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519}"
OLLAMA_DEFAULT_MODEL="${OLLAMA_DEFAULT_MODEL:-qwen3.5:4b}"

if [[ -f "$SCRIPT_DIR/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    . "$SCRIPT_DIR/.env"
    set +a
fi

log() {
    printf '[setup] %s\n' "$1"
}

warn() {
    printf '[warn] %s\n' "$1" >&2
}

die() {
    printf '[error] %s\n' "$1" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

ensure_not_root() {
    [[ "$EUID" -ne 0 ]] || die "Bitte setup.sh als normaler Benutzer starten, nicht als root."
}

ensure_package() {
    local package="$1"
    if dpkg -s "$package" >/dev/null 2>&1; then
        return 0
    fi
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$package"
}

ensure_snap() {
    local package="$1"
    shift
    if snap list "$package" >/dev/null 2>&1; then
        return 0
    fi
    sudo snap install "$package" "$@"
}

ensure_service_running() {
    local service="$1"
    sudo systemctl enable "$service" >/dev/null 2>&1 || true
    sudo systemctl start "$service"
}

ensure_not_root

log "Starte System-Update"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

log "Installiere Basispakete"
ensure_package curl
ensure_package git
ensure_package wget
ensure_package openssh-server
ensure_package snapd

log "Aktiviere Dienste"
ensure_service_running ssh
ensure_service_running snapd
sudo systemctl start snapd.socket >/dev/null 2>&1 || true

log "Pruefe SSH-Key"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
[[ -f "$SSH_KEY_PATH" ]] || die "SSH private key fehlt: $SSH_KEY_PATH"
chmod 600 "$SSH_KEY_PATH"
if [[ -f "${SSH_KEY_PATH}.pub" ]]; then
    chmod 644 "${SSH_KEY_PATH}.pub"
fi

log "Konfiguriere Git"
current_git_name="$(git config --global user.name || true)"
current_git_email="$(git config --global user.email || true)"
if [[ "$current_git_name" != "$GIT_USER_NAME" ]]; then
    git config --global user.name "$GIT_USER_NAME"
fi
if [[ "$current_git_email" != "$GIT_USER_EMAIL" ]]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi

log "Installiere Visual Studio Code ueber Snap"
ensure_snap code --classic

log "Installiere/Aktualisiere Ollama"
if ! command_exists ollama; then
    curl -fsSL https://ollama.com/install.sh | sh
fi
if systemctl list-unit-files | grep -q '^ollama.service'; then
    ensure_service_running ollama
else
    warn "ollama.service nicht gefunden; ueberspringe Service-Aktivierung"
fi

if command_exists ollama; then
    if ! ollama list 2>/dev/null | grep -q "$OLLAMA_DEFAULT_MODEL"; then
        log "Lade Ollama Modell $OLLAMA_DEFAULT_MODEL"
        ollama pull "$OLLAMA_DEFAULT_MODEL"
    fi
else
    warn "Ollama wurde nicht gefunden; ueberspringe Modell-Download"
fi

log "Raeume APT Cache auf"
sudo apt-get clean

log "Setup abgeschlossen"
