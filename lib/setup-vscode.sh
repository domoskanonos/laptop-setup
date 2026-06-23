if ! declare -f log >/dev/null 2>&1; then
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
fi

setup_vscode() {
    log "Aktualisiere Paketquellen..."
    "${APT_ENV[@]}" apt-get update

    if ! command_exists snap; then
        log "Snap ist nicht installiert. Installiere snapd..."
        "${APT_ENV[@]}" apt-get install -y snapd
    fi

    log "Installiere Visual Studio Code aus dem Snap Store..."
    sudo snap install code --classic

    log "Installation abgeschlossen!"
}
