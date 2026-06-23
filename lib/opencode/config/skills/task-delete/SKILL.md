---
name: task-delete
description: Löscht einen zeitgesteuerten Task (Service und Timer) und deaktiviert ihn.
compatibility: opencode
---

## Anweisungen für den Agenten
1. **IDENTIFIKATION:** Frage den Benutzer nach dem exakten Namen des Tasks, der gelöscht werden soll (z. B. "podcast").
2. **PRÜFUNG:** Prüfe vorab, ob die Timer-Datei `~/.config/systemd/user/opencode-[NAME].timer` existiert. 
   - Falls nicht, informiere den Benutzer: "Task [NAME] wurde nicht gefunden." und breche ab.
3. **AUSFÜHRUNG:** Führe die Löschung nur aus, wenn der Task existiert:
```bash
   systemctl --user disable --now opencode-[NAME].timer
   rm ~/.config/systemd/user/opencode-[NAME].timer
   rm ~/.config/systemd/user/opencode-[NAME].service
   systemctl --user daemon-reload