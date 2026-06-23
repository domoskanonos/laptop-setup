if ! declare -f log >/dev/null 2>&1; then
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
fi

setup_docker() {
    log "Starte Docker-Installation"

    if command_exists docker; then
        log "Docker ist bereits installiert"
    else
        log "Installiere Voraussetzungen"
        ensure_package ca-certificates
        ensure_package curl
        ensure_package gnupg
        ensure_package lsb-release

        log "Fuege Docker-Repository hinzu"
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
            sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        echo \
            "deb [arch=$(dpkg --print-architecture) \
            signed-by=/etc/apt/keyrings/docker.gpg] \
            https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

        "${APT_ENV[@]}" apt-get update
        "${APT_ENV[@]}" apt-get install -y \
            docker-ce \
            docker-ce-cli \
            containerd.io \
            docker-buildx-plugin \
            docker-compose-plugin
    fi

    log "Starte und aktiviere Docker-Dienst"
    ensure_service_running docker

    log "Fuege Benutzer zur Docker-Gruppe hinzu"
    sudo usermod -aG docker "$USER"

    log "Docker-Setup erfolgreich abgeschlossen!"
    log "Hinweis: Für Docker-Zugriff bitte aus- und wieder einloggen oder 'newgrp docker' ausfuehren"
}
