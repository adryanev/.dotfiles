#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

log_info "GPG Key Setup and Management"

# Configuration
GNUPG_DIR="${SCRIPT_DIR}/../gnupg"
ENV_FILE="${SCRIPT_DIR}/../env/.env-install"
GPG_KEY_FILE="${GNUPG_DIR}/signing-key.asc"
PUBLIC_KEY_FILE="${GNUPG_DIR}/public-key.asc"

# Ensure gnupg directory exists
ensure_directory "$GNUPG_DIR"
chmod 700 "$GNUPG_DIR"

# Function to display menu
show_menu() {
    echo ""
    echo "GPG Key Management Options:"
    echo "1) Generate new GPG key"
    echo "2) Import existing GPG key from file"
    echo "3) Import GPG key from clipboard"
    echo "4) Export current GPG key to gnupg folder"
    echo "5) List existing GPG keys"
    echo "6) Configure Git to use GPG key"
    echo "7) Test GPG signing"
    echo "8) Remove GPG configuration"
    echo "q) Quit"
    echo ""
    read -p "Choose an option: " choice
}

# Function to generate new GPG key
generate_new_key() {
    log_info "Generating new GPG key..."
    
    # Get user information
    read -p "Enter your full name: " REAL_NAME
    read -p "Enter your email address: " EMAIL
    read -p "Enter key expiration (0 for no expiration, or specify like '2y' for 2 years): " EXPIRATION
    
    EXPIRATION="${EXPIRATION:-0}"
    
    # Generate GPG key
    log_info "Generating GPG key for $REAL_NAME <$EMAIL>..."
    
    gpg --batch --generate-key <<EOF
%echo Generating GPG key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $REAL_NAME
Name-Email: $EMAIL
Expire-Date: $EXPIRATION
%no-protection
%commit
%echo done
EOF

    if [ $? -eq 0 ]; then
        log_info "GPG key generated successfully!"
        
        # Get the key ID
        KEY_ID=$(gpg --list-secret-keys --keyid-format=long "$EMAIL" 2>/dev/null | grep sec | awk '{print $2}' | cut -d'/' -f2)
        
        if [ -n "$KEY_ID" ]; then
            log_info "Your GPG key ID is: $KEY_ID"
            
            # Export the key
            export_key_to_folder "$KEY_ID"
            
            # Update .env-install
            update_env_file "$KEY_ID"
        else
            log_error "Could not determine key ID"
        fi
    else
        log_error "Failed to generate GPG key"
        return 1
    fi
}

# Function to import key from file
import_key_from_file() {
    read -p "Enter the path to your GPG key file: " KEY_PATH
    
    if [ ! -f "$KEY_PATH" ]; then
        log_error "File not found: $KEY_PATH"
        return 1
    fi
    
    log_info "Importing GPG key from $KEY_PATH..."
    gpg --import "$KEY_PATH" || {
        log_error "Failed to import GPG key"
        return 1
    }
    
    # Copy to gnupg folder
    cp "$KEY_PATH" "$GPG_KEY_FILE"
    chmod 600 "$GPG_KEY_FILE"
    
    log_info "GPG key imported successfully!"
    list_keys
}

# Function to import key from clipboard
import_key_from_clipboard() {
    log_info "Importing GPG key from clipboard..."
    
    # Create temporary file
    TEMP_KEY="/tmp/gpg-import-$$.asc"
    pbpaste > "$TEMP_KEY"
    
    if [ ! -s "$TEMP_KEY" ]; then
        log_error "Clipboard is empty or doesn't contain valid data"
        rm -f "$TEMP_KEY"
        return 1
    fi
    
    # Check if it looks like a GPG key
    if ! grep -q "BEGIN PGP" "$TEMP_KEY"; then
        log_error "Clipboard doesn't contain a valid GPG key"
        rm -f "$TEMP_KEY"
        return 1
    fi
    
    gpg --import "$TEMP_KEY" || {
        log_error "Failed to import GPG key"
        rm -f "$TEMP_KEY"
        return 1
    }
    
    # Copy to gnupg folder
    cp "$TEMP_KEY" "$GPG_KEY_FILE"
    chmod 600 "$GPG_KEY_FILE"
    
    rm -f "$TEMP_KEY"
    log_info "GPG key imported successfully from clipboard!"
    list_keys
}

# Function to export key to gnupg folder
export_key_to_folder() {
    local KEY_ID="${1:-}"
    
    if [ -z "$KEY_ID" ]; then
        log_info "Available keys:"
        gpg --list-secret-keys --keyid-format=long
        read -p "Enter the key ID to export: " KEY_ID
    fi
    
    if [ -z "$KEY_ID" ]; then
        log_error "No key ID provided"
        return 1
    fi
    
    log_info "Exporting private key to $GPG_KEY_FILE..."
    gpg --armor --export-secret-keys "$KEY_ID" > "$GPG_KEY_FILE" || {
        log_error "Failed to export private key"
        return 1
    }
    chmod 600 "$GPG_KEY_FILE"
    
    log_info "Exporting public key to $PUBLIC_KEY_FILE..."
    gpg --armor --export "$KEY_ID" > "$PUBLIC_KEY_FILE" || {
        log_error "Failed to export public key"
        return 1
    }
    chmod 644 "$PUBLIC_KEY_FILE"
    
    log_info "Keys exported successfully to gnupg folder!"
    log_warn "Remember: These files are gitignored and won't be committed"
    log_info "Private key: $GPG_KEY_FILE"
    log_info "Public key: $PUBLIC_KEY_FILE"
}

# Function to list GPG keys
list_keys() {
    log_info "Listing GPG keys..."
    echo ""
    echo "Secret keys:"
    gpg --list-secret-keys --keyid-format=long
    echo ""
    echo "Public keys:"
    gpg --list-keys --keyid-format=long
}

# Function to update .env-install file
update_env_file() {
    local KEY_ID="$1"
    
    if [ -f "$ENV_FILE" ]; then
        # Check if GIT_SIGNING_KEY already exists
        if grep -q "^GIT_SIGNING_KEY=" "$ENV_FILE"; then
            # Update existing key
            sed -i.bak "s/^GIT_SIGNING_KEY=.*/GIT_SIGNING_KEY=$KEY_ID/" "$ENV_FILE"
            log_info "Updated GIT_SIGNING_KEY in .env-install"
        else
            # Add new key
            echo "GIT_SIGNING_KEY=$KEY_ID" >> "$ENV_FILE"
            log_info "Added GIT_SIGNING_KEY to .env-install"
        fi
    else
        log_warn ".env-install file not found. Please add manually:"
        log_info "GIT_SIGNING_KEY=$KEY_ID"
    fi
}

# Function to configure Git with GPG
configure_git() {
    log_info "Configuring Git to use GPG signing..."
    
    # Get key ID
    log_info "Available keys:"
    gpg --list-secret-keys --keyid-format=long
    read -p "Enter the key ID to use for signing: " KEY_ID
    
    if [ -z "$KEY_ID" ]; then
        log_error "No key ID provided"
        return 1
    fi
    
    # Configure Git
    git config --global user.signingkey "$KEY_ID" || {
        log_error "Failed to set Git signing key"
        return 1
    }
    
    git config --global commit.gpgsign true || {
        log_error "Failed to enable commit signing"
        return 1
    }
    
    git config --global tag.gpgsign true || {
        log_error "Failed to enable tag signing"
        return 1
    }
    
    # Update .env-install
    update_env_file "$KEY_ID"
    
    log_info "Git configured to use GPG key: $KEY_ID"
    log_info "All future commits and tags will be signed"
}

# Function to test GPG signing
test_signing() {
    log_info "Testing GPG signing..."
    
    # Create a test file
    TEST_FILE="/tmp/gpg-test-$$.txt"
    echo "This is a test file for GPG signing" > "$TEST_FILE"
    
    # Get key to use
    log_info "Available keys:"
    gpg --list-secret-keys --keyid-format=long
    read -p "Enter the key ID to test (or press Enter for default): " KEY_ID
    
    if [ -n "$KEY_ID" ]; then
        GPG_OPTS="--local-user $KEY_ID"
    else
        GPG_OPTS=""
    fi
    
    # Sign the file
    log_info "Signing test file..."
    gpg --armor --detach-sign $GPG_OPTS "$TEST_FILE" || {
        log_error "Failed to sign test file"
        rm -f "$TEST_FILE"
        return 1
    }
    
    # Verify the signature
    log_info "Verifying signature..."
    gpg --verify "${TEST_FILE}.asc" "$TEST_FILE" || {
        log_error "Failed to verify signature"
        rm -f "$TEST_FILE" "${TEST_FILE}.asc"
        return 1
    }
    
    rm -f "$TEST_FILE" "${TEST_FILE}.asc"
    log_info "GPG signing test successful!"
    
    # Test Git commit signing
    read -p "Do you want to test Git commit signing? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        test_git_signing
    fi
}

# Function to test Git signing
test_git_signing() {
    log_info "Testing Git commit signing..."
    
    # Create temporary repo
    TEMP_REPO="/tmp/gpg-git-test-$$"
    mkdir -p "$TEMP_REPO"
    cd "$TEMP_REPO" || return 1
    
    git init
    echo "test" > test.txt
    git add test.txt
    
    log_info "Creating signed commit..."
    git commit -S -m "Test signed commit" || {
        log_error "Failed to create signed commit"
        cd - > /dev/null
        rm -rf "$TEMP_REPO"
        return 1
    }
    
    log_info "Verifying commit signature..."
    git verify-commit HEAD || {
        log_error "Failed to verify commit signature"
        cd - > /dev/null
        rm -rf "$TEMP_REPO"
        return 1
    }
    
    cd - > /dev/null
    rm -rf "$TEMP_REPO"
    
    log_info "Git commit signing test successful!"
}

# Function to remove GPG configuration
remove_configuration() {
    log_warn "This will remove GPG configuration from Git"
    read -p "Are you sure? (y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cancelled"
        return
    fi
    
    git config --global --unset user.signingkey 2>/dev/null
    git config --global --unset commit.gpgsign 2>/dev/null
    git config --global --unset tag.gpgsign 2>/dev/null
    
    if [ -f "$ENV_FILE" ]; then
        sed -i.bak '/^GIT_SIGNING_KEY=/d' "$ENV_FILE"
    fi
    
    log_info "GPG configuration removed from Git"
    log_warn "GPG keys are still in your keyring. Use 'gpg --delete-secret-key' to remove them"
}

# Main execution
main() {
    # Check if gpg is installed
    if ! command_exists gpg; then
        log_error "GPG is not installed. Please install it first:"
        log_info "brew install gnupg"
        exit 1
    fi
    
    # Ensure GPG home directory is set correctly
    export GNUPGHOME="${HOME}/.gnupg"
    ensure_directory "$GNUPGHOME"
    chmod 700 "$GNUPGHOME"
    
    # Main loop
    while true; do
        show_menu
        
        case $choice in
            1)
                generate_new_key
                ;;
            2)
                import_key_from_file
                ;;
            3)
                import_key_from_clipboard
                ;;
            4)
                export_key_to_folder
                ;;
            5)
                list_keys
                ;;
            6)
                configure_git
                ;;
            7)
                test_signing
                ;;
            8)
                remove_configuration
                ;;
            q|Q)
                log_info "Exiting..."
                break
                ;;
            *)
                log_error "Invalid option"
                ;;
        esac
    done
}

# Run main function
main "$@"