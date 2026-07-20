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
    install_homebrew

    cd "$SCRIPT_DIR" || exit 1

    # Homebrew packages come first: the restore below needs gpg, which is
    # installed from the Brewfile.
    log_info "Installing Homebrew packages..."
    ./install-brew-packages.sh

    # Secrets are not tracked in this repository. They live in an encrypted
    # archive in iCloud and are restored here: SSH keys, the GPG signing key,
    # cliproxyapi credentials, and ~/.zshrc_local.
    #
    # Non-fatal on purpose. A machine with no prior backup falls through to the
    # generate-a-new-key paths in the scripts below.
    log_info "Restoring secrets from the encrypted iCloud backup..."
    ./post-reinstall-restore.sh ||
        log_warn "No backup restored; new keys will be generated where needed"

    install_oh_my_zsh

    log_info "Setting up SSH keys..."
    ./setup-ssh-keys.sh "$SSH_EMAIL"

    log_info "Preventing database auto-start..."
    ./prevent-db-autostart.sh
    
    log_info "Installing shell plugins..."
    ./install-shell-plugins.sh
    
    log_info "Installing Spaceship theme..."
    ./install-spaceship-zsh-theme.sh
    
    # Must run before configure-git-user.sh: it records GIT_SIGNING_KEY in
    # .env-install, which is what turns on commit signing in the gitconfig.
    log_info "Importing GPG signing key..."
    ./setup-gpg-key.sh --import ||
        log_warn "No GPG key imported; commit signing will be skipped"

    log_info "Configuring Git..."
    ./configure-git-user.sh
    
    log_info "Deploying dotfiles..."
    ./deploy-dotfiles.sh

    # rtk is installed from brew/Brewfile by install-brew-packages.sh above.

    # Global scope only. Project-scoped skills are installed per repository
    # with `sync-agent-skills.sh --project`, never by machine setup.
    log_info "Syncing global agent skills..."
    ./sync-agent-skills.sh --global

    # Runs after deploy-dotfiles.sh: the installer detects installed agents and
    # writes their MCP configuration, so the agent config files must exist first.
    log_info "Installing codebase-memory-mcp..."
    ./setup-codebase-memory.sh ||
        log_warn "codebase-memory-mcp setup failed; install it manually later"

    # Claude Code MCP servers live in ~/.claude.json, which is not tracked
    # here because it also holds account identifiers and caches.
    log_info "Registering MCP servers with Claude Code..."
    ./setup-mcp-servers.sh ||
        log_warn "MCP server registration failed; run setup-mcp-servers.sh later"

    # cliproxyapi serves the local API that .claudex/settings.json points at
    # (ANTHROPIC_BASE_URL=http://127.0.0.1:8317). Started here rather than left
    # manual so claudex works after a reboot without intervention.
    #
    # Runs after deploy-dotfiles.sh, which seeds ~/.config/cliproxyapi/config.yaml,
    # and after the restore, which replaces that seed with the real config and
    # the provider OAuth logins in ~/.cli-proxy-api.
    if command_exists brew; then
        log_info "Starting cliproxyapi service..."
        brew services start cliproxyapi ||
            log_warn "Could not start cliproxyapi; start it with: brew services start cliproxyapi"
    fi

    # Runs after install-brew-packages.sh, which provides duti and the
    # QLMarkdown cask that this script configures.
    log_info "Configuring file associations..."
    ./configure-file-associations.sh ||
        log_warn "File association setup failed; run configure-file-associations.sh later"

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
