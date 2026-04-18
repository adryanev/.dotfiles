
# ═══════════════════════════════════════════════════════════════
# ZSH CONFIGURATION
# ═══════════════════════════════════════════════════════════════
# Main zsh configuration file that loads Oh My Zsh and sources
# modular configurations from ~/.zshrc_sourced/
#
# Modular configs:
# - .path      → PATH environment variables
# - .dev       → Development tools (Node, Ruby, Go, etc.)
# - .alias     → Command aliases
# - .wrapper   → Function wrappers (yazi, etc.)
# - .eval      → Tool initialization (zoxide, thefuck)
# - .spaceship → Spaceship prompt configuration
# ═══════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════
# ENVIRONMENT VARIABLES
# ═══════════════════════════════════════════════════════════════

export EDITOR="nvim"
export VISUAL="nvim"
export GPG_TTY=$(tty)

# ═══════════════════════════════════════════════════════════════
# OH MY ZSH
# ═══════════════════════════════════════════════════════════════

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="spaceship"

# Oh My Zsh plugins (keep minimal for fast startup)
plugins=(
  git                      # Git aliases and completions
  zsh-autosuggestions      # Suggest commands as you type
  fast-syntax-highlighting # Syntax highlighting for commands
  zsh-autocomplete         # Advanced tab completion
)

source $ZSH/oh-my-zsh.sh

# ═══════════════════════════════════════════════════════════════
# MODULAR CONFIGURATIONS
# ═══════════════════════════════════════════════════════════════
# Load order matters! PATH → Dev tools → Aliases → Wrappers → Evals

# 1. PATH variables (load first so tools can be found)
[[ -f "$HOME/.zshrc_sourced/.path" ]] && source "$HOME/.zshrc_sourced/.path"

# 2. Development environment setup
[[ -f "$HOME/.zshrc_sourced/.dev" ]] && source "$HOME/.zshrc_sourced/.dev"

# 3. Headroom proxy client routing
[[ -f "$HOME/.zshrc_sourced/.headroom" ]] && source "$HOME/.zshrc_sourced/.headroom"

# 4. Spaceship prompt configuration
[[ -f "$HOME/.zshrc_sourced/.spaceship" ]] && source "$HOME/.zshrc_sourced/.spaceship"

# 5. Aliases (load after tools are configured)
[[ -f "$HOME/.zshrc_sourced/.alias" ]] && source "$HOME/.zshrc_sourced/.alias"

# 6. Function wrappers
[[ -f "$HOME/.zshrc_sourced/.wrapper" ]] && source "$HOME/.zshrc_sourced/.wrapper"

# 7. Tool initialization (load last, may be slow)
[[ -f "$HOME/.zshrc_sourced/.eval" ]] && source "$HOME/.zshrc_sourced/.eval"

# Added by codebase-memory-mcp install
export PATH="/Users/adryanev/.local/bin:$PATH"
