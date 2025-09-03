#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

log_info "Installing Spaceship Prompt theme for Zsh..."

# Check for Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log_error "Oh My Zsh is not installed. Please install Oh My Zsh first."
    exit 1
fi

# Configuration
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
THEMES_DIR="${ZSH_CUSTOM}/themes"
SPACESHIP_DIR="${THEMES_DIR}/spaceship-prompt"
SPACESHIP_REPO="https://github.com/spaceship-prompt/spaceship-prompt.git"

# Install or update Spaceship Prompt
install_spaceship() {
    ensure_directory "$THEMES_DIR"
    
    if [ -d "$SPACESHIP_DIR" ]; then
        log_info "Spaceship Prompt already installed, updating..."
        (
            cd "$SPACESHIP_DIR" || exit 1
            git pull origin master || {
                log_warn "Failed to update Spaceship Prompt"
                return 1
            }
        )
        log_info "Spaceship Prompt updated successfully"
    else
        log_info "Cloning Spaceship Prompt repository..."
        git clone "$SPACESHIP_REPO" "$SPACESHIP_DIR" --depth=1 || {
            log_error "Failed to clone Spaceship Prompt"
            exit 1
        }
        log_info "Spaceship Prompt cloned successfully"
    fi
}

# Create symlink for the theme
create_theme_symlink() {
    local SYMLINK_PATH="${ZSH_CUSTOM}/themes/spaceship.zsh-theme"
    local TARGET_PATH="${SPACESHIP_DIR}/spaceship.zsh-theme"
    
    if [ ! -f "$TARGET_PATH" ]; then
        log_error "Spaceship theme file not found at $TARGET_PATH"
        exit 1
    fi
    
    log_info "Creating theme symlink..."
    safe_symlink "$TARGET_PATH" "$SYMLINK_PATH"
    log_info "Theme symlink created"
}

# Verify installation
verify_installation() {
    local THEME_FILE="${ZSH_CUSTOM}/themes/spaceship.zsh-theme"
    
    if [ -L "$THEME_FILE" ] && [ -e "$THEME_FILE" ]; then
        log_info "Spaceship Prompt installed successfully!"
        log_info "To use it, set ZSH_THEME=\"spaceship\" in your .zshrc"
        
        # Check if already configured in .zshrc
        if grep -q "^ZSH_THEME=\"spaceship\"" "$HOME/.zshrc" 2>/dev/null; then
            log_info "Spaceship theme is already configured in .zshrc"
        else
            log_info "You may need to update ZSH_THEME in your .zshrc to \"spaceship\""
        fi
    else
        log_error "Installation verification failed"
        exit 1
    fi
}

# Main execution
main() {
    install_spaceship
    create_theme_symlink
    verify_installation
    
    log_info "Spaceship Prompt installation complete!"
    log_info "Restart your terminal or run: source ~/.zshrc"
}

# Run main function
main "$@"