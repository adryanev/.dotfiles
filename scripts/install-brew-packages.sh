#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

log_info "Installing Homebrew packages..."

# Check if Homebrew is installed
if ! command_exists brew; then
    log_error "Homebrew is not installed. Please install Homebrew first."
    exit 1
fi

# Update Homebrew
log_info "Updating Homebrew..."
brew update || {
    log_warn "Failed to update Homebrew, continuing anyway"
}

# Install packages from Brewfile
BREWFILE="${SCRIPT_DIR}/../brew/Brewfile"
if [ -f "$BREWFILE" ]; then
    log_info "Installing packages from Brewfile..."
    brew bundle --file="$BREWFILE" || {
        log_error "Failed to install packages from Brewfile"
        exit 1
    }
    log_info "Homebrew packages installed successfully."
else
    log_error "Brewfile not found at $BREWFILE"
    exit 1
fi

# Cleanup
log_info "Cleaning up Homebrew..."
brew cleanup || log_warn "Cleanup failed, but continuing"

log_info "Homebrew package installation complete!"