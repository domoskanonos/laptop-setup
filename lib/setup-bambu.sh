if ! declare -f log >/dev/null 2>&1; then
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
fi

setup_bambu() {
    log "Installiere BambuStudio (AppImage)..."
    local appimage_path="$HOME/.local/bin/BambuStudio.AppImage"
    local desktop_file="$HOME/.local/share/applications/bambustudio.desktop"
    local icon_path="$HOME/.local/share/icons/bambustudio.png"

    if [[ -f "$appimage_path" ]]; then
        log "BambuStudio AppImage bereits vorhanden: $appimage_path"
    else
        "${APT_ENV[@]}" apt-get update
        ensure_package locales
        ensure_package language-pack-en

        mkdir -p "$HOME/.local/bin"
        mkdir -p "$HOME/.local/share/applications"
        mkdir -p "$HOME/.local/share/icons"

        log "Suche nach der neuesten BambuStudio Version..."
        local download_url
        download_url=$(curl -s https://api.github.com/repos/bambulab/BambuStudio/releases/latest \
          | grep -oP '"browser_download_url": "\K[^"]+\.AppImage' \
          | head -n 1)

        if [[ -z "$download_url" ]]; then
            die "Konnte die Download-URL fuer das AppImage nicht ermitteln."
        fi

        log "Lade herunter von: $download_url"
        curl -L "$download_url" -o "$appimage_path"
        chmod +x "$appimage_path"
    fi

    if [[ ! -f "$icon_path" ]]; then
        curl -sL "https://raw.githubusercontent.com/bambulab/BambuStudio/master/resources/images/BambuStudio.png" -o "$icon_path"
    fi

    log "Erstelle Desktop-Starter..."
    cat > "$desktop_file" <<EOF
[Desktop Entry]
Name=Bambu
Exec=env LANG=en_US.UTF-8 $appimage_path
Icon=$icon_path
Type=Application
Categories=Office;Development;
Terminal=false
Comment=Bambu Lab 3D slicer
EOF

    chmod +x "$desktop_file"
    log "BambuStudio erfolgreich unter $appimage_path installiert!"
}
