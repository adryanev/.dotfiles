#!/bin/bash


#Install pnpm using script
curl -fsSL https://get.pnpm.io/install.sh | sh -


export PNPM_HOME="/Users/adryanev/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac


# install node using pnpm env
pnpm env use --global lts

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

echo "Node.js and Flutter setup complete!"
echo "Note: You may need to restart your terminal or source your shell profile to use the installed tools."
