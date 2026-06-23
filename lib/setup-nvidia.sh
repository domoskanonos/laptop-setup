if ! declare -f log >/dev/null 2>&1; then
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
fi

setup_nvidia() {
    if ! command_exists nvidia-smi; then
        log "Kein NVIDIA-Treiber gefunden. Ueberspringe NVIDIA Container Toolkit."
        return
    fi

    if command_exists nvidia-container-toolkit; then
        log "NVIDIA Container Toolkit ist bereits installiert"
        return
    fi

    log "Installiere NVIDIA Container Toolkit"
    ensure_package curl

    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
        sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

    curl -sL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null

    "${APT_ENV[@]}" apt-get update
    "${APT_ENV[@]}" apt-get install -y nvidia-container-toolkit

    log "Starte Docker neu (damit NVIDIA Runtime geladen wird)"
    sudo systemctl restart docker

    log "NVIDIA Container Toolkit erfolgreich installiert!"
}
