#!/bin/bash

# Common utilities and error handling for all scripts

set -euo pipefail
IFS=$'\n\t'

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# When set to 1, mutating helpers (safe_symlink, ensure_directory) only
# report what they would do instead of changing the filesystem.
DRY_RUN="${DRY_RUN:-0}"

# Number of timestamped backups to keep per target (older ones are pruned).
BACKUP_KEEP="${BACKUP_KEEP:-3}"

# Error handling
trap 'error_handler $? $LINENO' ERR

error_handler() {
    local exit_code=$1
    local line_number=$2
    echo -e "${RED}Error: Command failed with exit code $exit_code at line $line_number${NC}" >&2
    exit "$exit_code"
}

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Print each whitespace-separated word of "$*" on its own line.
# IFS is $'\n\t' here, so `for x in $VAR` does not split a space-separated
# list; iterate with `for x in $(split_words "$VAR")` instead.
split_words() {
    printf '%s\n' "$*" | tr -s '[:space:]' '\n' | grep -v '^$' || true
}

# Prune old timestamped backups for a target, keeping the newest $BACKUP_KEEP.
prune_backups() {
    local target=$1

    # Timestamped names (YYYYMMDD_HHMMSS) sort chronologically, so a plain
    # glob (sorted oldest-first) lets us drop all but the newest few without
    # parsing `ls`. nullglob makes the array empty when nothing matches.
    local had_nullglob=0
    shopt -q nullglob && had_nullglob=1
    shopt -s nullglob
    local backups=("${target}".backup.*)
    [ "$had_nullglob" -eq 0 ] && shopt -u nullglob

    local count=${#backups[@]}
    [ "$count" -le "$BACKUP_KEEP" ] && return 0

    local prune=$((count - BACKUP_KEEP)) i
    for ((i = 0; i < prune; i++)); do
        rm -rf "${backups[i]}" && log_info "Pruned old backup: ${backups[i]}"
    done
}

# Safe symlink creation
safe_symlink() {
    local source=$1
    local target=$2

    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
            log_info "Symlink already correct: $target -> $source"
            return 0
        fi

        local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
        if [ "$DRY_RUN" = "1" ]; then
            log_warn "[dry-run] Would back up: $target -> $backup"
        else
            log_warn "Backing up existing file: $target -> $backup"
            mv "$target" "$backup"
            prune_backups "$target"
        fi
    fi

    if [ "$DRY_RUN" = "1" ]; then
        log_info "[dry-run] Would create symlink: $target -> $source"
        return 0
    fi

    ln -sf "$source" "$target"
    log_info "Created symlink: $target -> $source"
}

# Ensure directory exists
ensure_directory() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        if [ "$DRY_RUN" = "1" ]; then
            log_info "[dry-run] Would create directory: $dir"
            return 0
        fi
        mkdir -p "$dir"
        log_info "Created directory: $dir"
    fi
}

# Run command with retry. Every argument is part of the command; tune the
# attempt count and delay with the RETRY_ATTEMPTS/RETRY_DELAY environment
# variables. (These used to be read from $2/$3, which collided with the
# command's own arguments -- `retry_command asdf install nodejs 22` set
# max_attempts to "install" and failed the loop's integer comparison.)
retry_command() {
    local max_attempts=${RETRY_ATTEMPTS:-3}
    local delay=${RETRY_DELAY:-5}
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if "$@"; then
            return 0
        fi
        
        log_warn "Command failed. Attempt $attempt/$max_attempts"
        if [ $attempt -lt $max_attempts ]; then
            log_info "Retrying in $delay seconds..."
            sleep $delay
        fi
        attempt=$((attempt + 1))
    done
    
    log_error "Command failed after $max_attempts attempts"
    return 1
}