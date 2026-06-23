if ! declare -f log >/dev/null 2>&1; then
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
fi

HERMES_DASHBOARD_HOST="${HERMES_DASHBOARD_HOST:-0.0.0.0}"
HERMES_DASHBOARD_PORT="${HERMES_DASHBOARD_PORT:-9119}"
HERMES_DASHBOARD_BASIC_AUTH_USERNAME="${HERMES_DASHBOARD_BASIC_AUTH_USERNAME:-admin}"
HERMES_DASHBOARD_BASIC_AUTH_PASSWORD="${HERMES_DASHBOARD_BASIC_AUTH_PASSWORD:-}"
HERMES_DASHBOARD_BASIC_AUTH_SECRET="${HERMES_DASHBOARD_BASIC_AUTH_SECRET:-}"

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

ensure_hermes_runtime_env() {
    local env_file="$HOME/.hermes/.env"
    local existing_username
    local existing_password
    local existing_secret

    local config_src
    config_src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/config.yaml"
    mkdir -p "$HOME/.hermes"
    if [[ -f "$config_src" ]]; then
        cp "$config_src" "$HOME/.hermes/config.yaml"
        log "Hermes-Konfiguration nach ~/.hermes/config.yaml kopiert"
    fi
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
Environment=PATH=%h/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
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

setup_hermes() {
    ensure_hermes
    ensure_hermes_dashboard_daemon
}
