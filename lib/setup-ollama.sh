if ! declare -f log >/dev/null 2>&1; then
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
fi

OLLAMA_DEFAULT_MODEL="${OLLAMA_DEFAULT_MODEL:-qwen3.5:4b}"

setup_ollama() {
    log "Starte Ollama Snap-Installation & Konfiguration"

    if ! command_exists snap; then
        log "Snap ist nicht installiert. Installiere snapd..."
        "${APT_ENV[@]}" apt-get update
        "${APT_ENV[@]}" apt-get install -y snapd
    fi

    log "Installiere Ollama aus dem Ubuntu App-Zentrum (Snap)..."
    sudo snap install ollama

    log "Lade Standard-Modell ($OLLAMA_DEFAULT_MODEL) ueber Snap herunter..."
    snap run ollama pull "$OLLAMA_DEFAULT_MODEL"

    log "Setup erfolgreich abgeschlossen!"
}
