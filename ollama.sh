#!/bin/bash

# Fehler abfangen: Bricht sofort ab, wenn ein Befehl fehlschlägt
set -euo pipefail

echo "=== Starte Ollama Snap-Installation & Konfiguration ==="

# 1. Sicherstellen, dass snapd geladen und aktiv ist
if ! command -v snap &> /dev/null; then
    echo "Snap ist nicht installiert. Installiere snapd..."
    sudo apt update
    sudo apt install -y snapd
fi

# 2. Ollama aus dem Snap Store installieren
echo "Installiere Ollama aus dem Ubuntu App-Zentrum (Snap)..."
sudo snap install ollama

# 3. Standard-Modell automatisch herunterladen
echo "Lade Standard-Modell (qwen3.5:4b) über Snap herunter..."
snap run ollama pull qwen3.5:4b

echo "=== Setup erfolgreich abgeschlossen! ==="
echo "Ollama läuft jetzt als systemweiter Dienst und startet automatisch."
echo "Du kannst den Status des Snaps prüfen mit: snap services ollama"