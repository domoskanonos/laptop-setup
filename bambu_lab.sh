#!/bin/bash

echo "====================================="
echo "Installiere BambuStudio (AppImage)..."
echo "====================================="

sudo apt-get update && sudo apt-get install -y locales language-pack-en


# 1. Zielverzeichnisse erstellen (falls nicht vorhanden)
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$HOME/.local/share/icons"

# 2. Neueste Release-URL über die GitHub-API abfragen (filtert nach dem Linux .AppImage)
echo "Suche nach der neuesten BambuStudio Version..."
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/bambulab/BambuStudio/releases/latest \
  | grep -oP '"browser_download_url": "\K[^"]+\.AppImage' \
  | head -n 1)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Fehler: Konnte die Download-URL für das AppImage nicht ermitteln."
    exit 1
fi

# 3. AppImage herunterladen
APPIMAGE_PATH="$HOME/.local/bin/BambuStudio.AppImage"
echo "Lade herunter von: $DOWNLOAD_URL"
curl -L "$DOWNLOAD_URL" -o "$APPIMAGE_PATH"

# 4. Ausführbar machen
chmod +x "$APPIMAGE_PATH"

# 5. Icon herunterladen (optional, für ein sauberes UI im Launcher)
# Nutzt das offizielle Icon aus dem GitHub-Repository
ICON_PATH="$HOME/.local/share/icons/bambustudio.png"
curl -sL "https://raw.githubusercontent.com/bambulab/BambuStudio/master/resources/images/BambuStudio.png" -o "$ICON_PATH"

# 6. Desktop-Starter (.desktop-Datei) erstellen
DESKTOP_FILE="$HOME/.local/share/applications/bambustudio.desktop"
echo "Erstelle Desktop-Starter..."

cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=Bambu
Exec=env LANG=en_US.UTF-8 $APPIMAGE_PATH
Icon=$ICON_PATH
Type=Application
Categories=Office;Development;
Terminal=false
Comment=Bambu Lab 3D slicer
EOF

# 7. Dateirechte für den Starter anpassen
chmod +x "$DESKTOP_FILE"

echo "BambuStudio wurde erfolgreich unter $APPIMAGE_PATH installiert!"
echo "Ein Desktop-Starter wurde angelegt. Evtl. musst du dich neu anmelden oder den Launcher neu starten, damit das Icon erscheint."