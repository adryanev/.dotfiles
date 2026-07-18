# ~/.zshenv - sourced for EVERY zsh invocation, including non-interactive ones.
#
# This exists so machine-specific secrets reach processes that are not started
# from an interactive terminal. ~/.zshrc (and therefore ~/.zshrc_sourced/.local)
# runs only for interactive shells, so a client launched from a GUI application
# or a launchd job saw none of these variables.
#
# Concretely: the Codex CLI passes CONTEXT7_API_KEY to the context7 MCP server
# by name and resolves it from its own environment, so without this the header
# was empty whenever Codex was not started from a terminal.
#
# Keep this file minimal. It runs for every `zsh -c` in every script, so PATH
# manipulation and slow initialisation belong in ~/.zshrc_sourced/ instead.
#
# ~/.zshrc_local itself is untracked (it holds the secret values) and is
# restored from the encrypted backup by post-reinstall-restore.sh.

# The guard keeps the values from being re-exported when ~/.zshrc_sourced/.local
# sources the same file later in an interactive shell.
if [[ -z "$DOTFILES_LOCAL_ENV_LOADED" && -f "$HOME/.zshrc_local" ]]; then
    source "$HOME/.zshrc_local"
    export DOTFILES_LOCAL_ENV_LOADED=1
fi
