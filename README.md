# Dotfiles

Personal dotfiles repository by Adryan Eka Vandra for macOS setup. This repository contains configuration files and scripts to set up a new macOS machine with my preferred development environment.

![Screenshot of configured environment](assets/SCR-20250504-lmgr.png)

## Table of Contents

- [Dotfiles](#dotfiles)
  - [Table of Contents](#table-of-contents)
  - [Contents](#contents)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Customization](#customization)
  - [Structure](#structure)
  - [Scripts](#scripts)
  - [Maintenance](#maintenance)
  - [Recent Improvements](#recent-improvements)
  - [License](#license)

## Contents

- Shell configuration (ZSH)
- macOS system preferences
- Homebrew package management
- SSH configuration
- Neovim configuration
- Ghostty terminal configuration
- Git configuration (with GPG signing support)
- Tmux configuration
- Yazi file manager configuration
- Development tools configuration (asdf-managed: Node.js, pnpm, Bun, Go, PHP, Ruby, Flutter, PostgreSQL)
- Spaceship Prompt theme for Oh My Zsh
- GPG key management for commit signing

## Prerequisites

- macOS
- Command Line Tools for Xcode (will be installed automatically)

## Installation

1. Clone this repository:

   ```bash
   git clone https://github.com/adryanev/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. Make all scripts executable:

   ```bash
   chmod +x scripts/*.sh
   ```

3. Copy the example environment file and modify as needed:

   ```bash
   cp env/.env-install.example env/.env-install
   ```

4. Run the installation script:

   ```bash
   ./scripts/setup-new-mac.sh
   ```

5. (Optional) Setup GPG for commit signing:

   ```bash
   ./scripts/setup-gpg-key.sh
   ```

The installation will:

- Install Xcode Command Line Tools (if not already installed)
- Install Rosetta 2 (for Apple Silicon Macs)
- Install Oh My Zsh (if not already installed)
- Install Homebrew (if not already installed)
- Install Homebrew packages from `brew/Brewfile`
- Set up SSH keys
- Install CLI tools and plugins (Tmux Plugin Manager, Zsh plugins)
- Install Spaceship Prompt theme for Oh My Zsh
- Apply macOS system preferences
- Create symlinks for dotfiles using custom stow functions
- Configure Git user settings and GPG signing (if configured)
- Create a Code directory for projects
- Set up development environments using asdf (Node.js, pnpm, Bun, Java, PHP, Go, Ruby, Flutter, PostgreSQL)

## Customization

1. Modify the `env/.env-install` file to customize installation options:
   - `SSH_EMAIL`: Email for SSH key generation
   - `GIT_USER_NAME`: Your name for Git commits
   - `GIT_USER_EMAIL`: Your email for Git commits
   - `GIT_SIGNING_KEY`: Your GPG key ID for signing Git commits (optional)
2. Edit the `brew/Brewfile` to add or remove Homebrew packages
3. Update `macos/.macos` to change macOS system preferences
4. Modify shell configurations in `zsh/.zshrc` and `zsh/.zprofile`
5. Adjust `.stow-local-ignore` if you need to exclude certain files from being symlinked

## Structure

- `scripts/` - Shell scripts with proper error handling and common utilities
  - `setup-new-mac.sh` - Main installation script
  - `install-brew-packages.sh` - Homebrew package installation
  - `setup-ssh-keys.sh` - SSH configuration setup
  - `install-shell-plugins.sh` - Shell environment plugins installation
  - `setup-dev-environments.sh` - Development tools setup via asdf
  - `setup-gpg-key.sh` - Interactive GPG key management
  - `configure-git-user.sh` - Git user configuration
  - `install-spaceship-zsh-theme.sh` - Spaceship Prompt installation
  - `deploy-dotfiles.sh` - Atomic symlink management with custom stow functions
  - `lib/common.sh` - Shared utilities for error handling and logging
- `brew/` - Homebrew configurations
  - `Brewfile` - Homebrew package list
- `macos/` - macOS configurations
  - `.macos` - macOS system preferences
- `zsh/` - Zsh configurations
  - `.zshrc` - Zsh shell configuration with plugin setup (git, tmux, tmuxinator, zsh-autosuggestions, etc.)
  - `.zprofile` - Zsh profile configuration
  - `.zshrc_sourced/` - Modular Zsh configurations
    - `.dev` - Development tools configuration (pnpm, Bun, Dart)
    - `.path` - PATH environment variables configuration
    - `.alias` - Custom aliases (e.g., alias cd="z" for zoxide)
    - `.eval` - Commands to be evaluated (thefuck, zoxide)
    - `.spaceship` - Spaceship prompt theme configuration
    - `.wrapper` - Function wrappers (Yazi file manager integration)
- `git/` - Git configurations
  - `.gitconfig` - Git configuration
  - `.gitignore_global` - Global Git ignore patterns
- `tmux/` - Tmux configurations
  - `.tmux.conf` - Tmux configuration
- `env/` - Environment files
  - `.env-install` - Installation environment variables
  - `.env-install.example` - Example environment file
- `nvim/` - Neovim configuration
- `ghostty/` - Ghostty terminal configuration
- `gnupg/` - GnuPG configuration and secure key storage (keys are gitignored)
- `yazi/` - Yazi file manager configuration
  - `yazi.toml` - Main configuration
  - `keymap.toml` - Keyboard mappings
  - `theme.toml` - Theme settings
- `.stow-local-ignore` - GNU Stow ignore patterns

## Scripts

The `scripts/` directory contains shell scripts with proper error handling, logging, and idempotency:

- `setup-new-mac.sh` - The main entry point script that orchestrates the entire installation process. It checks for Xcode Command Line Tools, installs Oh My Zsh, Homebrew, sets up SSH keys, creates necessary directories, and calls all other installation scripts.

- `install-brew-packages.sh` - Handles the installation of all Homebrew packages, casks, and App Store applications using the Brewfile.

- `setup-ssh-keys.sh` - Generates SSH keys if they don't exist and configures SSH with proper permissions. Takes an email address as an argument for the SSH key.

- `install-shell-plugins.sh` - Installs and configures various shell environment plugins:
  - Installs Tmux Plugin Manager (TPM)
  - Installs Zsh plugins (zsh-autosuggestions, fast-syntax-highlighting, zsh-autocomplete)

- `setup-dev-environments.sh` - Sets up development environments using asdf:
  - Manages multiple versions of Node.js, Java, PHP, Go, Ruby
  - Installs pnpm, Bun, Flutter, and PostgreSQL
  - Configurable version numbers via environment variables
  - Installs latest Xcode using xcodes (if available)

- `setup-gpg-key.sh` - Interactive GPG key management:
  - Generate new GPG keys or import existing ones
  - Export keys to secure storage (gitignored)
  - Configure Git for commit signing
  - Test GPG signing functionality

- `configure-git-user.sh` - Configures Git user settings and GPG signing:
  - Sets username and email for Git commits
  - Configures GPG signing key (if provided)
  - Creates .gitconfig with appropriate settings

- `install-spaceship-zsh-theme.sh` - Installs and configures the Spaceship Prompt theme for Oh My Zsh:
  - Clones the Spaceship repository
  - Symlinks the theme to the Oh My Zsh themes directory
  - Sets up custom Spaceship theme configuration

- `deploy-dotfiles.sh` - Manages symlinks with atomic operations:
  - Creates symlinks for configuration files to their appropriate locations
  - Handles backup of existing dotfiles with timestamps
  - Uses atomic operations to prevent partial updates
  - Manages conflicts and helps ensure a clean installation

- `lib/common.sh` - Shared library for all scripts:
  - Proper error handling with `set -euo pipefail`
  - Colored logging functions (info, warn, error)
  - Safe symlink creation with automatic backups
  - Retry mechanism for network operations
  - Common utility functions

## Maintenance

To update Homebrew packages:

```bash
brew bundle --file=~/.dotfiles/brew/Brewfile
```

To update dotfiles:

```bash
cd ~/.dotfiles
git pull
./scripts/setup-new-mac.sh
```

To manage GPG keys:

```bash
./scripts/setup-gpg-key.sh
```

## Recent Improvements

- **Enhanced Error Handling**: All scripts now use `set -euo pipefail` and proper error trapping
- **Atomic Operations**: Symlink creation is now atomic to prevent partial updates
- **asdf Version Management**: Replaced NVM with asdf for consistent tool version management
- **GPG Key Management**: New script for secure GPG key setup and commit signing
- **Common Library**: Shared utilities reduce code duplication and improve consistency
- **Configurable Versions**: Development tool versions can be configured via environment variables

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
