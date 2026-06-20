#!/bin/bash

# Install agent skills via `npx skills@latest add`.
#
# Usage:
#   ./scripts/sync-agent-skills.sh          # Install all configured skill packages
#   ./scripts/sync-agent-skills.sh --list   # List available skills and their source

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="${DOTFILES_ROOT}/.claude/skills"

# ── Skill packages to install (npx skills@latest) ────────────────────
# Add new packages here as "org/repo" entries.
SKILL_PACKAGES=(
    "vercel-labs/agent-skills"
    "mattpocock/skills"
    "pbakaus/impeccable"
    "ast-grep/agent-skill"
)

# ── Functions ─────────────────────────────────────────────────────────

install_skills_from_package() {
    local package=$1

    if ! command_exists npx; then
        log_warn "npx not found — skipping $package"
        return
    fi

    log_info "Installing skills from $package via npx..."
    # -g installs into the ~/.agents/skills hub and symlinks each agent dir,
    # matching deploy-dotfiles.sh. Without -g, skills land as real directories
    # inside each agent dir, which defeats the single-source hub.
    npx --yes skills add "$package" --skill '*' -g -a claude-code -a codex -a opencode -y || log_warn "Failed to install skills from $package"
}

list_skills() {
    echo ""
    echo "Installed skills in ${SKILLS_DIR}:"
    echo ""

    for skill_dir in "$SKILLS_DIR"/*/; do
        [ -d "$skill_dir" ] || continue
        local name
        name=$(basename "$skill_dir")

        local desc="(no description)"
        if [ -f "${skill_dir}/SKILL.md" ]; then
            desc=$(sed -n '/^description:/{ s/^description: *//; s/^"//; s/"$//; p; q; }' "${skill_dir}/SKILL.md")
            [ -z "$desc" ] && desc="(no description)"
        fi

        printf "  %-30s %s\n" "$name" "$desc"
    done
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────

main() {
    if [ "${1:-}" = "--list" ]; then
        list_skills
        exit 0
    fi

    ensure_directory "$SKILLS_DIR"

    for package in "${SKILL_PACKAGES[@]}"; do
        log_info "━━━ Installing from $package ━━━"
        install_skills_from_package "$package"
    done

    echo ""
    log_info "Done! Skills are up to date."
    log_info "Run with --list to see all installed skills."
}

main "$@"
