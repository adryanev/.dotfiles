#!/bin/bash

# Install codebase-memory-mcp (https://github.com/DeusData/codebase-memory-mcp)
# and enable its graph visualisation UI.
#
# The project ships two builds. The default archive has no embedded UI: passing
# --ui=true to that binary prints a warning and starts no HTTP server. The UI is
# only present in the codebase-memory-mcp-ui asset, which the upstream installer
# selects when given --ui. That is why --ui is passed at install time and not
# only afterwards.
#
# The installer auto-detects installed agents (Claude Code, Codex CLI, OpenCode,
# Zed and others) and writes their MCP configuration itself, so this script does
# not manage those files. Note that ~/.codex/config.toml and
# ~/.config/opencode/opencode.jsonc are symlinks into this repository, so the
# installer writes through them into tracked files.
#
# Usage:
#   ./setup-codebase-memory.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

INSTALL_URL="https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh"
BIN="$HOME/.local/bin/codebase-memory-mcp"
UI_PORT="${CBM_UI_PORT:-9749}"

log_info "Installing codebase-memory-mcp (with UI)..."

if ! command_exists curl; then
    log_error "curl is required to install codebase-memory-mcp"
    exit 1
fi

# The installer is idempotent: re-running it upgrades in place.
if ! curl -fsSL "$INSTALL_URL" | bash -s -- --ui; then
    log_error "codebase-memory-mcp installation failed"
    exit 1
fi

if [ ! -x "$BIN" ]; then
    log_error "Expected binary not found at $BIN"
    exit 1
fi

log_info "Installed: $("$BIN" --version 2>/dev/null)"

# Enable the UI. This is persisted to ~/.cache/codebase-memory-mcp/config.json,
# so it only needs to be set once per machine. The binary starts a server when
# invoked this way, so it is stopped after the setting is written.
log_info "Enabling graph UI on port ${UI_PORT}..."
timeout 20 "$BIN" --ui=true --port="$UI_PORT" >/dev/null 2>&1

CONFIG="$HOME/.cache/codebase-memory-mcp/config.json"
if grep -q '"ui_enabled": *true' "$CONFIG" 2>/dev/null; then
    log_info "Graph UI enabled: http://localhost:${UI_PORT}"
else
    log_warn "Could not confirm ui_enabled in $CONFIG"
fi

log_info "codebase-memory-mcp setup complete."
