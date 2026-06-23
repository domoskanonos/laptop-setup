if ! declare -f log >/dev/null 2>&1; then
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
fi

setup_basic() {
    log "Starte System-Update"
    "${APT_ENV[@]}" apt-get update
    "${APT_ENV[@]}" apt-get upgrade -y

    log "Installiere Basispakete"
    ensure_package curl
    ensure_package git
    ensure_package wget
    ensure_package openssh-server
    ensure_package snapd
    ensure_package util-linux-extra
    ensure_package pandoc
    ensure_package nodejs
    ensure_package ffmpeg
    ensure_package imagemagick
    ensure_package sox
    ensure_package wkhtmltopdf

    log "Aktiviere Dienste"
    ensure_service_running ssh
    ensure_service_running snapd
    sudo systemctl start snapd.socket >/dev/null 2>&1 || true

    log "Konfiguriere GNOME Desktop"
    gsettings set org.gnome.shell.extensions.ding show-trash false 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.ding show-home false 2>/dev/null || true
}
