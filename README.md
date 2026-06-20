# Laptop Setup (Ubuntu 26.04)

Dieses Repository bietet zwei Wege:

- Ansible als bevorzugten, reproduzierbaren Weg
- bootstrap.sh fuer den Erststart auf frischen Systemen

Der empfohlene Standard ist Ansible, weil es idempotent ist und sich sehr gut testen und wiederholt ausfuehren laesst.

## Voraussetzungen

- Ubuntu 26.04 (oder Debian/Ubuntu kompatibel)
- Ein normaler Benutzer mit sudo Rechten
- Internetverbindung

## Konfiguration

Beispieldatei kopieren und anpassen:

    cp .env.example .env

Inhalt anpassen (Git Name, Mail, SSH Key Pfad, Ollama Modell).
Die Makefile-Targets laden .env automatisch vor dem Playbook-Lauf.

## Ansible Setup

Minimaler Bootstrap auf neuem System:

    ./bootstrap.sh

Alternative ohne vorheriges Klonen:

    curl -fsSL https://raw.githubusercontent.com/domoskanonos/laptop-setup/main/bootstrap.sh | bash

## Playbook testen und ausfuehren

Syntax check:

    make lint

Dry run mit Diff:

    make check

Echter Lauf:

    make apply

Idempotenz pruefen (zweimal hintereinander):

    make idempotence

## Wichtige Ordner

- ansible/site.yml: Einstiegspunkt
- ansible/inventories/local/hosts.yml: Lokales Inventory
- ansible/group_vars/local/main.yml: Variablen mit Defaults, ueberschreibbar per .env
- ansible/roles: Rollen fuer base, ssh, git, ollama

## Enthaltene Kerninstallationen

- Basispakete (curl, git, wget, openssh-server)
- OpenSSH Dienst aktiviert
- Visual Studio Code ueber Snap (code --classic, App-Store-kompatibler Updatepfad)

## Frisches System spaeter erneut aufsetzen

Auf einer neuen Maschine reichen danach diese Schritte:

    curl -fsSL https://raw.githubusercontent.com/domoskanonos/laptop-setup/main/bootstrap.sh | bash

## Bootstrap Script

bootstrap.sh installiert auf einem frischen Ubuntu-System die noetigen Tools (git, ansible, make), klont bei Bedarf das Repository nach ~/laptop-setup und fuehrt danach make deps sowie make apply aus.