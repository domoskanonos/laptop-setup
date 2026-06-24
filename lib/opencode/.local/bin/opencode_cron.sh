#!/bin/bash

# --- 1. Parameter prüfen ---
if [ -z "$1" ]; then
    echo "Fehler: Keine Prompt-Datei als Parameter übergeben."
    echo "Nutzung: $0 /pfad/zu/prompt.md [/pfad/zum/arbeitsverzeichnis]"
    exit 1
fi

PROMPT_FILE="$1"

if [ ! -f "$PROMPT_FILE" ]; then
    echo "Fehler: Prompt-Datei '$PROMPT_FILE' existiert nicht."
    exit 1
fi

# --- 2. Arbeitsverzeichnis setzen (Parameter 2 oder Fallback) ---
if [ -n "$2" ] && [ -d "$2" ]; then
    WORKSPACE_DIR="$2"
else
    # Fallback-Verzeichnis, falls kein zweiter Parameter übergeben wird
    WORKSPACE_DIR="/home/laptop/_dev/repositories"
fi

cd "$WORKSPACE_DIR" || exit 1

# --- 3. Cron-Environment erzwingen ---
export HOME="${HOME:-/home/laptop}"
export USER="${USER:-laptop}"

# Node.js-Pfad ueber NVM aufloesen (fallback auf v22)
if [ -f "$HOME/.nvm/nvm.sh" ]; then
    . "$HOME/.nvm/nvm.sh"
    NVM_NODE_DIR="$(dirname "$(nvm which current 2>/dev/null)" 2>/dev/null)"
fi
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.local/bin:$HOME/.opencode/bin:${NVM_NODE_DIR:-$HOME/.nvm/versions/node/v22/bin}"

# --- 4. Dynamisches Logging aufbauen ---
# Isoliert den Dateinamen (z.B. "daily_podcast" aus "daily_podcast.md")
TASK_NAME=$(basename "$PROMPT_FILE" .md)
LOG_DIR="/home/laptop/logs/opencode"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/${TASK_NAME}.log"

# --- 5. Prompt einlesen und ausführen ---
# Wir lesen den Inhalt der Markdown-Datei in eine Variable
PROMPT_CONTENT=$(cat "$PROMPT_FILE")

echo "=====================================================" >> "$LOG_FILE"
echo "Starte Task: $TASK_NAME" >> "$LOG_FILE"
echo "Verzeichnis: $WORKSPACE_DIR" >> "$LOG_FILE"
echo "Zeitpunkt:   $(date)" >> "$LOG_FILE"
echo "=====================================================" >> "$LOG_FILE"

# Führe OpenCode mit dem Inhalt der Datei aus und setze ein Timeout (z.B. 30 Minuten)
timeout 30m opencode run --dir "$WORKSPACE_DIR" "$PROMPT_CONTENT" >> "$LOG_FILE" 2>&1

EXIT_CODE=$?

echo "-----------------------------------------------------" >> "$LOG_FILE"
echo "Task beendet: $(date) mit Exit-Code $EXIT_CODE" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"