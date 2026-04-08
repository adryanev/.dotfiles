#!/bin/bash

# Sync agent skills from remote repositories into the dotfiles skills directory.
# Currently syncs: vercel-labs/agent-skills
#
# Usage:
#   ./scripts/sync-agent-skills.sh          # Sync all configured repos
#   ./scripts/sync-agent-skills.sh --list   # List available skills and their source

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"
SOURCES_DIR="${DOTFILES_ROOT}/.claude/sources"
SKILLS_DIR="${DOTFILES_ROOT}/.claude/skills"

# ── Skill repos to sync ───────────────────────────────────────────────
# Add new repos here as "org/repo" entries.
SKILL_REPOS=(
    "vercel-labs/agent-skills"
)

# ── Functions ─────────────────────────────────────────────────────────

clone_or_pull() {
    local repo=$1
    local dest=$2

    if [ -d "$dest/.git" ]; then
        log_info "Pulling latest for $repo..."
        git -C "$dest" pull --ff-only --quiet
    else
        log_info "Cloning $repo..."
        ensure_directory "$(dirname "$dest")"
        git clone --depth 1 "https://github.com/${repo}.git" "$dest" --quiet
    fi
}

sync_skills_from_repo() {
    local repo=$1
    local repo_dir="${SOURCES_DIR}/$(echo "$repo" | tr '/' '-')"
    local skills_source="${repo_dir}/skills"

    clone_or_pull "$repo" "$repo_dir"

    if [ ! -d "$skills_source" ]; then
        log_warn "No skills/ directory found in $repo, skipping."
        return
    fi

    local count=0
    for skill_dir in "$skills_source"/*/; do
        [ -d "$skill_dir" ] || continue

        local skill_name
        skill_name=$(basename "$skill_dir")

        # Skip zip files and build tooling — only sync actual skill directories
        [ -f "${skill_dir}/SKILL.md" ] || continue

        local target="${SKILLS_DIR}/${skill_name}"
        log_info "Syncing skill: $skill_name"
        rsync -a --delete "$skill_dir" "$target/"
        count=$((count + 1))
    done

    log_info "Synced $count skills from $repo"
}

list_skills() {
    echo ""
    echo "Installed skills in ${SKILLS_DIR}:"
    echo ""

    for skill_dir in "$SKILLS_DIR"/*/; do
        [ -d "$skill_dir" ] || continue
        local name
        name=$(basename "$skill_dir")

        # Try to extract description from SKILL.md frontmatter
        local desc="(no description)"
        if [ -f "${skill_dir}/SKILL.md" ]; then
            desc=$(sed -n '/^description:/{ s/^description: *//; s/^"//; s/"$//; p; q; }' "${skill_dir}/SKILL.md")
            [ -z "$desc" ] && desc="(no description)"
        fi

        # Check if it came from a synced repo
        local source="local"
        for repo in "${SKILL_REPOS[@]}"; do
            local repo_dir="${SOURCES_DIR}/$(echo "$repo" | tr '/' '-')"
            if [ -d "${repo_dir}/skills/${name}" ]; then
                source="$repo"
                break
            fi
        done

        printf "  %-30s %-25s %s\n" "$name" "[$source]" "$desc"
    done
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────

main() {
    if [ "${1:-}" = "--list" ]; then
        list_skills
        exit 0
    fi

    ensure_directory "$SOURCES_DIR"
    ensure_directory "$SKILLS_DIR"

    for repo in "${SKILL_REPOS[@]}"; do
        log_info "━━━ Syncing from $repo ━━━"
        sync_skills_from_repo "$repo"
    done

    echo ""
    log_info "Done! Skills are up to date."
    log_info "Run with --list to see all installed skills."
}

main "$@"
