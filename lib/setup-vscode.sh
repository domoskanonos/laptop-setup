if ! declare -f log >/dev/null 2>&1; then
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
fi

setup_vscode() {
    log "Aktualisiere Paketquellen..."
    "${APT_ENV[@]}" apt-get update

    log "Installiere Abhängigkeiten..."
    ensure_package wget gpg

    log "Füge Microsoft GPG-Schlüssel hinzu..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/ms-vscode-keyring.gpg
    sudo install -D -o root -g root -m 644 /tmp/ms-vscode-keyring.gpg /usr/share/keyrings/ms-vscode-keyring.gpg
    rm -f /tmp/ms-vscode-keyring.gpg

    log "Füge VS Code Repository hinzu..."
    echo "deb [signed-by=/usr/share/keyrings/ms-vscode-keyring.gpg] https://packages.microsoft.com/repos/code stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null

    log "Installiere Visual Studio Code..."
    "${APT_ENV[@]}" apt-get update
    ensure_package code

    log "Installation abgeschlossen!"
}
