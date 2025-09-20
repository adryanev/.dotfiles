#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

log_info "Installing shell environment plugins..."

# Check for Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log_error "Oh My Zsh is not installed. Please install Oh My Zsh first."
    exit 1
fi

# Install Tmux Plugin Manager
install_tmux_plugins() {
    log_info "Installing Tmux Plugin Manager..."

    local TPM_DIR="$HOME/.config/tmux/plugins/tpm"
    if [ -d "$TPM_DIR" ]; then
        log_info "TPM already installed, updating..."
        (
            cd "$TPM_DIR" || exit 1
            git pull origin master || log_warn "Failed to update TPM"
        )
    else
        ensure_directory "$(dirname "$TPM_DIR")"
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR" || {
            log_error "Failed to clone TPM"
            return 1
        }
    fi

    log_info "TPM installed/updated successfully"
    log_info "Press prefix + I in tmux to install plugins"
}

# Install Zsh plugins
install_zsh_plugins() {
    log_info "Installing Zsh plugins..."

    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    local PLUGINS_DIR="${ZSH_CUSTOM}/plugins"

    ensure_directory "$PLUGINS_DIR"

    # Define plugins to install
    declare -A plugins=(
        ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
        ["fast-syntax-highlighting"]="https://github.com/zdharma-continuum/fast-syntax-highlighting"
        ["zsh-autocomplete"]="https://github.com/marlonrichert/zsh-autocomplete"
    )

    # Install each plugin
    for plugin_name in "${!plugins[@]}"; do
        local plugin_url="${plugins[$plugin_name]}"
        local plugin_dir="${PLUGINS_DIR}/${plugin_name}"

        if [ -d "$plugin_dir" ]; then
            log_info "Plugin $plugin_name already installed, updating..."
            (
                cd "$plugin_dir" || exit 1
                git pull origin master || log_warn "Failed to update $plugin_name"
            )
        else
            log_info "Installing $plugin_name..."
            git clone "$plugin_url" "$plugin_dir" || {
                log_warn "Failed to install $plugin_name"
                continue
            }
        fi
    done

    log_info "Zsh plugins installed/updated successfully"
}

# Install fzf key bindings and completion
install_fzf_integration() {
    if ! command_exists fzf; then
        log_warn "fzf is not installed, skipping integration"
        return
    fi

    log_info "Installing fzf shell integration..."

    # Install fzf shell integration
    local FZF_BASE="$(brew --prefix)/opt/fzf"
    if [ -d "$FZF_BASE" ]; then
        yes | "$FZF_BASE/install" --key-bindings --completion --no-update-rc 2>/dev/null || {
            log_warn "Failed to install fzf integration automatically"
        }
        log_info "fzf shell integration installed"
    else
        log_warn "fzf directory not found at expected location"
    fi
}

# Install thefuck integration
install_thefuck_integration() {
    if ! command_exists thefuck; then
        log_warn "thefuck is not installed, skipping integration"
        return
    fi

    log_info "Configuring thefuck..."

    # The eval command is already in .zshrc_sourced/.eval
    log_info "thefuck configuration complete (loaded from .zshrc_sourced/.eval)"
}

# Main execution
main() {
    install_tmux_plugins
    install_zsh_plugins
    install_fzf_integration
    install_thefuck_integration

    log_info "Shell plugin installation complete!"
    log_info "Note: Restart your terminal or reload your shell configuration to use the new plugins"
}

# Run main function
main "$@"