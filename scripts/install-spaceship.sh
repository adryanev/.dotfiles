#!/bin/bash

# Install Spaceship Prompt for Oh My Zsh
echo "Installing Spaceship Prompt..."

# Define ZSH_CUSTOM if not set
if [ -z "$ZSH_CUSTOM" ]; then
  ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
fi

# Clone the repository
if [ ! -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]; then
  git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1

  # Create symlink
  ln -sf "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

  echo "Spaceship Prompt has been installed successfully."
else
  echo "Spaceship Prompt is already installed."
fi

# Reminder to update .zshrc
echo "Remember to set ZSH_THEME=\"spaceship\" in your .zshrc"