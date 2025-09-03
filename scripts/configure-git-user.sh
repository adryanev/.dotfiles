#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

log_info "Configuring Git user settings..."

# Load environment variables
ENV_FILE="${SCRIPT_DIR}/../env/.env-install"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    log_error ".env-install file not found at $ENV_FILE"
    exit 1
fi

# Validate required environment variables
if [ -z "${GIT_USER_NAME:-}" ]; then
    log_error "GIT_USER_NAME not set in .env-install"
    exit 1
fi

if [ -z "${GIT_USER_EMAIL:-}" ]; then
    log_error "GIT_USER_EMAIL not set in .env-install"
    exit 1
fi

# Git configuration path
GIT_CONFIG_PATH="${SCRIPT_DIR}/../git/.gitconfig"
GIT_CONFIG_BACKUP="${GIT_CONFIG_PATH}.backup.$(date +%Y%m%d_%H%M%S)"

# Backup existing .gitconfig if it exists
if [ -f "$GIT_CONFIG_PATH" ]; then
    log_info "Backing up existing .gitconfig to $GIT_CONFIG_BACKUP"
    cp "$GIT_CONFIG_PATH" "$GIT_CONFIG_BACKUP" || {
        log_error "Failed to backup .gitconfig"
        exit 1
    }
fi

# Create .gitconfig with user settings
log_info "Creating .gitconfig with user settings..."

# Start with basic config
cat > "$GIT_CONFIG_PATH" << EOF
[user]
    name = ${GIT_USER_NAME}
    email = ${GIT_USER_EMAIL}
EOF

# Add GPG signing configuration if signing key is provided
if [ -n "${GIT_SIGNING_KEY:-}" ]; then
    log_info "Configuring GPG signing with key: ${GIT_SIGNING_KEY}"
    cat >> "$GIT_CONFIG_PATH" << EOF
    signingkey = ${GIT_SIGNING_KEY}

[commit]
    gpgsign = true

[tag]
    gpgsign = true
EOF
else
    log_warn "No GIT_SIGNING_KEY provided, skipping GPG configuration"
fi

# Add common Git configurations
cat >> "$GIT_CONFIG_PATH" << 'EOF'

[init]
    defaultBranch = main

[core]
    excludesfile = ~/.gitignore_global
    editor = nvim
    autocrlf = input

[pull]
    rebase = true

[push]
    default = current
    autoSetupRemote = true

[fetch]
    prune = true

[diff]
    colorMoved = zebra

[merge]
    conflictstyle = diff3

[rebase]
    autoStash = true

[filter "lfs"]
    clean = git-lfs clean -- %f
    smudge = git-lfs smudge -- %f
    process = git-lfs filter-process
    required = true

[alias]
    co = checkout
    br = branch
    ci = commit
    st = status
    unstage = reset HEAD --
    last = log -1 HEAD
    lg = log --oneline --decorate --graph --all
EOF

log_info "Git configuration complete!"

# Verify the configuration
log_info "Current Git configuration:"
git config --file="$GIT_CONFIG_PATH" --list | head -5 || log_warn "Could not verify Git configuration"

# Create symlink to home directory
GITCONFIG_HOME="$HOME/.gitconfig"
if [ -f "$GITCONFIG_HOME" ] && [ ! -L "$GITCONFIG_HOME" ]; then
    log_warn "Existing .gitconfig found at $GITCONFIG_HOME"
    log_info "Creating backup at ${GITCONFIG_HOME}.backup"
    mv "$GITCONFIG_HOME" "${GITCONFIG_HOME}.backup"
fi

log_info "Creating symlink for .gitconfig..."
safe_symlink "$GIT_CONFIG_PATH" "$GITCONFIG_HOME"

log_info "Git user configuration complete!"