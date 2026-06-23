if ! declare -f log >/dev/null 2>&1; then
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
fi

setup_whatsapp() {
    log "Aktualisiere Paketquellen..."
    "${APT_ENV[@]}" apt-get update

    if ! command_exists snap; then
        log "Snap ist nicht installiert. Installiere snapd..."
        "${APT_ENV[@]}" apt-get install -y snapd
    fi

    log "Installiere whatsdev aus dem Ubuntu/Snap Store..."
    sudo snap install whatsdev

    log "Installation abgeschlossen!"
}
