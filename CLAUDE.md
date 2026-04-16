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

<!-- rtk-instructions v2 -->
# RTK (Rust Token Killer) - Token-Optimized Commands

## Golden Rule

**Always prefix commands with `rtk`**. If RTK has a dedicated filter, it uses it. If not, it passes through unchanged. This means RTK is always safe to use.

**Important**: Even in command chains with `&&`, use `rtk`:
```bash
# ❌ Wrong
git add . && git commit -m "msg" && git push

# ✅ Correct
rtk git add . && rtk git commit -m "msg" && rtk git push
```

## RTK Commands by Workflow

### Build & Compile (80-90% savings)
```bash
rtk cargo build         # Cargo build output
rtk cargo check         # Cargo check output
rtk cargo clippy        # Clippy warnings grouped by file (80%)
rtk tsc                 # TypeScript errors grouped by file/code (83%)
rtk lint                # ESLint/Biome violations grouped (84%)
rtk prettier --check    # Files needing format only (70%)
rtk next build          # Next.js build with route metrics (87%)
```

### Test (90-99% savings)
```bash
rtk cargo test          # Cargo test failures only (90%)
rtk vitest run          # Vitest failures only (99.5%)
rtk playwright test     # Playwright failures only (94%)
rtk test <cmd>          # Generic test wrapper - failures only
```

### Git (59-80% savings)
```bash
rtk git status          # Compact status
rtk git log             # Compact log (works with all git flags)
rtk git diff            # Compact diff (80%)
rtk git show            # Compact show (80%)
rtk git add             # Ultra-compact confirmations (59%)
rtk git commit          # Ultra-compact confirmations (59%)
rtk git push            # Ultra-compact confirmations
rtk git pull            # Ultra-compact confirmations
rtk git branch          # Compact branch list
rtk git fetch           # Compact fetch
rtk git stash           # Compact stash
rtk git worktree        # Compact worktree
```

Note: Git passthrough works for ALL subcommands, even those not explicitly listed.

### GitHub (26-87% savings)
```bash
rtk gh pr view <num>    # Compact PR view (87%)
rtk gh pr checks        # Compact PR checks (79%)
rtk gh run list         # Compact workflow runs (82%)
rtk gh issue list       # Compact issue list (80%)
rtk gh api              # Compact API responses (26%)
```

### JavaScript/TypeScript Tooling (70-90% savings)
```bash
rtk pnpm list           # Compact dependency tree (70%)
rtk pnpm outdated       # Compact outdated packages (80%)
rtk pnpm install        # Compact install output (90%)
rtk npm run <script>    # Compact npm script output
rtk npx <cmd>           # Compact npx command output
rtk prisma              # Prisma without ASCII art (88%)
```

### Files & Search (60-75% savings)
```bash
rtk ls <path>           # Tree format, compact (65%)
rtk read <file>         # Code reading with filtering (60%)
rtk grep <pattern>      # Search grouped by file (75%)
rtk find <pattern>      # Find grouped by directory (70%)
```

### Analysis & Debug (70-90% savings)
```bash
rtk err <cmd>           # Filter errors only from any command
rtk log <file>          # Deduplicated logs with counts
rtk json <file>         # JSON structure without values
rtk deps                # Dependency overview
rtk env                 # Environment variables compact
rtk summary <cmd>       # Smart summary of command output
rtk diff                # Ultra-compact diffs
```

### Infrastructure (85% savings)
```bash
rtk docker ps           # Compact container list
rtk docker images       # Compact image list
rtk docker logs <c>     # Deduplicated logs
rtk kubectl get         # Compact resource list
rtk kubectl logs        # Deduplicated pod logs
```

### Network (65-70% savings)
```bash
rtk curl <url>          # Compact HTTP responses (70%)
rtk wget <url>          # Compact download output (65%)
```

### Meta Commands
```bash
rtk gain                # View token savings statistics
rtk gain --history      # View command history with savings
rtk discover            # Analyze Claude Code sessions for missed RTK usage
rtk proxy <cmd>         # Run command without filtering (for debugging)
rtk init                # Add RTK instructions to CLAUDE.md
rtk init --global       # Add RTK to ~/.claude/CLAUDE.md
```

## Token Savings Overview

| Category | Commands | Typical Savings |
|----------|----------|-----------------|
| Tests | vitest, playwright, cargo test | 90-99% |
| Build | next, tsc, lint, prettier | 70-87% |
| Git | status, log, diff, add, commit | 59-80% |
| GitHub | gh pr, gh run, gh issue | 26-87% |
| Package Managers | pnpm, npm, npx | 70-90% |
| Files | ls, read, grep, find | 60-75% |
| Infrastructure | docker, kubectl | 85% |
| Network | curl, wget | 65-70% |

Overall average: **60-90% token reduction** on common development operations.
<!-- /rtk-instructions -->