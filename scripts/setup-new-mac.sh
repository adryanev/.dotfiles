#!/bin/bash

echo "Setting up your Mac..."

# Check for sudo access and cache credentials
echo "Checking for sudo access..."
if ! sudo -v; then
    echo "Error: This script requires sudo access"
    exit 1
fi

# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Load environment variables
ENV_FILE="$(pwd)/env/.env-install"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "Error: .env-install file not found at $ENV_FILE"
    exit 1
fi

# Check if Xcode Command Line Tools are installed
if ! xcode-select -p &>/dev/null; then
  echo "Xcode Command Line Tools not found. Installing..."
  xcode-select --install
  # Accept Xcode license
  echo "Accepting Xcode license..."
  sudo -n xcodebuild -license accept

  # Install Rosetta 2 for Apple Silicon Macs
  if [[ $(uname -m) == 'arm64' ]]; then
    echo "Installing Rosetta 2..."
    sudo -n softwareupdate --install-rosetta --agree-to-license
    echo "Rosetta 2 installed."
  fi

else
  echo "Xcode Command Line Tools already installed."
fi

# Manual Oh My Zsh installation
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh manually..."
  git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  echo "Oh My Zsh has been installed manually."
else
  echo "Oh My Zsh is already installed."
fi

# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Make sure we're in the scripts directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Setup SSH
./setup-ssh-keys.sh "$SSH_EMAIL"

# Install Homebrew packages
echo "Installing Homebrew packages..."
./install-brew-packages.sh

# Prevent MySQL and PostgreSQL from auto-starting
echo "Configuring MySQL and PostgreSQL to not auto-start..."
./prevent-db-autostart.sh

# Install CLI tools and plugins
echo "Installing CLI tools and plugins..."
./install-shell-plugins.sh

# Install Spaceship Prompt
echo "Installing Spaceship Prompt..."
./install-spaceship-zsh-theme.sh

# Configure Git user settings before stowing
echo "Configuring Git user settings..."
./configure-git-user.sh

# Create symlinks using Stow
echo "Creating symlinks for dotfiles..."
cd "$SCRIPT_DIR"
./deploy-dotfiles.sh
cd ..

# Create projects directory
mkdir -p $HOME/Code

# Install Node.js and Flutter
echo "Setting up Node.js and Flutter environments..."
cd "$SCRIPT_DIR"
./setup-dev-environments.sh
cd ..

# Apply macOS settings
echo "Applying macOS settings..."
source ../macos/.macos

echo "Setup complete! Please restart your terminal for all changes to take effect."
