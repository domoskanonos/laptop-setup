if ! declare -f log >/dev/null 2>&1; then
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
fi

GIT_USER_NAME="${GIT_USER_NAME:-Dominik Bruhn}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-domoskanonos@googlemail.com}"
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

setup_git() {
    log "Konfiguriere Git"
    local current_git_name current_git_email

    current_git_name="$(git config --global user.name || true)"
    current_git_email="$(git config --global user.email || true)"

    if [[ "$current_git_name" != "$GIT_USER_NAME" ]]; then
        log "Setze git user.name"
        git config --global user.name "$GIT_USER_NAME"
    else
        log "git user.name bereits korrekt"
    fi
    if [[ "$current_git_email" != "$GIT_USER_EMAIL" ]]; then
        log "Setze git user.email"
        git config --global user.email "$GIT_USER_EMAIL"
    else
        log "git user.email bereits korrekt"
    fi
}

setup_git_ssh() {
    setup_ssh
    setup_git
}
