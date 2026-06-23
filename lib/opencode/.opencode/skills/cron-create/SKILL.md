---
name: cron-create
description: Erstellt einen neuen, zeitgesteuerten OpenCode-Task über das generische Cron-Skript.
compatibility: opencode
---

## Was ich tue
Ich füge der Crontab des aktuellen Benutzers einen neuen Eintrag hinzu, der das generische Skript `/home/laptop/.local/bin/opencode_cron.sh` aufruft.

## Wann du mich verwendest
Nutze mich, wenn der Benutzer einen automatischen, zeitgesteuerten Task oder Cronjob für OpenCode einrichten möchte.

## Anweisungen für den Agenten
1. Frage den Benutzer nach:
   - Dem absoluten Pfad zur Prompt-Datei (z. B. `/home/laptop/_dev/prompts/daily_podcast.md`)
   - Der gewünschten Uhrzeit oder dem Intervall (Standard: jeden Morgen um 04:00 Uhr)
   - Dem optionalen Arbeitsverzeichnis (Workspace)
2. Übersetze die Zeitangabe in das Standard-Cron-Format (`Minute Stunde Tag Monat Wochentag`).
3. Führe folgenden Bash-Befehl aus, um den Eintrag atomar an die bestehende Crontab anzuhängen:
```bash
   (crontab -l 2>/dev/null; echo "<MINUTE> <STUNDE> <TAG> <MONAT> <WOCHENTAG> /home/laptop/.local/bin/opencode_cron.sh <PROMPT_PFAD> <WORKSPACE_PFAD>") | crontab -