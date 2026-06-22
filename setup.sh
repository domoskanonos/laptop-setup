#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APT_ENV=(sudo DEBIAN_FRONTEND=noninteractive)

GIT_USER_NAME="${GIT_USER_NAME:-Dominik Bruhn}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-domoskanonos@googlemail.com}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519}"
OLLAMA_DEFAULT_MODEL="${OLLAMA_DEFAULT_MODEL:-qwen3.5:4b}"
HERMES_DASHBOARD_HOST="${HERMES_DASHBOARD_HOST:-0.0.0.0}"
HERMES_DASHBOARD_PORT="${HERMES_DASHBOARD_PORT:-9119}"
HERMES_DASHBOARD_BASIC_AUTH_USERNAME="${HERMES_DASHBOARD_BASIC_AUTH_USERNAME:-admin}"
HERMES_DASHBOARD_BASIC_AUTH_PASSWORD="${HERMES_DASHBOARD_BASIC_AUTH_PASSWORD:-}"
HERMES_DASHBOARD_BASIC_AUTH_SECRET="${HERMES_DASHBOARD_BASIC_AUTH_SECRET:-}"

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

package_installed() {
    dpkg -s "$1" >/dev/null 2>&1
}

snap_installed() {
    snap list "$1" >/dev/null 2>&1
}

retry() {
    local attempts="$1"
    local delay_seconds="$2"
    shift 2

    local attempt=1
    until "$@"; do
        if (( attempt >= attempts )); then
            return 1
        fi
        warn "Befehl fehlgeschlagen, neuer Versuch in ${delay_seconds}s: $*"
        sleep "$delay_seconds"
        attempt=$((attempt + 1))
    done
}

load_env_file() {
    local env_file="$1"
    local line key value
    local allowed='^(GIT_USER_NAME|GIT_USER_EMAIL|SSH_KEY_PATH|OLLAMA_DEFAULT_MODEL|HERMES_DASHBOARD_HOST|HERMES_DASHBOARD_PORT|HERMES_DASHBOARD_BASIC_AUTH_USERNAME|HERMES_DASHBOARD_BASIC_AUTH_PASSWORD|HERMES_DASHBOARD_BASIC_AUTH_SECRET)$'

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"

        if [[ -z "${line//[[:space:]]/}" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        if [[ "$line" != *"="* ]]; then
            warn "Ignoriere ungueltige .env-Zeile: $line"
            continue
        fi

        key="${line%%=*}"
        value="${line#*=}"

        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"

        if [[ ! "$key" =~ $allowed ]]; then
            warn "Ignoriere nicht erlaubte .env-Variable: $key"
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
    log "Lade Konfiguration aus .env"
    load_env_file "$SCRIPT_DIR/.env"
fi

ensure_not_root() {
    [[ "$EUID" -ne 0 ]] || die "Bitte setup.sh als normaler Benutzer starten, nicht als root."
}

ensure_package() {
    local package="$1"
    if package_installed "$package"; then
        log "Paket bereits installiert: $package"
        return 0
    fi
    log "Installiere Paket: $package"
    "${APT_ENV[@]}" apt-get install -y "$package"
}

ensure_snap() {
    local package="$1"
    shift
    if snap_installed "$package"; then
        log "Snap bereits installiert: $package"
        return 0
    fi
    log "Installiere Snap: $package"
    retry 3 2 sudo snap install "$package" "$@"
}

ensure_service_running() {
    local service="$1"
    if ! systemctl is-enabled --quiet "$service" 2>/dev/null; then
        log "Aktiviere Dienst: $service"
        sudo systemctl enable "$service" >/dev/null 2>&1 || true
    fi
    if ! systemctl is-active --quiet "$service"; then
        log "Starte Dienst: $service"
        sudo systemctl start "$service"
    else
        log "Dienst laeuft bereits: $service"
    fi
}

ensure_ollama_server() {
    if ollama list >/dev/null 2>&1; then
        log "Ollama-Server ist bereits erreichbar"
        return 0
    fi

    if systemctl list-unit-files | grep -q '^ollama.service'; then
        ensure_service_running ollama
    elif pgrep -af 'ollama serve' >/dev/null 2>&1; then
        log "Ollama-Serverprozess laeuft bereits"
    else
        log "Starte lokalen Ollama-Server ohne systemd-Service"
        nohup ollama serve >/tmp/ollama-serve.log 2>&1 &
    fi

    if ! retry 10 1 ollama list >/dev/null 2>&1; then
        warn "Ollama-Server konnte nicht gestartet werden"
        return 1
    fi

    log "Ollama-Server ist erreichbar"
}

ensure_hermes() {
    local hermes_binary="$HOME/.local/bin/hermes"

    if [[ -x "$hermes_binary" ]]; then
        log "Hermes ist bereits installiert"
        return 0
    fi

    log "Installiere Hermes Agent (offizieller Installer)..."
    curl -fsSL "https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh" | bash -s -- --skip-setup

    if [[ -x "$hermes_binary" ]]; then
        log "Hermes erfolgreich installiert"
        log "Dashboard starten: hermes dashboard"
        return 0
    fi

    warn "Hermes-Installation fehlgeschlagen"
    return 1
}

is_loopback_host() {
    local host="$1"
    [[ "$host" == "127.0.0.1" || "$host" == "::1" || "$host" == "localhost" ]]
}

set_env_kv() {
    local env_file="$1"
    local key="$2"
    local value="$3"
    local tmp_file

    tmp_file="$(mktemp)"
    if [[ -f "$env_file" ]]; then
        grep -v "^${key}=" "$env_file" > "$tmp_file" || true
    fi
    printf '%s=%s\n' "$key" "$value" >> "$tmp_file"
    mv "$tmp_file" "$env_file"
}

ensure_hermes_runtime_env() {
    local env_file="$HOME/.hermes/.env"
    local existing_username
    local existing_password
    local existing_secret

    mkdir -p "$HOME/.hermes"
    touch "$env_file"
    chmod 600 "$env_file"

    existing_username="$(grep '^HERMES_DASHBOARD_BASIC_AUTH_USERNAME=' "$env_file" 2>/dev/null | tail -n1 | cut -d'=' -f2-)"
    if [[ -z "$existing_username" ]]; then
        set_env_kv "$env_file" "HERMES_DASHBOARD_BASIC_AUTH_USERNAME" "$HERMES_DASHBOARD_BASIC_AUTH_USERNAME"
    elif [[ "$HERMES_DASHBOARD_BASIC_AUTH_USERNAME" != "admin" ]]; then
        set_env_kv "$env_file" "HERMES_DASHBOARD_BASIC_AUTH_USERNAME" "$HERMES_DASHBOARD_BASIC_AUTH_USERNAME"
    else
        HERMES_DASHBOARD_BASIC_AUTH_USERNAME="$existing_username"
    fi

    if [[ -z "$HERMES_DASHBOARD_BASIC_AUTH_PASSWORD" ]]; then
        existing_password="$(grep '^HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=' "$env_file" 2>/dev/null | tail -n1 | cut -d'=' -f2-)"
        if [[ -z "$existing_password" ]]; then
            HERMES_DASHBOARD_BASIC_AUTH_PASSWORD="$(od -An -N12 -tx1 /dev/urandom | tr -d ' \n')"
            log "Hermes Dashboard Passwort wurde automatisch erzeugt und in ~/.hermes/.env gespeichert"
        else
            HERMES_DASHBOARD_BASIC_AUTH_PASSWORD="$existing_password"
        fi
    fi
    set_env_kv "$env_file" "HERMES_DASHBOARD_BASIC_AUTH_PASSWORD" "$HERMES_DASHBOARD_BASIC_AUTH_PASSWORD"

    if [[ -z "$HERMES_DASHBOARD_BASIC_AUTH_SECRET" ]]; then
        existing_secret="$(grep '^HERMES_DASHBOARD_BASIC_AUTH_SECRET=' "$env_file" 2>/dev/null | tail -n1 | cut -d'=' -f2-)"
        if [[ -z "$existing_secret" ]]; then
            HERMES_DASHBOARD_BASIC_AUTH_SECRET="$(od -An -N32 -tx1 /dev/urandom | tr -d ' \n')"
        else
            HERMES_DASHBOARD_BASIC_AUTH_SECRET="$existing_secret"
        fi
    fi
    set_env_kv "$env_file" "HERMES_DASHBOARD_BASIC_AUTH_SECRET" "$HERMES_DASHBOARD_BASIC_AUTH_SECRET"
}

ensure_hermes_dashboard_daemon() {
    local unit_dir="$HOME/.config/systemd/user"
    local unit_file="$unit_dir/hermes-dashboard.service"
    local lan_ip

    [[ "$HERMES_DASHBOARD_PORT" =~ ^[0-9]+$ ]] || die "HERMES_DASHBOARD_PORT muss numerisch sein"
    (( HERMES_DASHBOARD_PORT >= 1 && HERMES_DASHBOARD_PORT <= 65535 )) || die "HERMES_DASHBOARD_PORT muss zwischen 1 und 65535 liegen"

    mkdir -p "$unit_dir"
    ensure_hermes_runtime_env

    cat > "$unit_file" <<EOF
[Unit]
Description=Hermes Dashboard Daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
EnvironmentFile=%h/.hermes/.env
ExecStart=%h/.local/bin/hermes dashboard --host ${HERMES_DASHBOARD_HOST} --port ${HERMES_DASHBOARD_PORT} --no-open
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

    if command_exists loginctl; then
        sudo loginctl enable-linger "$USER" >/dev/null 2>&1 || warn "Konnte loginctl enable-linger fuer $USER nicht setzen"
    fi

    if command_exists systemctl && systemctl --user daemon-reload >/dev/null 2>&1; then
        systemctl --user enable --now hermes-dashboard.service
        systemctl --user restart hermes-dashboard.service
    else
        warn "systemd --user ist nicht verfuegbar, starte Hermes Dashboard im Hintergrund"
        pkill -f 'hermes dashboard --host' >/dev/null 2>&1 || true
        nohup "$HOME/.local/bin/hermes" dashboard --host "$HERMES_DASHBOARD_HOST" --port "$HERMES_DASHBOARD_PORT" --no-open >/tmp/hermes-dashboard.log 2>&1 &
    fi

    if retry 20 1 curl -fsS "http://127.0.0.1:${HERMES_DASHBOARD_PORT}/api/status" >/dev/null 2>&1; then
        log "Hermes Dashboard Daemon laeuft"
    else
        warn "Hermes Dashboard antwortet nicht auf Port ${HERMES_DASHBOARD_PORT}"
    fi

    lan_ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
    if is_loopback_host "$HERMES_DASHBOARD_HOST"; then
        log "Hermes Dashboard lokal erreichbar: http://127.0.0.1:${HERMES_DASHBOARD_PORT}"
    elif [[ -n "$lan_ip" ]]; then
        log "Hermes Dashboard im Netzwerk erreichbar: http://${lan_ip}:${HERMES_DASHBOARD_PORT}"
    else
        log "Hermes Dashboard gebunden auf ${HERMES_DASHBOARD_HOST}:${HERMES_DASHBOARD_PORT}"
    fi

    log "Login-Daten liegen in ~/.hermes/.env (HERMES_DASHBOARD_BASIC_AUTH_*)"
}

ensure_not_root

log "Starte System-Update"
"${APT_ENV[@]}" apt-get update
"${APT_ENV[@]}" apt-get upgrade -y

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
    log "Setze git user.name"
    git config --global user.name "$GIT_USER_NAME"
else
    log "git user.name bereits korrekt"
fi
if [[ "$current_git_email" != "$GIT_USER_EMAIL" ]]; then
    log "Setze git user.email"
    git config --global user.email "$GIT_USER_EMAIL"
else
    log "git user.email bereits korrekt"
fi

log "Installiere Visual Studio Code ueber den Ubuntu App-Store/Snap-Weg"
ensure_snap code --classic

log "Installiere/Aktualisiere Ollama"
if ! command_exists ollama; then
    log "Installiere Ollama"
    retry 3 2 bash -lc 'curl -fsSL https://ollama.com/install.sh | sh'
else
    log "Ollama ist bereits installiert"
fi
echo -e "\n=== Konfiguriere Ollama Umgebungsvariable ==="
if grep -q "OLLAMA_HOST" ~/.bashrc; then
    echo "OLLAMA_HOST ist bereits in ~/.bashrc eingetragen."
else
    echo 'export OLLAMA_HOST="http://127.0.0.1:11434"' >> ~/.bashrc
    echo "✅ OLLAMA_HOST wurde zu ~/.bashrc hinzugefügt."
fi
export OLLAMA_HOST="http://127.0.0.1:11434"

if command_exists ollama; then
    if ensure_ollama_server; then
        if ! ollama list 2>/dev/null | grep -q "$OLLAMA_DEFAULT_MODEL"; then
            log "Lade Ollama Modell $OLLAMA_DEFAULT_MODEL"
            ollama pull "$OLLAMA_DEFAULT_MODEL"
        else
            log "Ollama Modell bereits vorhanden: $OLLAMA_DEFAULT_MODEL"
        fi
    else
        warn "Ollama-Server ist nicht erreichbar; ueberspringe Modell-Download"
    fi
else
    warn "Ollama wurde nicht gefunden; ueberspringe Modell-Download"
fi

ensure_hermes
ensure_hermes_dashboard_daemon

log "Raeume APT Cache auf"
sudo apt-get clean

log "Setup abgeschlossen"
