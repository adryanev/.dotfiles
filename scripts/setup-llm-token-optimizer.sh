#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

readonly HEADROOM_SPEC="headroom-ai[proxy] @ git+https://github.com/chopratejas/headroom.git@main"
readonly HEADROOM_LABEL="ai.headroom.proxy"
readonly HEADROOM_PLIST_NAME="${HEADROOM_LABEL}.plist"
readonly HEADROOM_PLIST_SOURCE="${DOTFILES_ROOT}/launchagents/${HEADROOM_PLIST_NAME}"
readonly HEADROOM_PLIST_TARGET="$HOME/Library/LaunchAgents/${HEADROOM_PLIST_NAME}"
readonly HEADROOM_HEALTH_URL="http://127.0.0.1:8787/health"
readonly HEADROOM_STDERR_LOG="/tmp/${HEADROOM_LABEL}.err.log"
readonly HEADROOM_HEALTH_WAIT_SECONDS=180
readonly LAUNCHD_DOMAIN="gui/$(id -u)"

ensure_brew_package() {
    local package=$1

    if brew list "$package" &>/dev/null; then
        log_info "Homebrew package already installed: $package"
        return 0
    fi

    log_info "Installing Homebrew package: $package"
    brew install "$package"
}

install_headroom() {
    if pipx list | grep -Fq "package headroom-ai "; then
        log_info "Upgrading Headroom..."
        if pipx upgrade headroom-ai; then
            return 0
        fi

        log_warn "pipx upgrade failed, repairing Headroom install from main..."
    else
        log_info "Installing Headroom from main via pipx..."
    fi

    pipx install --force "$HEADROOM_SPEC"
}

link_launch_agent() {
    ensure_directory "$HOME/Library/LaunchAgents"
    safe_symlink "$HEADROOM_PLIST_SOURCE" "$HEADROOM_PLIST_TARGET"
}

reload_launch_agent() {
    if launchctl print "${LAUNCHD_DOMAIN}/${HEADROOM_LABEL}" &>/dev/null; then
        log_info "Unloading existing Headroom launch agent..."
        launchctl bootout "$LAUNCHD_DOMAIN" "$HEADROOM_PLIST_TARGET" || log_warn "Could not unload existing Headroom launch agent"
    fi

    log_info "Loading Headroom launch agent..."
    launchctl bootstrap "$LAUNCHD_DOMAIN" "$HEADROOM_PLIST_TARGET"
}

wait_for_health() {
    local attempt

    for ((attempt = 1; attempt <= HEADROOM_HEALTH_WAIT_SECONDS; attempt++)); do
        if curl -sf "$HEADROOM_HEALTH_URL" >/dev/null; then
            log_info "Headroom proxy is healthy"
            return 0
        fi

        sleep 1
    done

    log_error "Headroom proxy did not become healthy"
    if [ -f "$HEADROOM_STDERR_LOG" ]; then
        log_warn "Recent proxy stderr:"
        tail -n 20 "$HEADROOM_STDERR_LOG" || true
    fi
    return 1
}

main() {
    if ! command_exists brew; then
        log_error "Homebrew is required before setting up Headroom"
        exit 1
    fi

    ensure_brew_package "rtk"

    if ! command_exists pipx; then
        ensure_brew_package "pipx"
    fi

    install_headroom
    link_launch_agent
    reload_launch_agent
    wait_for_health

    log_info "Headroom version: $("$HOME/.local/bin/headroom" --version)"
    log_info "RTK version: $(rtk --version)"
}

main "$@"
