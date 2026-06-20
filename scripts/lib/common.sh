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

# Prune old timestamped backups for a target, keeping the newest $BACKUP_KEEP.
prune_backups() {
    local target=$1
    local old
    # List backups newest-first, skip the ones we keep, remove the rest.
    while IFS= read -r old; do
        [ -n "$old" ] || continue
        rm -rf "$old" && log_info "Pruned old backup: $old"
    done < <(ls -1dt "${target}".backup.* 2>/dev/null | tail -n +"$((BACKUP_KEEP + 1))")
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

# Run command with retry
retry_command() {
    local max_attempts=${2:-3}
    local delay=${3:-5}
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