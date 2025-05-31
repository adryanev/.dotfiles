#!/bin/bash

# Install pnpm using script
curl -fsSL https://get.pnpm.io/install.sh | sh -

export PNPM_HOME="/Users/adryanev/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

mkdir -p "$HOME/.nvm"

export NVM_DIR="$HOME/.nvm"
    [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" # This loads nvm
    [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion


# Install latest Xcode using xcodes
echo "Installing latest Xcode..."
if command -v xcodes &> /dev/null; then
    echo "Checking for latest Xcode version..."
    xcodes list
    echo "Installing latest Xcode (this may take a while)..."
    xcodes install --latest --select --experimental-unxip

    mkdir -p ~/.oh-my-zsh/completions
    xcodes --generate-completion-script > ~/.oh-my-zsh/completions/_xcodes

else
    echo "Error: xcodes CLI not available. Skipping Xcode installation."
fi

# Ensure Flutter SDK PATH is available
export PATH="$PATH:$HOME/fvm/default/bin"

# Check if FVM is properly loaded
if command -v fvm &> /dev/null; then
  # Install stable version of Flutter via FVM
  echo "Installing stable Flutter version..."
  fvm install stable
  fvm global stable
else
  echo "Error: FVM could not be loaded. Please check if dart and pub are properly installed."
  echo "You may need to add '$HOME/.pub-cache/bin' to your PATH manually."
fi

echo "Node.js, Xcode, and Flutter setup complete!"
echo "Note: You may need to restart your terminal or source your shell profile to use the installed tools."
