# Setup

## Verwendung

```bash
./setup.sh
```

Das Skript fragt nach Laptop oder Server und führt das entsprechende Setup aus.

## Module einzeln ausführen

Jedes Modul ist autark und kann standalone ausgeführt werden:

```bash
source common/setup-ollama.sh && setup_ollama
source common/setup-ssh.sh && setup_ssh
source laptop/setup-bambu.sh && setup_bambu
```

> **Hinweis:** `setup_ssh` ist nicht im automatischen Ablauf enthalten, da SSH-Keys typischerweise manuell erstellt werden. Das Modul dient der nachträglichen Prüfung und Berechtigungskorrektur.

## Umgebungsvariablen

Über `.env` (im Repository-Root) oder als Environment-Variable setzbar:

| Variable | Standard | Beschreibung |
|---|---|---|
| `GIT_USER_NAME` | `Dominik Bruhn` | Git-Benutzername |
| `GIT_USER_EMAIL` | `domoskanonos@googlemail.com` | Git-E-Mail |
| `SSH_KEY_PATH` | `$HOME/.ssh/id_ed25519` | Pfad zum SSH-Private-Key |
| `OLLAMA_DEFAULT_MODEL` | `qwen3.5:4b` | Standard-Ollama-Modell |

## Modulübersicht

### Common (beide Systeme)

| Quelle | Funktion | Beschreibung |
|---|---|---|
| `common/common.sh` | — | Gemeinsame Helfer (`log`, `die`, `ensure_package`, `load_env_file`) |
| `common/setup-basic.sh` | `setup_basic` | System-Update, Basispakete (curl, git, wget, ssh, snapd, pandoc, nodejs, ffmpeg) |
| `common/setup-git.sh` | `setup_git` | Setzt `git user.name` und `user.email` |
| `common/setup-ssh.sh` | `setup_ssh` | Prüft SSH-Key und setzt Berechtigungen |
| `common/setup-uv.sh` | `setup_uv` | Installiert uv (Python-Paketmanager) |
| `common/setup-nvidia.sh` | `setup_nvidia` | Installiert NVIDIA Container Toolkit |
| `common/setup-docker.sh` | `setup_docker` | Installiert Docker, Docker Compose |
| `common/opencode/setup-opencode.sh` | `setup_opencode` | Installiert OpenCode CLI und Konfiguration |
| `common/opencode/config/opencode.jsonc` | — | OpenCode-Konfiguration mit MCP-Servern |
| `common/opencode/config/.env_example` | — | Vorlage für OpenCode-API-Key |
| `common/opencode/config/prompts/daily_report.md` | — | Promptvorlage für täglichen Report |
| `common/opencode/config/skills/` | — | Skills für Task-Management |
| `common/prompts/media/video/videokomprimierer.md` | — | Prompt für ffmpeg-Videokompression |

### Laptop-spezifisch

| Quelle | Funktion | Beschreibung |
|---|---|---|
| `laptop/setup.sh` | — | Entry-Point (laptop) |
| `laptop/setup-vscode.sh` | `setup_vscode` | Visual Studio Code |
| `laptop/setup-ollama.sh` | `setup_ollama` | Ollama (Snap) inkl. Modellvorladung |
| `laptop/setup-bambu.sh` | `setup_bambu` | BambuStudio AppImage + Desktop-Starter |
| `laptop/setup-whatsapp.sh` | `setup_whatsapp` | whatsdev (Snap) |
| `laptop/setup-desktop.sh` | `setup_desktop` | Desktop-Pakete + GNOME-Konfiguration |
| `laptop/docker-compose.yaml` | — | Alle Docker-Dienste (ComfyUI, TTS, Jellyfin, Immich, Navidrome, Dozzle, FreshRSS, Radio-Ripper) |
| `laptop/.env` | — | .env für laptop |

### Server-spezifisch

| Quelle | Funktion | Beschreibung |
|---|---|---|
| `server/setup.sh` | — | Entry-Point (server) |
| `server/setup-basic.sh` | `setup_basic` | Server-Basispakete |
| `server/docker-compose.yaml` | — | Docker-Dienste (Jellyfin, Immich, Navidrome, Dozzle, FreshRSS, Radio-Ripper) |
| `server/.env` | — | .env für server |

## Projektstruktur

```
.
├── setup.sh                  # Entry-Point (Geräteauswahl)
├── setup.md                  # Setup-Dokumentation
├── .env                      # Lokale Konfiguration (gitignoriert)
├── README.md
│
├── common/                   # Gemeinsame Module
│   ├── common.sh
│   ├── setup-basic.sh
│   ├── setup-git.sh
│   ├── setup-ssh.sh
│   ├── setup-uv.sh
│   ├── setup-nvidia.sh
│   ├── setup-docker.sh
│   ├── opencode/
│   │   ├── setup-opencode.sh
│   │   ├── .local/bin/opencode_cron.sh
│   │   └── config/
│   │       ├── opencode.jsonc
│   │       ├── .env_example
│   │       ├── prompts/daily_report.md
│   │       └── skills/
│   └── prompts/media/video/videokomprimierer.md
│
├── laptop/                   # Laptop-spezifisch (Desktop + GPU)
│   ├── setup.sh
│   ├── setup-vscode.sh
│   ├── setup-ollama.sh
│   ├── setup-bambu.sh
│   ├── setup-whatsapp.sh
│   ├── setup-desktop.sh
│   ├── docker-compose.yaml
│   └── .env
│
└── server/                   # Server-spezifisch (Headless)
    ├── setup.sh
    ├── setup-basic.sh
    ├── docker-compose.yaml
    └── .env
```
