#!/bin/bash

# Fehler abfangen: Skript bricht bei unerwarteten Fehlern sofort ab
set -e

# 1. Schutz vor falscher Ausführung als Root
if [ "$EUID" -eq 0 ]; then
    echo "❌ ERROR: Bitte starte dieses Skript NICHT mit 'sudo ./setup.sh'!" >&2
    echo "Starte es einfach als normaler User: ./setup.sh" >&2
    echo "Das Skript fragt sich die benötigten Root-Rechte selbst ab." >&2
    exit 1
fi

# 2. Harter Check für den SSH-Schlüssel (Abbruch bei Fehlen)
echo "=== Überprüfe SSH Schlüssel ==="
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "❌ CRITICAL ERROR: Der private SSH-Schlüssel (~/.ssh/id_ed25519) fehlt!" >&2
    echo "Das Setup wird abgebrochen. Bitte lege den Schlüssel zuerst an." >&2
    exit 1
fi

# Wenn der Key da ist, Berechtigungen sauber setzen
mkdir -p ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# SSH-Agent starten und Key hinzufügen
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
fi
ssh-add ~/.ssh/id_ed25519
echo "✅ SSH-Schlüssel erfolgreich geladen."

# 3. System-Updates
echo -e "\n=== Starte System-Update ==="
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl git

# === GOOGLE CHROME INSTALLATION ===
echo -e "\n=== Überprüfe Google Chrome ==="
if [ -f /usr/bin/google-chrome-stable ]; then
    echo "Google Chrome ist bereits installiert, wird übersprungen."
else
    echo "Google Chrome wird installiert..."
    mkdir -p ~/Downloads
    wget -P ~/Downloads/ https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ~/Downloads/google-chrome-stable_current_amd64.deb
    rm ~/Downloads/google-chrome-stable_current_amd64.deb

    # Keyring-Abfrage direkt im systemweiten Starter unterdrücken
    if [ -f /usr/share/applications/google-chrome.desktop ]; then
        echo "Deaktiviere GNOME-Keyring für Google Chrome..."
        sudo sed -i 's|Exec=/usr/bin/google-chrome-stable %U|Exec=/usr/bin/google-chrome-stable --password-store=basic --disable-features=DbusSecretPortal %U|g' /usr/share/applications/google-chrome.desktop
    fi
fi

# === SSH SERVER KONFIGURATION ===
echo -e "\n=== Überprüfe SSH Server ==="
if systemctl is-active --quiet ssh; then
    echo "SSH Server läuft bereits, wird übersprungen."
else
    echo "Installiere und starte OpenSSH-Server..."
    sudo apt install -y openssh-server
    sudo systemctl enable ssh
    sudo systemctl start ssh
fi

# Git Einstellungen für deinen User setzen
echo -e "\n=== Konfiguriere Git ==="
git config --global user.name "Dominik Bruhn"
git config --global user.email "domoskanonos@googlemail.com"
echo "✅ Git erfolgreich eingerichtet."





# === OLLAMA INSTALLATION & MODEL DOWNLOAD ===
curl -fsSL https://ollama.com/install.sh | sh

# WICHTIG: Den Hintergrunddienst aktivieren und starten, egal was vorher war
echo "Starte und aktiviere Ollama-Hintergrunddienst..."
sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl start ollama

echo "Warte 5 Sekunden, bis der Server antwortet..."
sleep 5

echo -e "\n=== Überprüfe Ollama Standard-Modell ==="
MODEL_NAME="qwen3.5:4b"

# Jetzt läuft der Server garantiert, und die Abfrage klappt ohne Fehler
if ollama list | grep -q "$MODEL_NAME"; then
    echo "Modell '$MODEL_NAME' ist bereits vorhanden."
else
    echo "Lade Standard-Modell '$MODEL_NAME' herunter..."
    ollama pull "$MODEL_NAME"
    echo "✅ Modell '$MODEL_NAME' erfolgreich heruntergeladen."
fi



# === HERMES AGENT INSTALLATION ===
echo -e "\n=== Überprüfe Hermes Agent ==="
if [ -f "$HOME/.local/bin/hermes" ]; then
    echo "Hermes Agent ist bereits installiert, wird übersprungen."
else
    echo "Hermes Agent wird installiert..."
    
    # Der Trick: Erst sauber runterladen, damit die Tastatur/Eingabe frei bleibt
    curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh -o /tmp/hermes_install.sh
    
    # Jetzt ausführen. Das Hermes-Skript regelt nun alles völlig autark!
    bash /tmp/hermes_install.sh
    
    # Temporäre Datei wieder aufräumen
    rm /tmp/hermes_install.sh
fi

echo -e "\n=== Setup erfolgreich abgeschlossen! ==="


# 1. Standby/Bildschirm ausschalten komplett deaktivieren (0 = Nie)
gsettings set org.gnome.desktop.session idle-delay 0

# 2. Die automatische Bildschirmsperre komplett abschalten
gsettings set org.gnome.desktop.screensaver lock-enabled false
