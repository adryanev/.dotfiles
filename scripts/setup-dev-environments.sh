#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Configuration - make versions configurable
NODE_VERSIONS="${NODE_VERSIONS:-22 20}"
NODE_DEFAULT="${NODE_DEFAULT:-22}"
JAVA_VERSIONS="${JAVA_VERSIONS:-17 21}"
JAVA_DEFAULT="${JAVA_DEFAULT:-21}"
PHP_VERSION="${PHP_VERSION:-8.3}"
GO_VERSION="${GO_VERSION:-1.24}"
RUBY_VERSION="${RUBY_VERSION:-3.3}"
FLUTTER_VERSION="${FLUTTER_VERSION:-3}"
POSTGRES_VERSION="${POSTGRES_VERSION:-17}"

log_info "Setting up development environments..."

# Install latest Xcode using xcodes if available
install_xcode() {
    if command_exists xcodes; then
        log_info "Installing latest Xcode..."
        log_info "Checking for latest Xcode version..."
        xcodes list || log_warn "Failed to list Xcode versions"

        log_info "Installing latest Xcode (this may take a while)..."
        xcodes install --latest --select --experimental-unxip || {
            log_warn "Failed to install Xcode automatically"
            return 1
        }

        ensure_directory "$HOME/.oh-my-zsh/completions"
        xcodes --generate-completion-script > "$HOME/.oh-my-zsh/completions/_xcodes" || {
            log_warn "Failed to generate xcodes completion"
        }
    else
        log_warn "xcodes CLI not available. Skipping Xcode installation."
    fi
}

# Setup asdf plugins and install versions
setup_asdf() {
    if ! command_exists asdf; then
        log_error "asdf is not available. Please install asdf first."
        log_info "You can install asdf from: https://asdf-vm.com/guide/getting-started.html"
        exit 1
    fi

    log_info "Setting up development environments with asdf..."

    # Define plugins to add
    local plugins=(
        "nodejs"
        "bun"
        "java"
        "php"
        "golang"
        "ruby"
        "flutter"
        "postgres"
        "pnpm"
    )

    # Add all plugins
    for plugin in "${plugins[@]}"; do
        log_info "Adding $plugin plugin..."
        asdf plugin add "$plugin" 2>/dev/null || log_info "$plugin plugin already exists"
    done

    # Install Node.js versions
    for version in $NODE_VERSIONS; do
        log_info "Installing Node.js $version..."
        retry_command asdf install nodejs "latest:$version" || log_warn "Failed to install Node.js $version"
    done

    # Set Node.js default
    log_info "Setting Node.js $NODE_DEFAULT as global default..."
    asdf global nodejs "latest:$NODE_DEFAULT" || log_warn "Failed to set Node.js default"

    # Install pnpm latest version
    log_info "Installing pnpm latest version..."
    asdf install pnpm latest || log_warn "Failed to install pnpm"
    asdf global pnpm latest || log_warn "Failed to set pnpm default"

    # Install Bun latest version
    log_info "Installing Bun latest version..."
    asdf install bun latest || log_warn "Failed to install Bun"
    asdf global bun latest || log_warn "Failed to set Bun default"

    # Install Java versions
    for version in $JAVA_VERSIONS; do
        log_info "Installing Java $version..."
        asdf install java "latest:openjdk-$version" || log_warn "Failed to install Java $version"
    done

    # Set Java default
    log_info "Setting Java $JAVA_DEFAULT as global default..."
    asdf global java "latest:openjdk-$JAVA_DEFAULT" || log_warn "Failed to set Java default"

    # Install PHP (asdf-php automatically installs Composer)
    log_info "Installing PHP $PHP_VERSION (includes Composer)..."
    asdf install php "latest:$PHP_VERSION" || log_warn "Failed to install PHP"
    asdf global php "latest:$PHP_VERSION" || log_warn "Failed to set PHP default"

    # Install Go
    log_info "Installing Go $GO_VERSION..."
    asdf install golang "latest:$GO_VERSION" || log_warn "Failed to install Go"
    asdf global golang "latest:$GO_VERSION" || log_warn "Failed to set Go default"

    # Install Ruby
    log_info "Installing Ruby $RUBY_VERSION..."
    asdf install ruby "latest:$RUBY_VERSION" || log_warn "Failed to install Ruby"
    asdf global ruby "latest:$RUBY_VERSION" || log_warn "Failed to set Ruby default"

    # Install Flutter
    log_info "Installing Flutter $FLUTTER_VERSION..."
    asdf install flutter "latest:$FLUTTER_VERSION" || log_warn "Failed to install Flutter"
    asdf global flutter "latest:$FLUTTER_VERSION" || log_warn "Failed to set Flutter default"

    # Install PostgreSQL
    log_info "Installing PostgreSQL $POSTGRES_VERSION..."
    asdf install postgres "latest:$POSTGRES_VERSION" || log_warn "Failed to install PostgreSQL"
    asdf global postgres "latest:$POSTGRES_VERSION" || log_warn "Failed to set PostgreSQL default"

    # Refresh asdf shims
    log_info "Refreshing asdf shims..."
    asdf reshim || log_warn "Failed to refresh shims"

    log_info "asdf setup complete!"
    log_info "Installed versions:"
    for plugin in "${plugins[@]}"; do
        asdf list "$plugin" 2>/dev/null || true
    done
}

# Main execution
main() {
    install_xcode
    setup_asdf

    log_info "Development environment setup complete!"
    log_info "Note: You may need to restart your terminal or source your shell profile to use the installed tools."
}

# Run main function
main "$@"