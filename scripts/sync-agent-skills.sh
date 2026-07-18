#!/bin/bash

# Install agent skills via `npx skills@latest add`.
#
# Two scopes:
#   global  - machine-wide skills you want in every project. Installed into the
#             ~/.agents/skills hub and symlinked into each agent directory.
#             Listed in <dotfiles>/.claude/skills-registry.txt.
#             This is what setup-new-mac.sh runs.
#   project - skills that only make sense inside one repository. Copied into
#             that repo's ./.claude/skills/ and recorded in its
#             skills-lock.json. Listed in <project>/.claude/skills-registry.txt.
#             Never run by setup-new-mac.sh; run it inside the project.
#
# Usage:
#   ./scripts/sync-agent-skills.sh             # global skills (default)
#   ./scripts/sync-agent-skills.sh --project   # project skills, from $PWD
#   ./scripts/sync-agent-skills.sh --list      # list installed global skills
#   ./scripts/sync-agent-skills.sh --list --project

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"

# ~/.agents/skills is the hub holding both the custom skills stowed from
# .agents/skills/ and the externally installed global ones.
SKILLS_HUB="$HOME/.agents/skills"

# Set by parse_scope(); the registry read depends on which scope is active.
SCOPE="global"
REGISTRY_FILE="${DOTFILES_ROOT}/.claude/skills-registry.txt"

# Switch to project scope. A registry inside the target repo wins; without one
# we fall back to this repo's registry and use its project-scoped entries as
# the candidate list.
use_project_scope() {
    SCOPE="project"

    local project_registry
    project_registry="$(pwd)/.claude/skills-registry.txt"
    if [ -f "$project_registry" ]; then
        REGISTRY_FILE="$project_registry"
    fi
}

# ── Functions ─────────────────────────────────────────────────────────

# Emit one "package<TAB>skills" line for each registry entry whose scope matches
# $SCOPE, skipping comments and blanks.
#
# A registry line is:
#   [scope] <package> [skill1,skill2,...]
# The leading scope is "global" or "project" and defaults to global when absent.
# The trailing skill list defaults to '*' (every skill in the package).
#
# The global IFS is $'\n\t' (set in lib/common.sh), so the per-command
# "IFS=$' \t'" below is what lets read split the fields on spaces.
# macOS ships bash 3.2, which has no namerefs, so this returns via stdout.
read_registry() {
    if [ ! -f "$REGISTRY_FILE" ]; then
        log_error "Skills registry not found at $REGISTRY_FILE"
        return 1
    fi

    local first second third scope package skills
    while IFS=$' \t' read -r first second third _ || [ -n "$first" ]; do
        [ -z "$first" ] && continue
        case "$first" in \#*) continue ;; esac

        case "$first" in
            global | project)
                scope="$first"
                package="$second"
                skills="$third"
                ;;
            *)
                scope="global"
                package="$first"
                skills="$second"
                ;;
        esac

        if [ -z "$package" ]; then
            log_warn "Ignoring malformed registry line starting with '$first'"
            continue
        fi

        [ "$scope" = "$SCOPE" ] || continue
        printf '%s\t%s\n' "$package" "${skills:-*}"
    done < "$REGISTRY_FILE"
}

# Turn a "a,b,c" skill list into repeated --skill flags. The CLI matches one
# name per flag; a single flag holding a comma- or space-separated list fails
# with "No matching skills found".
build_skill_args() {
    local list=$1

    if [ "$list" = "*" ]; then
        SKILL_ARGS=(--skill '*')
        return
    fi

    SKILL_ARGS=()
    local rest="$list" name
    while [ -n "$rest" ]; do
        name="${rest%%,*}"
        [ -n "$name" ] && SKILL_ARGS+=(--skill "$name")
        [ "$name" = "$rest" ] && break
        rest="${rest#*,}"
    done
}

install_skills_from_package() {
    local package=$1
    local skills=$2

    if ! command_exists npx; then
        log_warn "npx not found — skipping $package"
        return
    fi

    build_skill_args "$skills"

    if [ "$SCOPE" = "project" ]; then
        # -p installs into this repo only (./.agents/skills plus ./.claude/skills
        # and a skills-lock.json), so the project carries its own set.
        #
        # Project scope is interactive on purpose: a package can hold dozens of
        # skills and only a few belong in any one repo. Omitting -y and --skill
        # hands over to the CLI's own selection prompt. A registry line that
        # pins an explicit skill list skips the prompt and installs just those.
        if [ "$skills" = "*" ]; then
            log_info "Choose the skills to install from $package:"
            npx --yes skills add "$package" -p -a claude-code -a codex -a opencode ||
                log_warn "Failed to install skills from $package"
        else
            log_info "Installing from $package: $skills"
            npx --yes skills add "$package" "${SKILL_ARGS[@]}" -p -a claude-code -a codex -a opencode -y ||
                log_warn "Failed to install skills from $package"
        fi
        return
    fi

    log_info "Installing from $package: $skills"
    # -g installs into the ~/.agents/skills hub and symlinks each agent dir,
    # matching deploy-dotfiles.sh. Without -g, skills land as real directories
    # inside each agent dir, which defeats the single-source hub.
    npx --yes skills add "$package" "${SKILL_ARGS[@]}" -g -a claude-code -a codex -a opencode -y ||
        log_warn "Failed to install skills from $package"
}

list_skills() {
    local hub="${1:-$SKILLS_HUB}"

    echo ""
    echo "Skills in ${hub}:"
    echo ""

    if [ ! -d "$hub" ]; then
        echo "  (directory does not exist)"
        echo ""
        return 0
    fi

    for skill_dir in "$hub"/*/; do
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

# `npx skills -g` symlinks Claude Code but treats Codex/OpenCode as
# "universal" and does not link them. codex-cli reads ~/.codex/skills
# directly, so link every hub skill into the agent dirs that need explicit
# symlinks. Mirrors deploy-dotfiles.sh step 3.
link_hub_to_agents() {
    local hub="$HOME/.agents/skills"
    [ -d "$hub" ] || return

    local target
    for target in "$HOME/.codex/skills" "$HOME/.config/opencode/skills"; do
        ensure_directory "$target"
        for skill_dir in "$hub"/*; do
            [ -d "$skill_dir" ] || continue
            [ -f "$skill_dir/SKILL.md" ] || continue
            local name
            name=$(basename "$skill_dir")
            [ -e "$target/$name" ] && continue
            ln -s "$skill_dir" "$target/$name"
        done
    done
}

# ── Main ──────────────────────────────────────────────────────────────

main() {
    local do_list=0 arg
    local cli_packages=""

    for arg in "$@"; do
        case "$arg" in
            --list) do_list=1 ;;
            --project | -p) use_project_scope ;;
            --global | -g) ;; # the default
            -*)
                log_error "Unknown option: $arg"
                echo "Usage: $0 [--global|--project] [--list] [package ...]"
                exit 1
                ;;
            *) cli_packages="${cli_packages}${arg}"$'\t''*'$'\n' ;;
        esac
    done

    if [ "$do_list" -eq 1 ]; then
        if [ "$SCOPE" = "project" ]; then
            list_skills "$(pwd)/.claude/skills"
        else
            list_skills "$SKILLS_HUB"
        fi
        exit 0
    fi

    local packages
    if [ -n "$cli_packages" ]; then
        # Packages named on the command line bypass the registry entirely.
        log_info "Scope: $SCOPE (packages from command line)"
        packages="${cli_packages%$'\n'}"
    else
        log_info "Scope: $SCOPE (registry: $REGISTRY_FILE)"
        packages="$(read_registry)" || exit 1
    fi

    if [ -z "$packages" ]; then
        log_warn "No $SCOPE-scoped entries in $REGISTRY_FILE; nothing to install"
        if [ "$SCOPE" = "project" ]; then
            log_info "Mark entries with a leading 'project' keyword, add a registry"
            log_info "at ./.claude/skills-registry.txt, or name packages directly:"
            log_info "  $0 --project <package> ..."
        fi
        exit 0
    fi

    # Read the loop from fd 3, not stdin. npx inherits stdin, and reading the
    # package list from there lets it swallow bytes between iterations (which
    # truncated package names) and leaves nothing for the interactive picker
    # that project scope depends on.
    local package skills
    while IFS=$'\t' read -r package skills <&3; do
        log_info "━━━ $package ━━━"
        install_skills_from_package "$package" "$skills"
    done 3<<< "$packages"

    # Project skills are copied into the repo, so there is no hub to link.
    if [ "$SCOPE" = "global" ]; then
        log_info "Linking hub skills into Codex and OpenCode..."
        link_hub_to_agents
    fi

    echo ""
    log_info "Done! $SCOPE skills are up to date."
    log_info "Run with --list to see what is installed."
}

main "$@"
