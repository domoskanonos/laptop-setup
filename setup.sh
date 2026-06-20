#!/bin/bash

# Fehler abfangen: Skript bricht bei unerwarteten Fehlern sofort ab
set -euo pipefail

# =============================================================================
# KONFIGURATION LADEN
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults (wenn .env nicht existiert)
GIT_USER_NAME="${GIT_USER_NAME:-Dominik Bruhn}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-domoskanonos@googlemail.com}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519}"
OLLAMA_DEFAULT_MODEL="${OLLAMA_DEFAULT_MODEL:-qwen3.5:4b}"

# .env sicher laden: nur Whitelist-Variablen, keine Code-Ausfuehrung
load_env_file() {
    local env_file="$1"
    local line key value
    local allowed='^(GIT_USER_NAME|GIT_USER_EMAIL|SSH_KEY_PATH|OLLAMA_DEFAULT_MODEL)$'

    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"

        # Leere Zeilen und Kommentare ignorieren
        if [[ -z "${line//[[:space:]]/}" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        if [[ "$line" != *"="* ]]; then
            echo "⚠️  Ungueltige .env-Zeile ignoriert: $line" >&2
            continue
        fi

        key="${line%%=*}"
        value="${line#*=}"

        # Fuehrende/trailing Spaces entfernen
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"

        if [[ ! "$key" =~ $allowed ]]; then
            echo "⚠️  Nicht erlaubte .env-Variable ignoriert: $key" >&2
            continue
        fi

        # Optionale Anfuehrungszeichen entfernen
        if [[ "$value" =~ ^\".*\"$ ]] || [[ "$value" =~ ^\'.*\'$ ]]; then
            value="${value:1:-1}"
        fi

        # Hauefiger Fall in .env.example
        value="${value//\$HOME/$HOME}"

        printf -v "$key" '%s' "$value"
    done < "$env_file"
}

# Umgebungsvariablen aus .env laden (wenn vorhanden)
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "Lade Konfiguration aus .env..."
    load_env_file "$SCRIPT_DIR/.env"
else
    echo "ℹ️  Keine .env gefunden, nutze Defaults."
    echo "💡 Tipp: Kopiere .env.example zu .env und passe Werte an."
fi

echo "Git User: $GIT_USER_NAME <$GIT_USER_EMAIL>"
echo "SSH Key: $SSH_KEY_PATH"
echo "Ollama Model: $OLLAMA_DEFAULT_MODEL"
echo ""

# 1. Schutz vor falscher Ausführung als Root
if [ "$EUID" -eq 0 ]; then
    echo "❌ ERROR: Bitte starte dieses Skript NICHT mit 'sudo ./setup.sh'!" >&2
    echo "Starte es einfach als normaler User: ./setup.sh" >&2
    echo "Das Skript fragt sich die benötigten Root-Rechte selbst ab." >&2
    exit 1
fi

# 2. Harter Check für den SSH-Schlüssel (Abbruch bei Fehlen)
echo "=== Überprüfe SSH Schlüssel ==="
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "❌ CRITICAL ERROR: Der private SSH-Schlüssel (~/.ssh/id_ed25519) fehlt!" >&2
    echo "Das Setup wird abgebrochen. Bitte lege den Schlüssel zuerst an." >&2
    exit 1
fi

# Wenn der Key da ist, Berechtigungen sauber setzen
mkdir -p ~/.ssh
chmod 700 ~/.ssh
chmod 600 "$SSH_KEY_PATH"
if [ -f "${SSH_KEY_PATH}.pub" ]; then
    chmod 644 "${SSH_KEY_PATH}.pub"
fi

# SSH-Agent starten (nur wenn nicht schon aktiv) und Key hinzufügen
if [ -z "${SSH_AUTH_SOCK:-}" ]; then
    eval "$(ssh-agent -s)"
fi

# Key nur hinzufügen wenn noch nicht geladen (idempotent)
if ! ssh-add -l >/dev/null 2>&1 || ! ssh-add -l 2>/dev/null | grep -q "$(basename "$SSH_KEY_PATH")"; then
    ssh-add "$SSH_KEY_PATH"
    echo "✅ SSH-Schlüssel geladen."
else
    echo "✅ SSH-Schlüssel ist bereits geladen."
fi

# 3. System-Updates
echo -e "\n=== Starte System-Update ==="
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl git

# === GOOGLE CHROME INSTALLATION ===
echo -e "\n=== Überprüfe Google Chrome ==="
if [ -f /usr/bin/google-chrome-stable ]; then
    echo "✅ Google Chrome ist bereits installiert."
else
    echo "Google Chrome wird installiert..."
    mkdir -p ~/Downloads
    
    # Download mit Fehlerbehandlung
    CHROME_DEB=~/Downloads/google-chrome-stable_current_amd64.deb
    if wget -q -P ~/Downloads/ https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb; then
        if sudo apt install -y "$CHROME_DEB" 2>/dev/null; then
            rm -f "$CHROME_DEB"
            echo "✅ Google Chrome erfolgreich installiert."
            
            # Keyring-Abfrage direkt im systemweiten Starter unterdrücken
            if [ -f /usr/share/applications/google-chrome.desktop ]; then
                sudo sed -i 's|Exec=/usr/bin/google-chrome-stable %U|Exec=/usr/bin/google-chrome-stable --password-store=basic --disable-features=DbusSecretPortal %U|g' /usr/share/applications/google-chrome.desktop
            fi
        else
            echo "⚠️  Chrome-Installation fehlgeschlagen, aber .deb-Datei vorhanden." >&2
            rm -f "$CHROME_DEB"
        fi
    else
        echo "⚠️  Chrome-Download fehlgeschlagen, wird übersprungen." >&2
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
CURRENT_NAME=$(git config --global user.name || echo "")
CURRENT_EMAIL=$(git config --global user.email || echo "")

if [ "$CURRENT_NAME" = "$GIT_USER_NAME" ] && [ "$CURRENT_EMAIL" = "$GIT_USER_EMAIL" ]; then
    echo "✅ Git ist bereits korrekt konfiguriert."
else
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    echo "✅ Git erfolgreich aktualisiert."
fi




# === OLLAMA INSTALLATION & MODEL DOWNLOAD ===
echo -e "\n=== Überprüfe Ollama ==="
# Das offizielle install.sh ist idempotent – immer laufen lassen damit auch systemd-Service korrekt registriert wird
echo "Ollama wird installiert/aktualisiert..."
curl -fsSL https://ollama.com/install.sh | sh
echo "✅ Ollama installiert."

# Hintergrunddienst aktivieren und starten (mit Fehlertoleranz)
echo "Starte und aktiviere Ollama-Hintergrunddienst..."
sudo systemctl daemon-reload 2>/dev/null || true
sudo systemctl enable ollama 2>/dev/null || true
sudo systemctl start ollama 2>/dev/null || true

echo "Warte 5 Sekunden, bis der Server antwortet..."
sleep 5

echo -e "\n=== Überprüfe Ollama Standard-Modell ==="
MODEL_NAME="$OLLAMA_DEFAULT_MODEL"

# Modell-Abfrage mit Fehlerbehandlung
if ollama list 2>/dev/null | grep -q "$MODEL_NAME"; then
    echo "✅ Modell '$MODEL_NAME' ist bereits vorhanden."
else
    echo "Lade Standard-Modell '$MODEL_NAME' herunter..."
    ollama pull "$MODEL_NAME"
    echo "✅ Modell '$MODEL_NAME' erfolgreich heruntergeladen."
fi


# === HERMES AGENT INSTALLATION ===
echo -e "\n=== Überprüfe Hermes Agent ==="
if [ -f "$HOME/.local/bin/hermes" ]; then
    echo "✅ Hermes Agent ist bereits installiert."
else
    echo "Hermes Agent wird installiert..."
    
    # Der Trick: Erst sauber runterladen, damit die Tastatur/Eingabe frei bleibt
    HERMES_SCRIPT="/tmp/hermes_install_$$.sh"
    if curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh -o "$HERMES_SCRIPT"; then
        bash "$HERMES_SCRIPT"
        echo "✅ Hermes Agent erfolgreich installiert."
    else
        echo "⚠️  Hermes Agent Installation fehlgeschlagen, wird übersprungen." >&2
    fi
    
    # Temporäre Datei aufräumen
    rm -f "$HERMES_SCRIPT"
fi


echo -e "\n=== Setup erfolgreich abgeschlossen! ==="

# GNOME Settings nur anpassen wenn vorhanden
if command -v gsettings &> /dev/null; then
    echo "Passe GNOME-Einstellungen an..."
    # 1. Standby/Bildschirm ausschalten komplett deaktivieren (0 = Nie)
    gsettings set org.gnome.desktop.session idle-delay 0
    # 2. Die automatische Bildschirmsperre komplett abschalten
    gsettings set org.gnome.desktop.screensaver lock-enabled false
    echo "✅ GNOME-Einstellungen angepasst."
else
    echo "⚠️  gsettings nicht verfügbar, GNOME-Einstellungen werden übersprungen."
fi
