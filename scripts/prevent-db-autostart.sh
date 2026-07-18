#!/bin/bash

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

log_info "Configuring database services to prevent auto-start..."

# Check if Homebrew is installed
if ! command_exists brew; then
    log_error "Homebrew is not installed. Please install Homebrew first."
    exit 1
fi

# `brew list` output is captured once and matched with a here-string rather than
# piped into grep. `grep -q` exits at the first match, which sends SIGPIPE to
# brew; under `set -o pipefail` the pipeline then reports 141 and an installed
# formula is misread as missing.
INSTALLED_FORMULAE=""

# Check whether a formula is installed
is_installed() {
    grep -qxF "$1" <<< "$INSTALLED_FORMULAE"
}

# Print the brew services status of a formula, empty when it has no service
service_status() {
    local name=$1 services
    services="$(brew services list)"
    awk -v name="$name" '$1 == name { print $2; exit }' <<< "$services"
}

# Function to stop and disable a service
disable_service() {
    local service_name=$1

    if ! is_installed "$service_name"; then
        log_info "${service_name} is not installed, skipping"
        return 0
    fi

    log_info "Stopping ${service_name} service..."

    # Stop the service if it's running
    brew services stop "${service_name}" 2>/dev/null || {
        log_info "${service_name} service was not running"
    }

    # Read the status back after stopping
    local status
    status="$(service_status "$service_name")"

    if [ -z "$status" ]; then
        log_info "${service_name} has no registered service"
    elif [ "$status" = "none" ] || [ "$status" = "stopped" ]; then
        log_info "${service_name} is stopped and won't auto-start"
    else
        log_warn "${service_name} service status: $status"
    fi
}

# Main execution
main() {
    INSTALLED_FORMULAE="$(brew list --formula)"

    # Disable MySQL
    disable_service "mysql"
    
    # Disable PostgreSQL (check for different versions)
    disable_service "postgresql"
    disable_service "postgresql@17"
    disable_service "postgresql@16"
    disable_service "postgresql@15"
    disable_service "postgresql@14"
    
    # Disable Redis if installed
    disable_service "redis"
    
    # Disable MongoDB if installed
    disable_service "mongodb-community"
    
    log_info "Database auto-start prevention complete!"
    log_info "To manually start a service, use: brew services start <service-name>"
    log_info "To see all services status, use: brew services list"
}

# Run main function
main "$@"