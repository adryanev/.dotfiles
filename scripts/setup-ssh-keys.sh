#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

log_info "Setting up SSH keys..."

# Check for email argument
SSH_EMAIL="${1:-}"

if [ -z "$SSH_EMAIL" ]; then
    log_error "Please provide an email address for SSH key generation."
    echo "Usage: $0 <email_address>"
    exit 1
fi

# SSH configuration
SSH_DIR="$HOME/.ssh"
SSH_KEY="${SSH_DIR}/id_ed25519"
SSH_KEY_RSA="${SSH_DIR}/id_rsa"
SSH_CONFIG="${SSH_DIR}/config"

# Create .ssh directory if it doesn't exist
ensure_directory "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Check if SSH key already exists
if [ -f "$SSH_KEY" ]; then
    log_warn "SSH key already exists at $SSH_KEY"
    read -p "Do you want to overwrite it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Keeping existing key"
    else
        # Generate a new SSH key
        log_info "Generating a new ED25519 SSH key for $SSH_EMAIL"
        ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$SSH_KEY" || {
            log_error "Failed to generate SSH key"
            exit 1
        }
        log_info "SSH key generated successfully."
    fi
else
    # Generate a new SSH key
    log_info "Generating a new ED25519 SSH key for $SSH_EMAIL"
    ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$SSH_KEY" || {
        log_error "Failed to generate SSH key"
        exit 1
    }
    log_info "SSH key generated successfully."
fi

# Also generate RSA key for compatibility if it doesn't exist
if [ ! -f "$SSH_KEY_RSA" ]; then
    log_info "Generating RSA SSH key for compatibility..."
    ssh-keygen -t rsa -b 4096 -C "$SSH_EMAIL" -f "$SSH_KEY_RSA" -N "" || {
        log_warn "Failed to generate RSA key for compatibility"
    }
fi

# Start ssh-agent and add keys
eval "$(ssh-agent -s)" || log_warn "Could not start ssh-agent"

# Create or update SSH config file
log_info "Configuring SSH..."
cat > "$SSH_CONFIG" << EOF
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile $SSH_KEY
    IdentityFile $SSH_KEY_RSA
EOF
chmod 600 "$SSH_CONFIG"
log_info "SSH config updated."

# Add SSH keys to the ssh-agent
if [ -f "$SSH_KEY" ]; then
    ssh-add --apple-use-keychain "$SSH_KEY" 2>/dev/null || ssh-add "$SSH_KEY" || log_warn "Could not add ED25519 key"
fi
if [ -f "$SSH_KEY_RSA" ]; then
    ssh-add --apple-use-keychain "$SSH_KEY_RSA" 2>/dev/null || ssh-add "$SSH_KEY_RSA" || log_warn "Could not add RSA key"
fi

# Display the public key
if [ -f "${SSH_KEY}.pub" ]; then
    echo ""
    log_info "Your SSH public key (ED25519):"
    cat "${SSH_KEY}.pub"
    echo ""
    log_info "To copy to clipboard: pbcopy < ${SSH_KEY}.pub"
    log_info "Please add this public key to your GitHub/GitLab account."
fi

log_info "SSH setup complete!"