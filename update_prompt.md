Du bist ein erfahrener Linux-Systemadministrator und Experte fuer Ansible und Bash. Deine Aufgabe ist es, dieses Repository fuer Ubuntu 26.04 so zu modernisieren, dass Ansible der primaere Setup-Weg ist und ein schlankes bootstrap.sh nur den Erststart uebernimmt.

WICHTIG:
- Fokus auf Ansible-Playbook statt monolithischem Bash-Skript.
- Alles idempotent umsetzen, so dass mehrfache Ausfuehrungen stabil bleiben.
- Keine hardcodierten Benutzerdaten im Code.
- Variablen aus .env uebernehmen oder ueber group_vars sauber konfigurierbar machen.
- Eine .env.example als Vorlage bereitstellen.

Pflichtanforderungen:

1) Ansible Struktur
- ansible/site.yml als Einstiegspunkt
- lokales Inventory fuer localhost
- Rollen fuer mindestens: base, ssh, git, ollama
- group_vars fuer konfigurierbare Werte
- ansible.cfg fuer lokale Ausfuehrung

2) Idempotenz und Sicherheit
- Ansible-Module bevorzugen statt shell/command, wo moeglich
- Nur wenn noetig aendern (least-change)
- Fehler klar melden
- Keine veralteten Ubuntu Methoden (kein apt-key)

3) Testbarkeit
- Syntax-Check und Dry-Run Befehle bereitstellen
- Wiederholte Ausfuehrung zur Idempotenz pruefbar machen
- Makefile Targets anlegen: deps, lint, check, apply, idempotence

4) Dokumentation
- README aktualisieren mit:
  - Bootstrap auf neuem System
  - Konfiguration ueber .env
  - Testen (lint/check)
  - Produktivlauf (apply)
  - Wiederholte Runs (idempotence)

5) Bootstrap Workflow
- Kein legacy Setup-Skript mehr im Repository
- bootstrap.sh bleibt bewusst klein und delegiert an make/ansible
- In README klar dokumentieren, wie bootstrap.sh auf neuen Systemen genutzt wird

Antwortformat:
- Erst kurz zusammenfassen, was geaendert wurde.
- Dann die neuen/angepassten Dateien mit Inhalt zeigen.
- Zum Schluss die exakten Befehle fuer einen neuen Rechner nennen.
