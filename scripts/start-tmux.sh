#!/bin/sh

# Terminal startup shell: attach to the standard tmux session, or create it.
#
# Referenced by kitty/kitty.conf via the `shell` option. Kept as a tracked
# script rather than an inline command so the launch logic lives in the
# repository and survives a fresh machine setup.
#
# Behaviour:
#   - Already inside tmux ($TMUX set): run a plain shell, so nested panes and
#     splits do not start a second server.
#   - tmux not installed: run a plain shell rather than failing to open the
#     terminal at all.
#   - Otherwise: attach to session "$TMUX_SESSION" (default "adryanev"),
#     creating it if it does not exist.
#
# POSIX sh only. This runs before the login shell, so no zsh features here.

# kitty launches this script directly from the GUI application, so PATH is
# launchd's minimal default: no /opt/homebrew/bin. Homebrew normally reaches
# the shell via /etc/paths.d/homebrew (read by path_helper from /etc/zprofile)
# and ~/.zprofile, both of which run after this script. Without this line the
# tmux lookup below fails on a machine where tmux is plainly installed.
PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export PATH

SESSION="${TMUX_SESSION:-adryanev}"

# Prefer the user's login shell for the fallback and for tmux panes.
SHELL_BIN="${SHELL:-/bin/zsh}"

if [ -n "$TMUX" ] || ! command -v tmux >/dev/null 2>&1; then
    exec "$SHELL_BIN" -l
fi

# -A attaches to SESSION if it exists, otherwise creates it.
exec tmux new-session -A -s "$SESSION"
