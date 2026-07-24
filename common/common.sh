set -euo pipefail

APT_ENV=(sudo DEBIAN_FRONTEND=noninteractive)

log()  { printf '[setup] %s\n' "$1"; }
warn() { printf '[warn] %s\n' "$1" >&2; }
die()  { printf '[error] %s\n' "$1" >&2; exit 1; }

command_exists()  { command -v "$1" >/dev/null 2>&1; }

ensure_package()          { "${APT_ENV[@]}" apt-get install -y "$1"; }
ensure_service_running()  { sudo systemctl enable --now "$1" >/dev/null 2>&1 || true; }

load_env_file() { set -a && source "$1" && set +a; }
