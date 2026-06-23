if ! declare -f log >/dev/null 2>&1; then
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../common.sh"
fi

setup_opencode() {
    local opencode_dir

    log "Starte offizielle OpenCode CLI-Installation"

    if ! command_exists curl; then
        log "curl nicht gefunden. Installiere curl..."
        "${APT_ENV[@]}" apt-get update && "${APT_ENV[@]}" apt-get install -y curl
    fi

    log "Lade OpenCode herunter und installiere die Binary..."
    curl -fsSL https://opencode.ai/install | bash

    log "Installiere opencode.jsonc nach ~/.config/opencode/"
    mkdir -p "$HOME/.config/opencode"
    opencode_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cp "$opencode_dir/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"

    log "Kopiere opencode_cron.sh nach ~/.local/bin/"
    mkdir -p "$HOME/.local/bin"
    cp "$opencode_dir/opencode_cron.sh" "$HOME/.local/bin/opencode_cron.sh"

    log "OpenCode erfolgreich installiert und konfiguriert!"
}
