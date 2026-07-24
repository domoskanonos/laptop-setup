if ! declare -f log >/dev/null 2>&1; then
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../common/common.sh"
fi

setup_desktop() {
    log "Installiere Desktop-Pakete"
    ensure_package calibre
    ensure_package mpv
    ensure_package sox
    ensure_package vlc
    ensure_package imagemagick
    ensure_package texlive-latex-recommended
    ensure_package texlive-fonts-recommended

    log "Konfiguriere GNOME Desktop"
    gsettings set org.gnome.shell.extensions.ding show-trash false 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.ding show-home false 2>/dev/null || true
}
