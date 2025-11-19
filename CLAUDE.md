# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for macOS setup. It contains configuration files and scripts to set up and maintain a development environment with:
- Shell configuration (ZSH with Oh My Zsh)
- Development tools managed via asdf (Node.js, pnpm, Bun, Java, PHP, Go, Ruby, Flutter, PostgreSQL)
- Terminal tools (Neovim, Tmux, Ghostty, Yazi)
- Git configuration with GPG signing support

## Common Commands

### Initial Setup
```bash
# Full macOS setup (only run once on a new machine)
./scripts/setup-new-mac.sh

# Deploy/update dotfiles symlinks
./scripts/deploy-dotfiles.sh
```

### Development Environment Management
```bash
# Install/update development environments (Node, Java, PHP, etc.)
./scripts/setup-dev-environments.sh

# Manage tool versions with asdf
asdf plugin add <tool>        # Add new tool plugin
asdf install <tool> latest     # Install latest version
asdf set --home <tool> latest  # Set global version
asdf list <tool>              # List installed versions
```

### Homebrew Package Management
```bash
# Update Homebrew packages from Brewfile
brew bundle --file=~/.dotfiles/brew/Brewfile

# Install new packages and update Brewfile
brew install <package>
brew bundle dump --file=~/.dotfiles/brew/Brewfile --force --describe --global
```

### Git Configuration
```bash
# Update git user configuration
./scripts/configure-git-user.sh

# Setup and manage GPG keys for commit signing
./scripts/setup-gpg-key.sh
```

### VSCode Extension Management
```bash
# List all available extension profiles
vscode-profile-manager.sh list

# Install a single profile
vscode-profile-manager.sh install core

# Install multiple profiles (recommended workflow)
vscode-profile-manager.sh install-multiple core web laravel

# Compare installed extensions with a profile
vscode-profile-manager.sh compare flutter

# Create workspace recommendations for a project
cd /path/to/project
vscode-profile-manager.sh workspace laravel
```

**Note**: After running `deploy-dotfiles.sh`, the script is available in your PATH via `~/Scripts`.

## Architecture & Key Scripts

### Script Organization (`scripts/`)

- **setup-new-mac.sh**: Main orchestrator that runs all other setup scripts in sequence
- **deploy-dotfiles.sh**: Uses custom stow functions to create symlinks for configuration files
- **setup-dev-environments.sh**: Manages development tools via asdf (recently updated to include pnpm)
- **install-brew-packages.sh**: Installs packages from `brew/Brewfile`
- **setup-ssh-keys.sh**: Generates and configures SSH keys
- **configure-git-user.sh**: Sets up git user config and GPG signing
- **setup-gpg-key.sh**: Interactive GPG key management for commit signing
- **vscode-profile-manager.sh**: Profile-based VSCode extension installer and manager

### Configuration Deployment Strategy

The repository uses a custom symlink approach (in `deploy-dotfiles.sh`) rather than GNU Stow directly:
- **stow_directory()**: Links entire directories to `~/.config/`
- **stow_files()**: Links individual files to specific locations
- **stow_directory_files()**: Links all files in a directory but not the directory itself

### Key Configurations

- **zsh/.zshrc**: Main shell configuration that sources modular configs from `.zshrc_sourced/`
- **zsh/.zshrc_sourced/**: Modular configs (.dev, .path, .alias, .eval, .spaceship, .wrapper)
- **brew/Brewfile**: Comprehensive list of Homebrew packages, casks, and App Store apps
- **env/.env-install**: Environment variables for setup scripts (SSH_EMAIL, GIT_USER_NAME, etc.)
- **.config/vscode-profiles/**: Profile-based extension definitions (17 profiles covering 149 extensions)
- **.config/vscode-profiles.md**: Documentation for VSCode extension profiles and usage instructions

## Development Workflow Tips

1. **Adding new tools via asdf**: Update `scripts/setup-dev-environments.sh` to include the plugin and installation steps

2. **Updating dotfiles**: Modify files in their respective directories, then run `./scripts/deploy-dotfiles.sh` to update symlinks

3. **Adding Homebrew packages**: Install with `brew install`, then dump to Brewfile with `brew bundle dump --file=brew/Brewfile --force`

4. **Testing script changes**: Scripts are idempotent and can be run multiple times safely

5. **Environment variables**: Check `env/.env-install` for required configuration before running setup scripts

6. **Managing VSCode extensions**:
   - Use `./scripts/vscode-profile-manager.sh` to install extensions by profile instead of installing all 149 extensions
   - Profile definitions are in `.config/vscode-profiles/` as JSON files
   - Update the Brewfile vscode section: `code --list-extensions | sort | sed 's/^/vscode "/' | sed 's/$/"/'`
   - Regenerate profile documentation after major changes to reflect current setup
