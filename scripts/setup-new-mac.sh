#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

log_info "Starting macOS setup..."

# Check for sudo access
if ! sudo -v; then
    log_error "This script requires sudo access"
    exit 1
fi

# Load environment variables
ENV_FILE="${SCRIPT_DIR}/../env/.env-install"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    log_error ".env-install file not found at $ENV_FILE"
    exit 1
fi

# Install Xcode Command Line Tools
install_xcode_tools() {
    if ! xcode-select -p &>/dev/null; then
        log_info "Installing Xcode Command Line Tools..."
        xcode-select --install
        
        log_info "Accepting Xcode license..."
        sudo xcodebuild -license accept || log_warn "Could not accept Xcode license automatically"
        
        if [[ $(uname -m) == 'arm64' ]]; then
            log_info "Installing Rosetta 2 for Apple Silicon..."
            sudo softwareupdate --install-rosetta --agree-to-license
        fi
    else
        log_info "Xcode Command Line Tools already installed"
    fi
}

# Install Oh My Zsh
install_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "Installing Oh My Zsh..."
        git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" || {
            log_error "Failed to clone Oh My Zsh"
            exit 1
        }
    else
        log_info "Oh My Zsh already installed"
    fi
}

# Install Homebrew
install_homebrew() {
    if ! command_exists brew; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
            log_error "Failed to install Homebrew"
            exit 1
        }
        
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        log_info "Homebrew already installed"
    fi
}

# Main execution
main() {
    install_xcode_tools
    install_oh_my_zsh
    install_homebrew
    
    cd "$SCRIPT_DIR"
    
    # Run setup scripts in order
    log_info "Setting up SSH keys..."
    ./setup-ssh-keys.sh "$SSH_EMAIL"
    
    log_info "Installing Homebrew packages..."
    ./install-brew-packages.sh
    
    log_info "Preventing database auto-start..."
    ./prevent-db-autostart.sh
    
    log_info "Installing shell plugins..."
    ./install-shell-plugins.sh
    
    log_info "Installing Spaceship theme..."
    ./install-spaceship-zsh-theme.sh
    
    log_info "Configuring Git..."
    ./configure-git-user.sh
    
    log_info "Deploying dotfiles..."
    ./deploy-dotfiles.sh
    
    ensure_directory "$HOME/Code"
    
    log_info "Setting up development environments..."
    ./setup-dev-environments.sh
    
    log_info "Applying macOS settings..."
    if [ -f "${SCRIPT_DIR}/../macos/macos.sh" ]; then
        "${SCRIPT_DIR}/../macos/macos.sh"
    else
        log_warn "macOS configuration script not found"
    fi
    
    log_info "Setup complete! Please restart your terminal."
}

# Run main function
main "$@"