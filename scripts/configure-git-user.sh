#!/bin/bash

echo "Configuring Git settings..."

# Check if environment variables are set
if [ -z "$GIT_USER_NAME" ] || [ -z "$GIT_USER_EMAIL" ]; then
    echo "Error: GIT_USER_NAME and GIT_USER_EMAIL must be set in .env-install"
    exit 1
fi

# Backup existing Git config if it exists
if [ -f "$HOME/.gitconfig" ]; then
    echo "Existing .gitconfig found, backing up to .gitconfig.bak"
    mv "$HOME/.gitconfig" "$HOME/.gitconfig.bak"
fi

# Get the dotfiles root directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Copy the template .gitconfig to the home directory
echo "Copying .gitconfig template..."
cp "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

# Update user-specific Git settings in the copied file
echo "Setting user-specific Git configuration..."
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

# Configure Git signing if signing key is provided
if [ -n "$GIT_SIGNING_KEY" ]; then
    echo "Configuring Git commit signing..."
    git config --global commit.gpgsign true
    git config --global user.signingkey "$GIT_SIGNING_KEY"
    gpgconf --kill gpg-agent
fi

echo "Git configuration complete!"