#!/bin/bash

# Install claude-mem for all supported AI coding assistants.
#
# Runs `npx claude-mem install --ide <id>` once per IDE. The installer is
# idempotent: re-running is safe and will overwrite existing claude-mem
# config without touching unrelated settings.
#
# Integration shape per IDE:
#   claude-code → native plugin (marketplace add + install)
#   cursor      → hooks in ~/.cursor/hooks.json + MCP in ~/.cursor/mcp.json
#   codex-cli   → transcript watcher (~/.claude-mem/transcript-watch.json)
#                 + context injection into ~/.codex/AGENTS.md
#   goose       → MCP entry in ~/.config/goose/config.yaml (read-only)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# IDEs to install for. Each must match an ID in claude-mem's IDE list
# (see `npx claude-mem install --help` or src/npx-cli/index.ts upstream).
readonly IDES=(
    claude-code
    cursor
    codex-cli
    goose
)

install_claude_mem() {
    if ! command_exists npx; then
        log_error "npx not found -- install Node.js first"
        return 1
    fi

    log_info "Installing claude-mem for: ${IDES[*]}"

    local failed=()
    for ide in "${IDES[@]}"; do
        log_info "→ $ide"
        # Pipe </dev/null so @clack/prompts enters non-interactive mode
        # and doesn't try to render a multiselect we can't answer.
        if npx --yes claude-mem@latest install --ide "$ide" </dev/null; then
            log_info "✓ $ide"
        else
            log_warn "✗ $ide failed (continuing)"
            failed+=("$ide")
        fi
    done

    if [ ${#failed[@]} -gt 0 ]; then
        log_warn "claude-mem install finished with failures: ${failed[*]}"
        return 1
    fi

    log_info "claude-mem installed. Worker: 'npx claude-mem start', status: 'npx claude-mem status'"
    log_info "Dashboard: http://localhost:37777"
}

# Allow sourcing without running (for setup-new-mac.sh composition)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    install_claude_mem "$@"
fi
