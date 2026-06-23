---
name: task-list
description: Listet alle konfigurierten OpenCode-Tasks auf und zeigt deren Status.
compatibility: opencode
---

## Was ich tue
Ich frage das System nach allen aktiven Timern ab und filtere speziell nach deinen OpenCode-Automatisierungen.

## Anweisungen für den Agenten
1. Führe den folgenden Befehl aus, um alle Timer aufzulisten:
```bash
   systemctl --user list-timers --all

2. Filtere das Ergebnis so, dass nur Zeilen angezeigt werden, die mit opencode- beginnen.

3. Formatiere die Ausgabe für den Benutzer in einer Tabelle:
   Task-Name: Der Name des Timers.
   Nächster Lauf: Wann der Task das nächste Mal ansteht.
   Letzter Lauf: Wann der Task zuletzt erfolgreich ausgeführt wurde (sehr hilfreich, um zu sehen, ob ein "nachgeholter" Job lief).

4. Wenn keine passenden Timer gefunden wurden, antworte: "Es sind aktuell keine OpenCode-Tasks konfiguriert."