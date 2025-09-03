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

    # Stow all files from tmux directory
    stow_directory_files "tmux" "$HOME"

    # Stow .zshrc
    stow_files "zsh" "$HOME" ".zshrc"

    # Stow .zshrc_sourced files
    stow_directory_files "zsh/.zshrc_sourced" "$HOME/.zshrc_sourced"

    # Stow only gpg-agent.conf
    stow_files "gnupg" "$HOME/.gnupg" "gpg-agent.conf"

    log_info "Stowing completed successfully!"
}

# Run main function
main "$@"