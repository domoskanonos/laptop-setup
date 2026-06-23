if ! declare -f log >/dev/null 2>&1; then
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
fi

setup_uv() {
    curl -LsSf https://astral.sh/uv/install.sh | sh
}