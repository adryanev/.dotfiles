#!/bin/bash

# Register MCP servers with Claude Code and with claudex.
#
# Claude Code stores user-scope MCP servers in a JSON file inside its config
# directory: ~/.claude.json for the default install, and
# ~/.claudex/.claude.json when CLAUDE_CONFIG_DIR points at ~/.claudex. Those
# files also hold oauthAccount, userID and session caches, so they are
# deliberately NOT tracked in this repository and NOT stowed by
# deploy-dotfiles.sh. This script reproduces the registrations instead.
#
# Note that ~/.claude/.mcp.json is not read for user-scope servers: `.mcp.json`
# is the project-scope filename and is looked up in a project root, not in the
# config directory. Writing servers there has no effect.
#
# claudex is Claude Code run against the local cliproxyapi, and claude-dsp is
# Claude Code run against a separate account. Both use CLAUDE_CONFIG_DIR, which
# redirects the whole config directory, so neither inherits anything from
# ~/.claude and each needs its own registrations.
#
# Other agents (Codex, OpenCode, Cursor) keep their MCP configuration in files
# that ARE tracked and stowed, so they need nothing here.
#
# Idempotent: servers are removed and re-added, so changing a command or
# argument here and re-running applies the change.
#
# Usage:
#   ./setup-mcp-servers.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

SERENA_BIN="$HOME/.local/bin/serena"
CBM_BIN="$HOME/.local/bin/codebase-memory-mcp"
TABLEPRO_BIN="/Applications/TablePro.app/Contents/MacOS/tablepro-mcp"
CONTEXT7_URL="https://mcp.context7.com/mcp"

# CONTEXT7_API_KEY lives in ~/.zshrc_local, which is untracked and comes from
# the encrypted backup. It is sourced explicitly here because ~/.zshrc only
# loads for interactive shells, and this script is not one.
if [ -z "${CONTEXT7_API_KEY:-}" ] && [ -f "$HOME/.zshrc_local" ]; then
    # shellcheck disable=SC1091
    source "$HOME/.zshrc_local" 2>/dev/null || true
fi

if ! command_exists claude; then
    log_warn "claude CLI not found; skipping MCP server registration"
    exit 0
fi

# Register one server into one config directory.
#   $1 config dir ("" for the default ~/.claude)
#   $2 server name
#   $3.. command and arguments
# lib/common.sh sets `set -e`, and `claude mcp remove` exits 1 when the server
# is not present, which is the normal case on a first run. Both the remove and
# the add are therefore guarded with `|| true` / an explicit branch so one
# missing server cannot abort the whole script.
# Register a remote HTTP server carrying an API key header.
#   $1 config dir ("" for the default ~/.claude)
#   $2 server name
#   $3 url
#   $4 header, e.g. "x-api-key: <value>"
#
# The key is passed on the command line rather than stored in this repository.
register_http() {
    local config_dir=$1 name=$2 url=$3 header=$4
    local label="${config_dir:-~/.claude}"

    if [ -n "$config_dir" ]; then
        CLAUDE_CONFIG_DIR="$config_dir" claude mcp remove --scope user "$name" >/dev/null 2>&1 || true
        if CLAUDE_CONFIG_DIR="$config_dir" claude mcp add --scope user --transport http \
            "$name" "$url" --header "$header" >/dev/null 2>&1; then
            log_info "  registered $name (${label})"
        else
            log_warn "  failed to register $name (${label})"
        fi
    else
        claude mcp remove --scope user "$name" >/dev/null 2>&1 || true
        if claude mcp add --scope user --transport http \
            "$name" "$url" --header "$header" >/dev/null 2>&1; then
            log_info "  registered $name (${label})"
        else
            log_warn "  failed to register $name (${label})"
        fi
    fi
}

register() {
    local config_dir=$1 name=$2
    shift 2
    local label="${config_dir:-~/.claude}"

    # CLAUDE_CONFIG_DIR="" behaves differently from leaving it unset, so the
    # two cases are kept apart rather than passing an empty value.
    if [ -n "$config_dir" ]; then
        CLAUDE_CONFIG_DIR="$config_dir" claude mcp remove --scope user "$name" >/dev/null 2>&1 || true
        if CLAUDE_CONFIG_DIR="$config_dir" claude mcp add --scope user "$name" -- "$@" >/dev/null 2>&1; then
            log_info "  registered $name (${label})"
        else
            log_warn "  failed to register $name (${label})"
        fi
    else
        claude mcp remove --scope user "$name" >/dev/null 2>&1 || true
        if claude mcp add --scope user "$name" -- "$@" >/dev/null 2>&1; then
            log_info "  registered $name (${label})"
        else
            log_warn "  failed to register $name (${label})"
        fi
    fi
}

# Register the same servers into every Claude Code config directory in use.
# An empty entry means the default ~/.claude.
for config_dir in "" "$HOME/.claudex" "$HOME/.claude-dsp"; do
    label="${config_dir:-~/.claude}"

    # serena: symbolic code navigation and editing.
    #
    # --context claude-code is the upstream recommendation and differs from the
    # 'ide' context used for Cursor; it tunes tool descriptions for this client.
    # --project-from-cwd makes serena adopt whichever project the session
    # was started in.
    if [ -x "$SERENA_BIN" ]; then
        register "$config_dir" serena \
            "$SERENA_BIN" start-mcp-server --context claude-code --project-from-cwd
    else
        log_warn "serena not found at $SERENA_BIN"
        log_warn "Install it with: uv tool install -p 3.13 serena-agent"
    fi

    # codebase-memory-mcp: code knowledge graph.
    #
    # setup-codebase-memory.sh installs the binary and registers it for the
    # agents its installer detects, which does not include the claudex config
    # directory, so it is registered explicitly here.
    if [ -x "$CBM_BIN" ]; then
        register "$config_dir" codebase-memory-mcp "$CBM_BIN"
    else
        log_warn "codebase-memory-mcp not found; run ./setup-codebase-memory.sh"
    fi

    # tablepro: database access, shipped inside the TablePro app bundle
    # (cask "tablepro" in the Brewfile). Codex and OpenCode configure it in
    # their own tracked config files; this covers the Claude Code side.
    if [ -x "$TABLEPRO_BIN" ]; then
        register "$config_dir" tablepro "$TABLEPRO_BIN"
    else
        log_warn "tablepro-mcp not found; install TablePro (cask \"tablepro\")"
    fi

    # context7: remote documentation lookup. Codex and OpenCode reference the
    # key indirectly (env var / {env:...} placeholder) in their tracked configs;
    # Claude Code stores the resolved header, which is another reason
    # ~/.claude.json is not tracked here.
    if [ -n "${CONTEXT7_API_KEY:-}" ]; then
        register_http "$config_dir" context7 "$CONTEXT7_URL" \
            "x-api-key: $CONTEXT7_API_KEY"
    else
        log_warn "CONTEXT7_API_KEY not set; skipping context7 (${label})"
        log_warn "  restore ~/.zshrc_local from the encrypted backup, or set it there"
    fi
done

log_info "MCP server registration complete."
