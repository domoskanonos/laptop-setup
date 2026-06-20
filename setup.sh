#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# Optionen
# -----------------------------------------------------------------------------
VERBOSE=0
DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --verbose) VERBOSE=1 ;;
        --dry-run) DRY_RUN=1 ;;
        *) ;;
    esac
done

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
log_info() {
    printf '[INFO] %s\n' "$1"
}

log_success() {
    printf '[SUCCESS] %s\n' "$1"
}

log_warn() {
    printf '[WARN] %s\n' "$1" >&2
}

log_error() {
    printf '[ERROR] %s\n' "$1" >&2
}

debug() {
    if [[ "$VERBOSE" -eq 1 ]]; then
        printf '[DEBUG] %s\n' "$1"
    fi
}

# -----------------------------------------------------------------------------
# Cleanup (tmp files)
# -----------------------------------------------------------------------------
TMP_FILES=()
cleanup() {
    local f
    for f in "${TMP_FILES[@]}"; do
        [[ -n "$f" && -f "$f" ]] && rm -f "$f"
    done
}
trap cleanup EXIT INT TERM

mktemp_track() {
    local tmp
    tmp="$(mktemp)"
    TMP_FILES+=("$tmp")
    printf '%s\n' "$tmp"
}

# -----------------------------------------------------------------------------
# Hilfsfunktionen
# -----------------------------------------------------------------------------
run_cmd() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf '[DRY-RUN] %s\n' "$*"
        return 0
    fi
    "$@"
}

retry() {
    local tries="$1"
    local wait_s="$2"
    shift 2

    local n=1
    while true; do
        if "$@"; then
            return 0
        fi
        if [[ "$n" -ge "$tries" ]]; then
            return 1
        fi
        n=$((n + 1))
        sleep "$wait_s"
    done
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_sudo() {
    if [[ "$EUID" -eq 0 ]]; then
        log_error "Bitte als normaler User starten, nicht als root/sudo."
        exit 1
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
        return 0
    fi
    sudo -v
}

has_internet() {
    ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 || ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1
}

# -----------------------------------------------------------------------------
# Konfiguration laden
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GIT_USER_NAME="${GIT_USER_NAME:-Dominik Bruhn}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-domoskanonos@googlemail.com}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519}"
OLLAMA_DEFAULT_MODEL="${OLLAMA_DEFAULT_MODEL:-qwen3.5:4b}"

load_env_file() {
    local env_file="$1"
    local line key value
    local allowed='^(GIT_USER_NAME|GIT_USER_EMAIL|SSH_KEY_PATH|OLLAMA_DEFAULT_MODEL)$'

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"

        if [[ -z "${line//[[:space:]]/}" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        if [[ "$line" != *"="* ]]; then
            log_warn "Ungueltige .env-Zeile ignoriert: $line"
            continue
        fi

        key="${line%%=*}"
        value="${line#*=}"

        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"

        if [[ ! "$key" =~ $allowed ]]; then
            log_warn "Nicht erlaubte .env-Variable ignoriert: $key"
            continue
        fi

        if [[ "$value" =~ ^\".*\"$ ]] || [[ "$value" =~ ^\'.*\'$ ]]; then
            value="${value:1:-1}"
        fi

        value="${value//\$HOME/$HOME}"
        printf -v "$key" '%s' "$value"
    done < "$env_file"
}

if [[ -f "$SCRIPT_DIR/.env" ]]; then
    log_info "Lade Konfiguration aus .env"
    load_env_file "$SCRIPT_DIR/.env"
else
    log_warn "Keine .env gefunden, verwende Defaults"
    log_info "Tipp: cp .env.example .env"
fi

debug "Git User: $GIT_USER_NAME <$GIT_USER_EMAIL>"
debug "SSH Key: $SSH_KEY_PATH"
debug "Ollama Model: $OLLAMA_DEFAULT_MODEL"

# -----------------------------------------------------------------------------
# Preconditions
# -----------------------------------------------------------------------------
require_sudo

if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID:-}" != "ubuntu" ]]; then
        log_warn "Nicht-Ubuntu erkannt (${ID:-unknown}), Script ist fuer Ubuntu 26.04 optimiert"
    fi
    if [[ "${VERSION_ID:-}" != "26.04" ]]; then
        log_warn "Ubuntu-Version ist ${VERSION_ID:-unknown}; erwartet 26.04"
    fi
else
    log_warn "/etc/os-release nicht gefunden"
fi

ARCH="$(dpkg --print-architecture 2>/dev/null || echo unknown)"
debug "Architektur: $ARCH"

if [[ ! -f "$SSH_KEY_PATH" ]]; then
    log_error "SSH private key fehlt: $SSH_KEY_PATH"
    exit 1
fi

run_cmd mkdir -p "$HOME/.ssh"
run_cmd chmod 700 "$HOME/.ssh"
run_cmd chmod 600 "$SSH_KEY_PATH"
if [[ -f "${SSH_KEY_PATH}.pub" ]]; then
    run_cmd chmod 644 "${SSH_KEY_PATH}.pub"
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
    if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
        eval "$(ssh-agent -s)" >/dev/null
    fi
    if ! ssh-add -l >/dev/null 2>&1 || ! ssh-add -l 2>/dev/null | grep -q "$(basename "$SSH_KEY_PATH")"; then
        ssh-add "$SSH_KEY_PATH" >/dev/null
        log_success "SSH-Key geladen"
    else
        log_info "SSH-Key bereits geladen"
    fi
fi

if ! has_internet; then
    log_error "Keine Internetverbindung erkannt"
    exit 1
fi

# -----------------------------------------------------------------------------
# Paketmanagement
# -----------------------------------------------------------------------------
APT_UPDATED=0
apt_update_once() {
    if [[ "$APT_UPDATED" -eq 0 ]]; then
        log_info "APT update"
        run_cmd sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
        APT_UPDATED=1
    fi
}

ensure_package_installed() {
    local pkg="$1"
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        debug "Paket bereits installiert: $pkg"
        return 0
    fi

    apt_update_once
    log_info "Installiere Paket: $pkg"
    run_cmd sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg"
}

log_info "Basis-Pakete sicherstellen"
ensure_package_installed curl
ensure_package_installed git
ensure_package_installed wget

# System-Upgrade bleibt idempotent und gewollt
log_info "System Upgrade"
run_cmd sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# -----------------------------------------------------------------------------
# Chrome
# -----------------------------------------------------------------------------
install_chrome() {
    if command_exists google-chrome-stable; then
        log_info "Google Chrome bereits installiert"
        return 0
    fi

    local deb
    deb="$(mktemp_track)"

    log_info "Lade Google Chrome herunter"
    if ! retry 3 2 wget -q -O "$deb" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"; then
        log_warn "Chrome Download fehlgeschlagen, ueberspringe"
        return 0
    fi

    log_info "Installiere Google Chrome"
    run_cmd sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$deb" || {
        log_warn "Chrome Installation fehlgeschlagen"
        return 0
    }

    if [[ -f /usr/share/applications/google-chrome.desktop ]]; then
        if ! grep -q -- '--password-store=basic' /usr/share/applications/google-chrome.desktop; then
            run_cmd sudo sed -i 's|Exec=/usr/bin/google-chrome-stable %U|Exec=/usr/bin/google-chrome-stable --password-store=basic --disable-features=DbusSecretPortal %U|g' /usr/share/applications/google-chrome.desktop
        fi
    fi

    log_success "Google Chrome ist installiert"
}
install_chrome

# -----------------------------------------------------------------------------
# SSH Server
# -----------------------------------------------------------------------------
ensure_package_installed openssh-server
if systemctl is-active --quiet ssh; then
    log_info "SSH Dienst laeuft bereits"
else
    run_cmd sudo systemctl enable ssh
    run_cmd sudo systemctl start ssh
    log_success "SSH Dienst aktiviert"
fi

# -----------------------------------------------------------------------------
# Git
# -----------------------------------------------------------------------------
CURRENT_NAME="$(git config --global user.name || true)"
CURRENT_EMAIL="$(git config --global user.email || true)"
if [[ "$CURRENT_NAME" != "$GIT_USER_NAME" ]]; then
    run_cmd git config --global user.name "$GIT_USER_NAME"
    log_info "Git user.name gesetzt"
else
    debug "Git user.name unveraendert"
fi
if [[ "$CURRENT_EMAIL" != "$GIT_USER_EMAIL" ]]; then
    run_cmd git config --global user.email "$GIT_USER_EMAIL"
    log_info "Git user.email gesetzt"
else
    debug "Git user.email unveraendert"
fi

# -----------------------------------------------------------------------------
# Ollama
# -----------------------------------------------------------------------------
install_ollama() {
    log_info "Installiere/Aktualisiere Ollama"
    if ! retry 3 2 bash -c 'curl -fsSL https://ollama.com/install.sh | sh'; then
        log_warn "Ollama Installer fehlgeschlagen"
        return 0
    fi

    if systemctl list-unit-files | grep -q '^ollama.service'; then
        run_cmd sudo systemctl daemon-reload
        run_cmd sudo systemctl enable ollama
        run_cmd sudo systemctl start ollama
        log_success "Ollama Dienst aktiviert"
    else
        log_warn "Ollama service nicht gefunden"
    fi

    if ! command_exists ollama; then
        log_warn "Ollama command nicht gefunden, ueberspringe Modell-Check"
        return 0
    fi

    if [[ "$DRY_RUN" -eq 0 ]]; then
        sleep 3
        if ollama list 2>/dev/null | grep -q "$OLLAMA_DEFAULT_MODEL"; then
            log_info "Ollama Modell bereits vorhanden: $OLLAMA_DEFAULT_MODEL"
        else
            log_info "Lade Ollama Modell: $OLLAMA_DEFAULT_MODEL"
            retry 3 2 ollama pull "$OLLAMA_DEFAULT_MODEL" || log_warn "Ollama Modell konnte nicht geladen werden"
        fi
    fi
}
install_ollama

# -----------------------------------------------------------------------------
# Hermes Agent
# -----------------------------------------------------------------------------
install_hermes() {
    if [[ -x "$HOME/.local/bin/hermes" ]]; then
        log_info "Hermes Agent bereits installiert"
        return 0
    fi

    local script
    script="$(mktemp_track)"

    log_info "Lade Hermes Installer"
    if ! retry 3 2 curl -fsSL "https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh" -o "$script"; then
        log_warn "Hermes Installer Download fehlgeschlagen"
        return 0
    fi

    log_info "Installiere Hermes Agent"
    run_cmd bash "$script" || log_warn "Hermes Installation fehlgeschlagen"
}
install_hermes

# -----------------------------------------------------------------------------
# Gnome Settings
# -----------------------------------------------------------------------------
if command_exists gsettings; then
    run_cmd gsettings set org.gnome.desktop.session idle-delay 0
    run_cmd gsettings set org.gnome.desktop.screensaver lock-enabled false
    log_info "GNOME Einstellungen aktualisiert"
else
    log_warn "gsettings nicht verfuegbar, ueberspringe GNOME Anpassungen"
fi

# -----------------------------------------------------------------------------
# Cleanup apt cache
# -----------------------------------------------------------------------------
run_cmd sudo apt-get clean

# -----------------------------------------------------------------------------
# Self-Check
# -----------------------------------------------------------------------------
log_info "Self-Check"
command_exists git && log_success "git verfuegbar" || log_warn "git fehlt"
command_exists curl && log_success "curl verfuegbar" || log_warn "curl fehlt"
command_exists ssh && log_success "ssh verfuegbar" || log_warn "ssh fehlt"
if command_exists systemctl; then
    if systemctl is-active --quiet ssh; then
        log_success "ssh service aktiv"
    else
        log_warn "ssh service nicht aktiv"
    fi
fi

log_success "Setup abgeschlossen"
