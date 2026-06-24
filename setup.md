# Setup

## Verwendung

```bash
./setup.sh
```

Optionale Konfiguration über `.env`-Datei (siehe `.env.example`):

```bash
cp .env.example .env
# Variablen nach Bedarf anpassen
./setup.sh
```

## Module einzeln ausführen

Jedes Modul in `lib/` ist autark und kann standalone ausgeführt werden:

```bash
source lib/setup-ollama.sh && setup_ollama
source lib/setup-ssh.sh && setup_ssh
source lib/setup-bambu.sh && setup_bambu
```

> **Hinweis:** `setup_ssh` ist nicht im automatischen Ablauf von `setup.sh` enthalten, da SSH-Keys typischerweise manuell erstellt werden. Das Modul dient der nachträglichen Prüfung und Berechtigungskorrektur.

## Umgebungsvariablen

Über `.env` oder als Environment-Variable setzbar:

| Variable | Standard | Beschreibung |
|---|---|---|
| `GIT_USER_NAME` | `Dominik Bruhn` | Git-Benutzername |
| `GIT_USER_EMAIL` | `domoskanonos@googlemail.com` | Git-E-Mail |
| `SSH_KEY_PATH` | `$HOME/.ssh/id_ed25519` | Pfad zum SSH-Private-Key |
| `OLLAMA_DEFAULT_MODEL` | `qwen3.5:4b` | Standard-Ollama-Modell |

## Modulübersicht

| Modul | Funktion | Beschreibung |
|---|---|---|
| `lib/common.sh` | — | Gemeinsame Helfer (`log`, `die`, `ensure_package`, `load_env_file` u. a.) |
| `lib/setup-basic.sh` | `setup_basic` | System-Update, Basispakete (curl, git, wget, openssh-server, snapd, util-linux-extra), GNOME-Einstellungen |
| `lib/setup-vscode.sh` | `setup_vscode` | Installiert Visual Studio Code per Snap |
| `lib/setup-git.sh` | `setup_git` | Setzt `git user.name` und `user.email` |
| `lib/setup-ssh.sh` | `setup_ssh` | Prüft SSH-Key und setzt Berechtigungen (Standalone einsetzbar) |
| `lib/setup-uv.sh` | `setup_uv` | Installiert uv (Python-Paketmanager) |
| `lib/setup-ollama.sh` | `setup_ollama` | Installiert Ollama per Snap und lädt ein Modell vor |
| `lib/setup-bambu.sh` | `setup_bambu` | Lädt BambuStudio AppImage, erstellt Desktop-Starter |
| `lib/setup-whatsapp.sh` | `setup_whatsapp` | Installiert whatsdev per Snap |
| `lib/setup-nvidia.sh` | `setup_nvidia` | Installiert NVIDIA Container Toolkit für GPU-Unterstützung in Docker |
| `lib/setup-docker.sh` | `setup_docker` | Installiert Docker, Docker Compose und aktiviert den Dienst |
| `lib/opencode/setup-opencode.sh` | `setup_opencode` | Installiert OpenCode CLI und kopiert Konfiguration |
| `lib/opencode/config/opencode.jsonc` | — | OpenCode-Konfiguration mit MCP-Servern und Ollama-Provider |
| `lib/opencode/config/.env_example` | — | Vorlage für OpenCode-API-Key |
| `lib/opencode/config/prompts/daily_report.md` | — | Promptvorlage für taeglichen Report |
| `lib/opencode/config/skills/task-create/SKILL.md` | — | Skill: zeitgesteuerten Task anlegen |
| `lib/opencode/config/skills/task-delete/SKILL.md` | — | Skill: Task loeschen |
| `lib/opencode/config/skills/task-list/SKILL.md` | — | Skill: Tasks auflisten |
| `lib/opencode/.local/bin/opencode_cron.sh` | — | Cron-Wrapper fuer geplante Tasks |

## Projektstruktur

```
.
├── setup.sh                  # Entry-Point
├── setup.md                  # Setup-Dokumentation
├── .env                      # Lokale Konfiguration (gitignoriert)
├── .env.example              # Vorlage für .env
├── docker-compose.yaml       # Docker Compose für ComfyUI
├── docker-compose.md         # Docker Compose Befehle
├── lib/
│   ├── common.sh             # Basis-Funktionen
│   ├── setup-basic.sh        # System-Update & Basispakete
│   ├── setup-vscode.sh       # VS Code-Installation
│   ├── setup-git.sh          # Git-Konfiguration
│   ├── setup-ssh.sh          # SSH-Key-Prüfung
│   ├── setup-uv.sh           # uv-Installation
│   ├── setup-ollama.sh       # Ollama-Installation
│   ├── setup-nvidia.sh       # NVIDIA Container Toolkit
│   ├── setup-docker.sh       # Docker-Installation
│   ├── setup-bambu.sh        # BambuStudio-Installation
│   ├── setup-whatsapp.sh     # WhatsApp-Desktop (whatsdev)
│   └── opencode/
│       ├── setup-opencode.sh       # OpenCode CLI-Installation
│       ├── .local/bin/
│       │   └── opencode_cron.sh    # Cron-Wrapper
│       └── config/
│           ├── .env_example        # OpenCode-API-Key-Vorlage
│           ├── opencode.jsonc      # OpenCode-Konfiguration
│           ├── prompts/
│           │   └── daily_report.md # Promptvorlage
│           └── skills/
│               ├── task-create/SKILL.md
│               ├── task-delete/SKILL.md
│               └── task-list/SKILL.md
└── README.md
```
