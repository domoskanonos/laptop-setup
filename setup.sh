#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Laptop / Server Setup ==="
echo ""
echo "Welches System soll eingerichtet werden?"
echo ""
echo "  1) Laptop  — Desktop mit GPU (ComfyUI, TTS, Ollama, VSCode, Bambu, ...)"
echo "  2) Server  — Headless (Jellyfin, Immich, Navidrome, Radio-Ripper, ...)"
echo ""

read -rp "Auswahl (1 oder 2): " choice

case "$choice" in
    1)
        echo ""
        exec "$SCRIPT_DIR/laptop/setup.sh"
        ;;
    2)
        echo ""
        exec "$SCRIPT_DIR/server/setup.sh"
        ;;
    *)
        echo "Ungueltige Auswahl. Bitte 1 oder 2 eingeben."
        exit 1
        ;;
esac
