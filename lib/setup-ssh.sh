if ! declare -f log >/dev/null 2>&1; then
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
fi

SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519}"

setup_ssh() {
    log "Pruefe SSH-Key"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    [[ -f "$SSH_KEY_PATH" ]] || die "SSH private key fehlt: $SSH_KEY_PATH"
    chmod 600 "$SSH_KEY_PATH"
    if [[ -f "${SSH_KEY_PATH}.pub" ]]; then
        chmod 644 "${SSH_KEY_PATH}.pub"
    fi
}
