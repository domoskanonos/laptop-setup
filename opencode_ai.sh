#!/bin/bash

# Fehler abfangen: Bricht sofort ab, wenn ein Befehl fehlschlägt
set -euo pipefail

echo "=== Starte offizielle OpenCode CLI-Installation ==="

# 1. Sicherstellen, dass curl installiert ist
if ! command -v curl &> /dev/null; then
    echo "curl nicht gefunden. Installiere curl..."
    sudo apt update && sudo apt install -y curl
fi

# 2. Den offiziellen Installer ausführen
echo "Lade OpenCode herunter und installiere die Binary..."
curl -fsSL https://opencode.ai/install | bash

echo "=== Setup erfolgreich abgeschlossen! ==="
echo "OpenCode wurde erfolgreich installiert."
echo "Du kannst es jetzt im Terminal starten mit: opencode"