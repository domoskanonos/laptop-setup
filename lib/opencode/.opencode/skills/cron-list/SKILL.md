---
name: cron-list
description: Listet alle aktuell eingerichteten OpenCode-Cronjobs des Benutzers auf.
compatibility: opencode
---

## Was ich tue
Ich lese die aktuelle Crontab des Benutzers aus und filtere nach den Tasks, die über `opencode_cron.sh` laufen.

## Wann du mich verwendest
Nutze mich, wenn der Benutzer wissen möchte, welche automatischen OpenCode-Tasks aktuell aktiv sind.

## Anweisungen für den Agenten
1. Führe den folgenden Bash-Befehl aus, um die Crontab zu lesen:
```bash
   crontab -l 2>/dev/null