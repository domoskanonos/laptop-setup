if ! declare -f log >/dev/null 2>&1; then
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
fi

GIT_USER_NAME="${GIT_USER_NAME:-Dominik Bruhn}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-domoskanonos@googlemail.com}"

setup_git() {

    log "Installiere Git"
    ensure_package git

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
