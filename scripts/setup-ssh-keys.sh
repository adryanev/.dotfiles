#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

log_info "Setting up SSH keys..."

# Check for email argument (only required when generating a new key)
SSH_EMAIL="${1:-}"

# SSH configuration
SSH_DIR="$HOME/.ssh"
SSH_KEY="${SSH_DIR}/id_ed25519"

# Private keys are NOT stored in this repository. They come from the encrypted
# iCloud backup, restored by post-reinstall-restore.sh, which setup-new-mac.sh
# runs before this script.
#
# This script deliberately does NOT write ~/.ssh/config. That file is deployed
# from ssh/config by deploy-dotfiles.sh, and after deployment it is a symlink
# into this repository. An earlier version of this script generated the config
# with a shell redirect, which followed that symlink and overwrote the tracked
# file with a stub. Do not reintroduce that.

# Private keys found in ~/.ssh, added to the agent below.
IDENTITY_FILES=()

ensure_directory "$SSH_DIR"
chmod 700 "$SSH_DIR"

is_private_key() {
    grep -q "PRIVATE KEY" "$1" 2>/dev/null
}

# Collect every private key already present in ~/.ssh.
collect_existing_keys() {
    local f name
    for f in "$SSH_DIR"/*; do
        [ -f "$f" ] || continue
        name="$(basename "$f")"

        case "$name" in
            *.pub | config | config.* | known_hosts* | *.backup.* | *.old) continue ;;
        esac

        if is_private_key "$f"; then
            IDENTITY_FILES+=("$f")
        fi
    done

    [ "${#IDENTITY_FILES[@]}" -gt 0 ]
}

generate_new_key() {
    if [ -z "$SSH_EMAIL" ]; then
        log_error "No SSH keys in $SSH_DIR and no email address given."
        log_info "Restore the encrypted backup first:"
        log_info "  ./post-reinstall-restore.sh"
        log_info "Or generate a new key:"
        log_info "  $0 <email_address>"
        exit 1
    fi

    log_info "Generating a new ED25519 SSH key for $SSH_EMAIL"
    ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$SSH_KEY" || {
        log_error "Failed to generate SSH key"
        exit 1
    }
    log_info "SSH key generated successfully."
    IDENTITY_FILES+=("$SSH_KEY")
}

# Use whatever the restore put in place; generate only when there is nothing.
if collect_existing_keys; then
    log_info "Found ${#IDENTITY_FILES[@]} existing private key(s) in $SSH_DIR"
else
    log_warn "No SSH keys found in $SSH_DIR"
    generate_new_key
fi

# Correct permissions without touching config or known_hosts.
find "$SSH_DIR" -maxdepth 1 -type f ! -name '*.pub' ! -name 'config' \
    ! -name 'known_hosts*' -exec chmod 600 {} \;
find "$SSH_DIR" -maxdepth 1 -type f -name '*.pub' -exec chmod 644 {} \;

# Start ssh-agent and add keys
eval "$(ssh-agent -s)" || log_warn "Could not start ssh-agent"

for key in "${IDENTITY_FILES[@]}"; do
    ssh-add --apple-use-keychain "$key" 2>/dev/null ||
        ssh-add "$key" ||
        log_warn "Could not add $(basename "$key")"
done

# Display the public keys
for key in "${IDENTITY_FILES[@]}"; do
    if [ -f "${key}.pub" ]; then
        echo ""
        log_info "Public key ($(basename "$key")):"
        cat "${key}.pub"
    fi
done
echo ""
log_info "Add these public keys to your GitHub/GitLab account if they are new."

log_info "SSH setup complete!"
