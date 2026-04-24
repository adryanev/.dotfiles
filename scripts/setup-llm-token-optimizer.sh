#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Headroom install spec: [all] extras pulls OCR, vision, and all compressors.
# Python 3.12 is required because rapidocr-onnxruntime>=1.4.0 does not ship
# wheels for 3.13 or 3.14 yet.
readonly HEADROOM_SPEC="headroom-ai[all] @ git+https://github.com/chopratejas/headroom.git@main"
readonly HEADROOM_PYTHON="/opt/homebrew/bin/python3.12"
readonly HEADROOM_BIN="$HOME/.local/bin/headroom"
readonly HEADROOM_PROFILE="default"
readonly HEADROOM_PORT=8787
readonly HEADROOM_HEALTH_URL="http://127.0.0.1:${HEADROOM_PORT}/readyz"
readonly HEADROOM_HEALTH_WAIT_SECONDS=180

# Legacy artifacts from the pre-0.9 manual launchd setup. We remove them so
# the modern headroom-managed service (com.headroom.default) owns the port.
readonly LEGACY_PLIST_TARGET="$HOME/Library/LaunchAgents/ai.headroom.proxy.plist"
readonly LEGACY_LAUNCHD_LABEL="ai.headroom.proxy"
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
    if [ ! -x "$HEADROOM_PYTHON" ]; then
        log_error "Python 3.12 not found at $HEADROOM_PYTHON (brew install python@3.12)"
        exit 1
    fi

    # Detect whether the existing venv is on a compatible interpreter.
    local needs_reinstall=0
    if pipx list | grep -Fq "package headroom-ai "; then
        local current_python
        current_python="$(pipx list --json 2>/dev/null | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["venvs"]["headroom-ai"]["metadata"]["main_package"]["python_version"])' 2>/dev/null || echo "")"
        if [[ "$current_python" != *"3.12"* ]]; then
            log_warn "Existing Headroom venv runs on ${current_python:-unknown} — rebuilding on Python 3.12"
            needs_reinstall=1
        fi
    else
        needs_reinstall=1
    fi

    if [ "$needs_reinstall" -eq 1 ]; then
        log_info "Installing Headroom via pipx on Python 3.12..."
        pipx uninstall headroom-ai &>/dev/null || true
        pipx install --python "$HEADROOM_PYTHON" "$HEADROOM_SPEC"
    else
        log_info "Upgrading Headroom..."
        pipx upgrade headroom-ai || {
            log_warn "pipx upgrade failed, reinstalling from main..."
            pipx install --force "$HEADROOM_SPEC"
        }
    fi
}

remove_legacy_launch_agent() {
    if launchctl print "${LAUNCHD_DOMAIN}/${LEGACY_LAUNCHD_LABEL}" &>/dev/null; then
        log_info "Unloading legacy Headroom launch agent..."
        launchctl bootout "$LAUNCHD_DOMAIN" "$LEGACY_PLIST_TARGET" \
            || log_warn "Could not unload ${LEGACY_LAUNCHD_LABEL}; continuing"
    fi

    if [ -L "$LEGACY_PLIST_TARGET" ] || [ -f "$LEGACY_PLIST_TARGET" ]; then
        log_info "Removing legacy launch agent symlink/file: $LEGACY_PLIST_TARGET"
        rm -f "$LEGACY_PLIST_TARGET"
    fi
}

install_persistent_service() {
    # headroom install apply writes and loads com.headroom.default.plist itself,
    # enabling KeepAlive + RunAtLoad. We target claude/codex/cursor explicitly
    # because --providers auto skips tools that are not on PATH at install time.
    log_info "Applying Headroom persistent service (all providers: claude, codex, cursor)..."
    "$HEADROOM_BIN" install apply \
        --preset persistent-service \
        --runtime python \
        --memory \
        --providers manual \
        --target claude \
        --target codex \
        --target cursor \
        --port "$HEADROOM_PORT" \
        --backend anthropic \
        --mode token
}

configure_agent_hooks() {
    log_info "Installing Claude Code durable hooks..."
    "$HEADROOM_BIN" init --global claude || log_warn "Claude Code hook install failed (Claude may not be installed)"

    log_info "Installing Codex durable hooks..."
    "$HEADROOM_BIN" init --global codex || log_warn "Codex hook install failed (Codex may not be installed)"
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

    log_error "Headroom proxy did not become healthy in ${HEADROOM_HEALTH_WAIT_SECONDS}s"
    log_warn "Check status with: headroom install status"
    return 1
}

print_cursor_instructions() {
    cat <<EOF

${GREEN}[INFO]${NC} Cursor requires a manual step (no config file to write):
    Settings > Models > OpenAI API Key > Override OpenAI Base URL
    Set to: http://127.0.0.1:${HEADROOM_PORT}/v1

EOF
}

main() {
    if ! command_exists brew; then
        log_error "Homebrew is required before setting up Headroom"
        exit 1
    fi

    # rtk: token-optimized CLI proxy (no setup beyond brew install).
    ensure_brew_package "rtk"
    ensure_brew_package "pipx"
    ensure_brew_package "python@3.12"

    remove_legacy_launch_agent
    install_headroom
    install_persistent_service
    configure_agent_hooks
    wait_for_health

    log_info "Headroom package version: $("$HEADROOM_PYTHON" -m pip show -q headroom-ai 2>/dev/null | awk '/^Version:/ {print $2}' || echo unknown)"
    log_info "RTK version: $(rtk --version 2>/dev/null || echo unknown)"
    print_cursor_instructions
}

main "$@"
