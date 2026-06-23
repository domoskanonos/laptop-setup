---
name: task-create
description: Erstellt einen zeitgesteuerten, persistenten Task.
compatibility: opencode
---

## Anweisungen für den Agenten

1. **VALIDIERUNG:** Prüfe, ob der Benutzer folgende Informationen bereitgestellt hat:
   - Einen eindeutigen Namen für den Task (NAME)
   - Den Pfad zur Prompt-Datei (PROMPT_PFAD)
   - Das Arbeitsverzeichnis (WORKSPACE_PFAD)

2. **ABFRAGE-LOGIK:** 
   - Falls eine der drei Informationen fehlt, frage den Benutzer **explizit und einzeln** nach dem fehlenden Wert.
   - Führe KEINEN Befehl aus, solange die Informationen unvollständig sind!

3. **AUSFÜHRUNG:** Sobald alle Daten vorhanden sind, erstelle die Dateien:
   - Service-Datei unter `~/.config/systemd/user/opencode-[NAME].service`
   - Timer-Datei unter `~/.config/systemd/user/opencode-[NAME].timer`
   - Setze in der Service-Datei den `ExecStart`-Befehl auf: `/home/laptop/.local/bin/opencode_cron.sh [PROMPT_PFAD] [WORKSPACE_PFAD]`
   - Setze in der Timer-Datei `Persistent=true` und den gewünschten Zeitplan.
   - Aktiviere den Task mit: `systemctl --user daemon-reload && systemctl --user enable --now opencode-[NAME].timer`

4. **BESTÄTIGUNG:** Bestätige die Erstellung und nenne den Namen des neu angelegten Tasks.