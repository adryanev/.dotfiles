#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Move to the dotfiles root directory
DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$DOTFILES_ROOT" || {
    log_error "Failed to change to dotfiles directory"
    exit 1
}

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --dry-run | -n)
            export DRY_RUN=1
            log_warn "Dry-run mode: reporting actions only, no changes will be made."
            ;;
        -h | --help)
            echo "Usage: deploy-dotfiles.sh [--dry-run|-n]"
            exit 0
            ;;
        *)
            log_error "Unknown argument: $arg"
            echo "Usage: deploy-dotfiles.sh [--dry-run|-n]"
            exit 1
            ;;
    esac
done

log_info "Working directory set to: $(pwd)"
log_info "Creating symlinks for dotfiles..."

# Function to safely stow a directory
stow_directory() {
    local dir=$1
    local target=$2

    log_info "Linking $dir to $target..."

    # Create source directory if it doesn't exist
    if [ ! -d "$dir" ]; then
        log_warn "Directory $dir not found, creating it..."
        ensure_directory "$dir"
    fi

    # Create target directory if it doesn't exist
    ensure_directory "$target"

    # Use safe_symlink for atomic operation
    local target_path="$target/$dir"
    safe_symlink "$(pwd)/$dir" "$target_path"
}

# Function to stow individual files
stow_files() {
    local source_dir=$1
    local target_dir=$2
    local file_pattern=${3:-}  # Optional: can be a specific filename or pattern

    log_info "Stowing files from $source_dir to $target_dir..."

    # Create source directory if it doesn't exist
    if [ ! -d "$source_dir" ]; then
        log_warn "Source directory $source_dir not found, creating it..."
        ensure_directory "$source_dir"
    fi

    # Create target directory if it doesn't exist
    ensure_directory "$target_dir"

    # Set appropriate permissions for sensitive directories
    if [[ "$target_dir" == *".gnupg"* ]]; then
        chmod 700 "$target_dir"
    fi

    # If a specific file pattern is provided
    if [ -n "$file_pattern" ]; then
        if [ -f "$source_dir/$file_pattern" ]; then
            log_info "Stowing $file_pattern..."
            safe_symlink "$(pwd)/$source_dir/$file_pattern" "$target_dir/$file_pattern"
        else
            log_warn "$file_pattern not found in $source_dir, skipping..."
        fi
    else
        # Stow all files, but not directories
        log_info "Stowing all files from $source_dir..."
        for file in "$source_dir"/*; do
            if [ -f "$file" ]; then
                local filename=$(basename "$file")
                safe_symlink "$(pwd)/$source_dir/$filename" "$target_dir/$filename"
            fi
        done
    fi
}

# Function to stow all files in a directory including hidden files
stow_directory_files() {
    local source_dir=$1
    local target_dir=$2

    log_info "Stowing all files from $source_dir to $target_dir..."

    # Create source directory if it doesn't exist
    if [ ! -d "$source_dir" ]; then
        log_warn "Source directory $source_dir not found, creating it..."
        ensure_directory "$source_dir"
    fi

    # Create target directory if it doesn't exist
    ensure_directory "$target_dir"

    # Stow all files in the directory including hidden files
    shopt -s dotglob # Enable expansion to include hidden files
    for file in "$source_dir"/*; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            safe_symlink "$(pwd)/$source_dir/$filename" "$target_dir/$filename"
        fi
    done
    shopt -u dotglob # Disable dotglob after we're done
}

stow_skill_directories() {
    local source_dir=$1
    local target_dir=$2
    local label=$3

    log_info "Stowing ${label} skills from $source_dir to $target_dir..."

    if [ ! -d "$source_dir" ]; then
        log_warn "Skill source directory $source_dir not found, skipping..."
        return
    fi

    ensure_directory "$target_dir"

    for skill_dir in "$source_dir"/*; do
        [ -d "$skill_dir" ] || continue
        [ -f "$skill_dir/SKILL.md" ] || continue
        [[ "$(basename "$skill_dir")" == *.backup.* ]] && continue

        local skill_name
        skill_name=$(basename "$skill_dir")
        safe_symlink "$skill_dir" "$target_dir/$skill_name"
    done
}

# Main execution
main() {
    # Ensure .config directory exists
    ensure_directory "$HOME/.config"

    # Stow each directory
    stow_directory "ghostty" "$HOME/.config"
    stow_directory "kitty" "$HOME/.config"
    stow_directory "nvim" "$HOME/.config"
    stow_directory "yazi" "$HOME/.config"
    
    # Cursor MCP servers. This file was tracked but never deployed, so its
    # contents had no effect until now.
    log_info "Stowing Cursor configuration..."
    ensure_directory "$HOME/.cursor"
    stow_files ".cursor" "$HOME/.cursor" "mcp.json"

    # For git, stow only specific files (exclude .gitconfig)
    log_info "Stowing Git files (excluding .gitconfig)..."
    stow_files "git" "$HOME" ".gitmessage"
    stow_files "git" "$HOME" ".gitignore_global"

    # Stow all files from tmux directory to ~/.config/tmux
    stow_directory_files "tmux" "$HOME/.config/tmux"

    # asdf global tool versions. Symlinked so version changes made with
    # `asdf set --home` are tracked here instead of drifting silently.
    log_info "Stowing asdf tool versions..."
    stow_files "asdf" "$HOME" ".tool-versions"

    # Stow .zshrc
    stow_files "zsh" "$HOME" ".zshrc"

    # .zshenv runs for non-interactive shells too, which is how secrets in
    # ~/.zshrc_local reach clients launched outside a terminal (see the file).
    stow_files "zsh" "$HOME" ".zshenv"

    # Stow .zshrc_sourced files
    stow_directory_files "zsh/.zshrc_sourced" "$HOME/.zshrc_sourced"

    # Stow only gpg-agent.conf
    stow_files "gnupg" "$HOME/.gnupg" "gpg-agent.conf"

    # Stow SSH config (config file only, never keys)
    stow_files "ssh" "$HOME/.ssh" "config"

    # Link user-facing scripts to ~/Scripts
    log_info "Linking user scripts to ~/Scripts..."
    ensure_directory "$HOME/Scripts"
    safe_symlink "$(pwd)/scripts/sync-agent-skills.sh" "$HOME/Scripts/sync-agent-skills.sh"
    safe_symlink "$(pwd)/scripts/start-tmux.sh" "$HOME/Scripts/start-tmux.sh"

    # No launch agents are stowed. The launchagents/ directory held only the
    # Headroom proxy agent, which has been removed.

    # Stow Claude Code configuration
    log_info "Stowing Claude Code configuration..."
    ensure_directory "$HOME/.claude"
    stow_files ".claude" "$HOME/.claude" "settings.json"
    stow_files ".claude" "$HOME/.claude" "settings.local.json"
    stow_files ".claude" "$HOME/.claude" "CLAUDE.md"

    # Claude Code MCP servers are NOT stowed. `claude mcp add --scope user`
    # writes them to ~/.claude.json, which also holds oauthAccount, userID and
    # session caches, so that file is not tracked here. setup-mcp-servers.sh
    # registers them instead.
    safe_symlink "$(pwd)/.claude/commands" "$HOME/.claude/commands"

    # claude-dsp CLAUDE.md is a symlink to the canonical .claude/CLAUDE.md
    log_info "Stowing claude-dsp configuration..."
    ensure_directory "$HOME/.claude-dsp"
    safe_symlink "$(pwd)/.claude/CLAUDE.md" "$HOME/.claude-dsp/CLAUDE.md"

    # Stow Codex configuration
    log_info "Stowing Codex configuration..."
    ensure_directory "$HOME/.codex"
    stow_files ".codex" "$HOME/.codex" "config.toml"
    stow_files ".codex" "$HOME/.codex" "hooks.json"
    stow_files ".codex" "$HOME/.codex" "AGENTS.md"

    # Stow Claudex configuration (Claude Code against the local cliproxyapi)
    #
    # claudex is Claude Code run with CLAUDE_CONFIG_DIR=~/.claudex, which
    # redirects settings, CLAUDE.md, skills and the MCP registry to that
    # directory. Nothing falls back to ~/.claude, so the shared parts are
    # linked in explicitly below.
    #
    # settings.json is claudex-specific (it points at the local proxy and
    # overrides the models), so it comes from .claudex/, not .claude/.
    log_info "Stowing Claudex configuration..."
    ensure_directory "$HOME/.claudex"
    stow_files ".claudex" "$HOME/.claudex" "settings.json"

    # Shared with Claude Code: same instructions, same local settings, same
    # skills. MCP servers are registered separately by setup-mcp-servers.sh.
    safe_symlink "$(pwd)/.claude/CLAUDE.md" "$HOME/.claudex/CLAUDE.md"
    safe_symlink "$(pwd)/.claude/settings.local.json" "$HOME/.claudex/settings.local.json"
    if [ -e "$HOME/.claude/skills" ]; then
        safe_symlink "$HOME/.claude/skills" "$HOME/.claudex/skills"
    fi

    # cliproxyapi config is NOT symlinked: it holds the remote-management
    # secret, so the real file stays out of this public repo. Seed it from the
    # example on first run only; an existing config is never overwritten.
    log_info "Seeding cliproxyapi configuration..."
    ensure_directory "$HOME/.config/cliproxyapi"
    local cliproxy_config="$HOME/.config/cliproxyapi/config.yaml"
    if [ -e "$cliproxy_config" ]; then
        log_info "cliproxyapi config already present, leaving it untouched: $cliproxy_config"
    elif [ "$DRY_RUN" = "1" ]; then
        log_info "[dry-run] Would seed $cliproxy_config from cliproxyapi/config.yaml.example"
    else
        cp "$(pwd)/cliproxyapi/config.yaml.example" "$cliproxy_config"
        chmod 600 "$cliproxy_config"
        log_warn "Seeded $cliproxy_config from the example; set remote-management.secret-key before use."
    fi

    # Point the Homebrew service at the config above.
    #
    # `brew services start cliproxyapi` runs the binary with no -config flag,
    # so it uses its compiled-in default of $(brew --prefix)/etc/cliproxyapi.conf
    # and ignores ~/.config entirely. Left alone, the service runs Homebrew's
    # shipped template, whose placeholder api-keys (your-api-key-1 ...) make it
    # refuse every proxy request. Symlinking keeps one source of truth without
    # having to manage a custom LaunchAgent.
    if command_exists brew; then
        local brew_cliproxy_config
        brew_cliproxy_config="$(brew --prefix)/etc/cliproxyapi.conf"
        if [ -e "$brew_cliproxy_config" ] || [ -L "$brew_cliproxy_config" ]; then
            safe_symlink "$cliproxy_config" "$brew_cliproxy_config"
        fi
    fi

    # Stow OpenCode configuration
    log_info "Stowing OpenCode configuration..."
    ensure_directory "$HOME/.config/opencode"
    stow_files ".config/opencode" "$HOME/.config/opencode" "opencode.jsonc"

    # Skills: ~/.agents/skills/ is the canonical hub for all skills.
    # Step 1: stow custom skills (dotfiles source) → ~/.agents/skills/
    log_info "Stowing custom skills to ~/.agents/skills/..."
    ensure_directory "$HOME/.agents/skills"
    stow_skill_directories "$(pwd)/.agents/skills" "$HOME/.agents/skills" "canonical"

    # External skills are NOT installed here. Deploying dotfiles is a local
    # symlink operation and should not reach the network. They are installed
    # from .claude/skills-registry.txt by scripts/sync-agent-skills.sh
    # (`make skills`), which is the only installer.

    # Step 2: link all of ~/.agents/skills/ → agent dirs (covers custom skills npx doesn't know about)
    log_info "Linking ~/.agents/skills/ to agent directories..."
    stow_skill_directories "$HOME/.agents/skills" "$HOME/.claude/skills" "Claude Code"
    stow_skill_directories "$HOME/.agents/skills" "$HOME/.codex/skills" "Codex"
    stow_skill_directories "$HOME/.agents/skills" "$HOME/.config/opencode/skills" "OpenCode"

    # The Compound Engineering plugin is deliberately not installed. Deploying
    # dotfiles is a local symlink operation and does not reach the network.

    log_info "Stowing completed successfully!"
}

# Run main function
main "$@"
