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

# Function to stop and disable a service
disable_service() {
    local service_name=$1
    
    # Check if service is installed
    if brew list --formula | grep -q "^${service_name}$"; then
        log_info "Stopping ${service_name} service..."
        
        # Stop the service if it's running
        brew services stop "${service_name}" 2>/dev/null || {
            log_info "${service_name} service was not running"
        }
        
        # Check if service is in the list
        if brew services list | grep -q "${service_name}"; then
            local status=$(brew services list | grep "${service_name}" | awk '{print $2}')
            if [ "$status" = "none" ] || [ "$status" = "stopped" ]; then
                log_info "${service_name} is stopped and won't auto-start"
            else
                log_warn "${service_name} service status: $status"
            fi
        fi
    else
        log_info "${service_name} is not installed, skipping"
    fi
}

# Main execution
main() {
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