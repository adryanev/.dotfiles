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
    stow_directory "nvim" "$HOME/.config"
    stow_directory "yazi" "$HOME/.config"
    
    # For git, stow only specific files (exclude .gitconfig)
    log_info "Stowing Git files (excluding .gitconfig)..."
    stow_files "git" "$HOME" ".gitmessage"
    stow_files "git" "$HOME" ".gitignore_global"

    # Stow all files from tmux directory to ~/.config/tmux
    stow_directory_files "tmux" "$HOME/.config/tmux"

    # Stow .zshrc
    stow_files "zsh" "$HOME" ".zshrc"

    # Stow .zshrc_sourced files
    stow_directory_files "zsh/.zshrc_sourced" "$HOME/.zshrc_sourced"

    # Stow only gpg-agent.conf
    stow_files "gnupg" "$HOME/.gnupg" "gpg-agent.conf"

    # Stow SSH config (config file only, never keys)
    stow_files "ssh" "$HOME/.ssh" "config"

    # Link user-facing scripts to ~/Scripts
    log_info "Linking user scripts to ~/Scripts..."
    ensure_directory "$HOME/Scripts"
    safe_symlink "$(pwd)/scripts/vscode-profile-manager.sh" "$HOME/Scripts/vscode-profile-manager.sh"
    safe_symlink "$(pwd)/scripts/sync-agent-skills.sh" "$HOME/Scripts/sync-agent-skills.sh"
    safe_symlink "$(pwd)/scripts/setup-llm-token-optimizer.sh" "$HOME/Scripts/setup-llm-token-optimizer.sh"

    # Stow launch agents
    log_info "Stowing launch agents..."
    ensure_directory "$HOME/Library/LaunchAgents"
    stow_directory_files "launchagents" "$HOME/Library/LaunchAgents"

    # Stow Claude Code configuration
    log_info "Stowing Claude Code configuration..."
    ensure_directory "$HOME/.claude"
    stow_files ".claude" "$HOME/.claude" "settings.json"
    stow_files ".claude" "$HOME/.claude" "settings.local.json"
    safe_symlink "$(pwd)/.claude/commands" "$HOME/.claude/commands"

    # Stow Codex configuration
    log_info "Stowing Codex configuration..."
    ensure_directory "$HOME/.codex"
    stow_files ".codex" "$HOME/.codex" "config.toml"
    stow_files ".codex" "$HOME/.codex" "hooks.json"

    # Stow OpenCode configuration
    log_info "Stowing OpenCode configuration..."
    ensure_directory "$HOME/.config/opencode"
    stow_files ".config/opencode" "$HOME/.config/opencode" "config.json"

    # Skills: ~/.agents/skills/ is the canonical hub for all skills.
    # Step 1: stow custom skills (dotfiles source) → ~/.agents/skills/
    log_info "Stowing custom skills to ~/.agents/skills/..."
    ensure_directory "$HOME/.agents/skills"
    stow_skill_directories "$(pwd)/.agents/skills" "$HOME/.agents/skills" "canonical"

    # Step 2: install external skills via npx (also lands in ~/.agents/skills/ + links agent dirs)
    log_info "Installing external skills via npx skills..."
    local registry_file="$(pwd)/.claude/skills-registry.txt"
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        npx --yes skills add "$line" --skill '*' -g -a claude-code -a codex -a opencode -y
    done < "$registry_file"

    # Step 3: link all of ~/.agents/skills/ → agent dirs (covers custom skills npx doesn't know about)
    log_info "Linking ~/.agents/skills/ to agent directories..."
    stow_skill_directories "$HOME/.agents/skills" "$HOME/.claude/skills" "Claude Code"
    stow_skill_directories "$HOME/.agents/skills" "$HOME/.codex/skills" "Codex"
    stow_skill_directories "$HOME/.agents/skills" "$HOME/.config/opencode/skills" "OpenCode"

    log_info "Stowing completed successfully!"
}

# Run main function
main "$@"
