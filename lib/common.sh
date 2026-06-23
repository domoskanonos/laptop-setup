set -euo pipefail

APT_ENV=(sudo DEBIAN_FRONTEND=noninteractive)

log()  { printf '[setup] %s\n' "$1"; }
warn() { printf '[warn] %s\n' "$1" >&2; }
die()  { printf '[error] %s\n' "$1" >&2; exit 1; }

command_exists()  { command -v "$1" >/dev/null 2>&1; }
is_loopback_host(){ [[ "$1" == "127.0.0.1" || "$1" == "::1" || "$1" == "localhost" ]]; }

retry() {
    local attempts=$1 delay=$2; shift 2
    local i=1; until "$@"; do (( i++ >= attempts )) && return 1
        warn "Befehl fehlgeschlagen, neuer Versuch in ${delay}s: $*"
        sleep "$delay"
    done
}

ensure_package()          { "${APT_ENV[@]}" apt-get install -y "$1"; }
ensure_snap()             { sudo snap install "$@"; }
ensure_service_running()  { sudo systemctl enable --now "$1" >/dev/null 2>&1 || true; }

set_env_kv() {
    local file=$1 key=$2 value=$3
    sed -i "/^${key}=/d" "$file" 2>/dev/null || true
    printf '%s=%s\n' "$key" "$value" >> "$file"
}

load_env_file() { set -a && source "$1" && set +a; }
