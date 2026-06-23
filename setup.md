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

## Umgebungsvariablen

Über `.env` oder als Environment-Variable setzbar:

| Variable | Standard | Beschreibung |
|---|---|---|
| `GIT_USER_NAME` | `Dominik Bruhn` | Git-Benutzername |
| `GIT_USER_EMAIL` | `domoskanonos@googlemail.com` | Git-E-Mail |
| `SSH_KEY_PATH` | `$HOME/.ssh/id_ed25519` | Pfad zum SSH-Private-Key |
| `OLLAMA_DEFAULT_MODEL` | `qwen3.5:4b` | Standard-Ollama-Modell |
| `HERMES_DASHBOARD_HOST` | `0.0.0.0` | Hermes-Dashboard-Bind-Adresse |
| `HERMES_DASHBOARD_PORT` | `9119` | Hermes-Dashboard-Port |
| `HERMES_DASHBOARD_BASIC_AUTH_USERNAME` | `admin` | Dashboard-Benutzername |
| `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` | *(auto-generiert)* | Dashboard-Passwort |
| `HERMES_DASHBOARD_BASIC_AUTH_SECRET` | *(auto-generiert)* | Dashboard-Secret |

## Modulübersicht

| Modul | Funktion | Beschreibung |
|---|---|---|
| `lib/common.sh` | — | Gemeinsame Helfer (`log`, `die`, `ensure_package`, `retry`, `load_env_file` u. a.) |
| `lib/setup-basic.sh` | `setup_basic` | System-Update, Basispakete (curl, git, wget, openssh-server, snapd, util-linux-extra), GNOME-Einstellungen |
| `lib/setup-git.sh` | `setup_git` | Setzt `git user.name` und `user.email` |
| `lib/setup-ssh.sh` | `setup_ssh` | Prüft SSH-Key und setzt Berechtigungen (Standalone einsetzbar) |
| `lib/setup-uv.sh` | `setup_uv` | Installiert uv (Python-Paketmanager) |
| `lib/setup-ollama.sh` | `setup_ollama` | Installiert Ollama per Snap und lädt ein Modell vor |
| `lib/hermes/setup-hermes.sh` | `setup_hermes` | Installiert Hermes Agent und richtet Dashboard-Daemon ein (Standalone einsetzbar) |
| `lib/setup-bambu.sh` | `setup_bambu` | Lädt BambuStudio AppImage, erstellt Desktop-Starter |
| `lib/setup-whatsapp.sh` | `setup_whatsapp` | Installiert whatsdev per Snap |
| `lib/setup-docker.sh` | `setup_docker` | Installiert Docker, Docker Compose und aktiviert den Dienst |
| `lib/opencode/setup-opencode.sh` | `setup_opencode` | Installiert OpenCode CLI und kopiert Konfiguration |
| `lib/opencode/opencode.jsonc` | — | OpenCode-Konfiguration mit MCP-Servern und Ollama-Provider |

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
│   ├── setup-git.sh          # Git-Konfiguration
│   ├── setup-ssh.sh          # SSH-Key-Prüfung
│   ├── setup-uv.sh           # uv-Installation
│   ├── setup-ollama.sh       # Ollama-Installation
│   ├── setup-docker.sh       # Docker-Installation
│   ├── hermes/
│   │   ├── setup-hermes.sh   # Hermes Agent & Dashboard
│   │   └── config.yaml       # Hermes-Konfiguration
│   ├── setup-bambu.sh        # BambuStudio-Installation
│   ├── setup-whatsapp.sh     # WhatsApp-Desktop (whatsdev)
│   └── opencode/
│       ├── setup-opencode.sh # OpenCode CLI-Installation
│       └── opencode.jsonc    # OpenCode-Konfiguration
└── README.md
```
