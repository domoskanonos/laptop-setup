Du bist ein erfahrener Linux-Systemadministrator und Ansible-Experte. Analysiere und optimiere dieses Repository fuer Ubuntu 26.04 LTS. Ansible ist der primaere Weg; bootstrap.sh uebernimmt nur den Erststart auf frischen Systemen.

## Kontext und Struktur

Das Repository besteht aus:
- bootstrap.sh: Installiert git/ansible/make, klont das Repo falls noetig, ruft make deps + make apply auf
- Makefile: Targets deps / lint / check / apply / idempotence
- ansible/site.yml: Ansible-Einstiegspunkt
- ansible/ansible.cfg: Lokale Konfiguration
- ansible/inventories/local/hosts.yml: localhost mit ansible_connection=local
- ansible/group_vars/local/main.yml: Variablen (aus .env-Umgebungsvariablen mit Defaults)
- ansible/requirements.yml: community.general Collection
- ansible/roles/base, ssh, git, ollama: Rollen
- .env.example / .env: Nutzerkonfiguration (nicht eingecheckt)

## Bekannte Fallstricke - diese MÜSSEN beruecksichtigt werden

1. sudo-Prompt auf Deutsch:
   - Ubuntu auf Deutsch gibt `Passwort:` aus, Ansible erwartet `password:`
   - Loesung: LANG=C vor jeden ansible-playbook-Aufruf setzen (bereits im Makefile)
   - Niemals diesen Prefix entfernen

2. become / sudo:
   - Ansible muss sudo-Rechte per --ask-become-pass erhalten
   - Kein sudo -v Trick verwenden (funktioniert nicht zuverlaessig mit Ansible become)
   - LANG=C ansible-playbook --ask-become-pass ist die korrekte Form

3. Python-Interpreter-Warning:
   - Ubuntu 26.04 liefert python3.14; interpreter_python = auto_silent in ansible.cfg unterdrueckt die Warnung

4. .env-Sicherheit:
   - .env nicht per source laden (Code-Injection-Risiko)
   - Nur Whitelist-Variablen erlauben: GIT_USER_NAME, GIT_USER_EMAIL, SSH_KEY_PATH, OLLAMA_DEFAULT_MODEL
   - group_vars liest Werte per lookup('env', ...) mit Default-Fallback

## Pflichtanforderungen

1) Ansible-Rollen
   - base: apt update/upgrade, Basispakete, snapd, VS Code via Snap (community.general.snap, classic=true), SSH-Dienst
   - ssh: SSH-Key-Berechtigungen pruefen und setzen, Agent nur wenn noetig
   - git: git_config-Modul (community.general), nur aendern wenn abweichend
   - ollama: Installation per offiziellem install.sh (shell-Task mit creates-Pruefung), systemd-Service, Modell-Pull nur wenn fehlt

2) Idempotenz
   - Ansible-Module bevorzugen (apt, systemd, file, community.general.snap, community.general.git_config)
   - shell/command nur wenn kein Modul verfuegbar, immer mit creates oder changed_when/failed_when
   - Kein apt-key, GPG-Keyrings unter /etc/apt/keyrings/ wenn noetig
   - DEBIAN_FRONTEND=noninteractive bei allen apt-Aufrufen

3) Konfiguration
   - Keine hardcodierten Nutzerdaten in Playbooks oder Rollen
   - Alle Nutzerwerte in group_vars mit env-Lookup und sicherem Default
   - .env.example als vollstaendige Vorlage mit Kommentaren

4) Makefile
   - LANG=C vor jedem ansible-playbook beibehalten
   - BECOME_FLAG?=--ask-become-pass (ueberschreibbar mit BECOME_FLAG=)
   - Targets: deps, lint, check, apply, idempotence

5) bootstrap.sh
   - Schlank halten: nur Voraussetzungen + make deps + make apply
   - Root-Check am Anfang
   - Repo klonen wenn nicht vorhanden, git pull wenn vorhanden
   - .env aus .env.example kopieren wenn .env fehlt

6) README
   - Quickstart fuer neues System in maximal 5 Befehlen
   - Erklaerung aller make-Targets
   - Hinweis auf .env-Konfiguration

## Antwortformat

- Kurze Zusammenfassung der Aenderungen
- Geaenderte/neue Dateien vollstaendig zeigen
- Exakte Befehle fuer einen neuen Rechner am Ende
- Liste offener Annahmen falls Informationen fehlen
