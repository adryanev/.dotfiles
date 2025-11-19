#!/bin/bash

# VSCode Profile-based Extension Manager
# Manage VSCode extensions based on predefined profiles

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directory containing profile definitions
PROFILE_DIR="$HOME/.dotfiles/.config/vscode-profiles"

# Print colored output
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if code command is available
check_vscode_cli() {
    if ! command -v code &> /dev/null; then
        print_error "VSCode CLI 'code' command not found"
        print_info "Install it from VSCode: View → Command Palette → 'Shell Command: Install code command in PATH'"
        exit 1
    fi
}

# List available profiles
list_profiles() {
    print_info "Available profiles:"
    echo ""
    for profile in "$PROFILE_DIR"/*.json; do
        if [ -f "$profile" ]; then
            profile_name=$(basename "$profile" .json)
            extension_count=$(jq -r '.recommendations | length' "$profile")
            echo "  • $profile_name ($extension_count extensions)"
        fi
    done
    echo ""
}

# Install extensions from a profile
install_profile() {
    local profile_name="$1"
    local profile_file="$PROFILE_DIR/$profile_name.json"

    if [ ! -f "$profile_file" ]; then
        print_error "Profile '$profile_name' not found"
        list_profiles
        exit 1
    fi

    print_info "Installing extensions from profile: $profile_name"
    echo ""

    # Read extensions from JSON file
    extensions=$(jq -r '.recommendations[]' "$profile_file")

    # Count total extensions
    total=$(echo "$extensions" | wc -l | tr -d ' ')
    current=0

    # Install each extension
    while IFS= read -r extension; do
        current=$((current + 1))
        echo -n "[$current/$total] Installing $extension... "

        if code --install-extension "$extension" --force > /dev/null 2>&1; then
            print_success "installed"
        else
            print_warning "failed or already installed"
        fi
    done <<< "$extensions"

    echo ""
    print_success "Profile '$profile_name' installation complete"
}

# Install multiple profiles at once
install_multiple_profiles() {
    shift # Remove 'install-multiple' argument

    if [ $# -eq 0 ]; then
        print_error "No profiles specified"
        echo "Usage: $0 install-multiple <profile1> <profile2> ..."
        exit 1
    fi

    print_info "Installing multiple profiles: $*"
    echo ""

    for profile in "$@"; do
        install_profile "$profile"
        echo ""
    done

    print_success "All profiles installed"
}

# List currently installed extensions
list_installed() {
    print_info "Currently installed extensions:"
    echo ""
    code --list-extensions | sort
}

# Compare installed extensions with a profile
compare_profile() {
    local profile_name="$1"
    local profile_file="$PROFILE_DIR/$profile_name.json"

    if [ ! -f "$profile_file" ]; then
        print_error "Profile '$profile_name' not found"
        exit 1
    fi

    print_info "Comparing installed extensions with profile: $profile_name"
    echo ""

    # Get expected extensions from profile
    expected_extensions=$(jq -r '.recommendations[]' "$profile_file" | sort)

    # Get currently installed extensions
    installed_extensions=$(code --list-extensions | sort)

    # Find missing extensions
    missing=$(comm -23 <(echo "$expected_extensions") <(echo "$installed_extensions"))

    # Find extra extensions (not in profile)
    extra=$(comm -13 <(echo "$expected_extensions") <(echo "$installed_extensions"))

    if [ -n "$missing" ]; then
        print_warning "Missing extensions (in profile but not installed):"
        echo "$missing" | sed 's/^/  • /'
        echo ""
    else
        print_success "All profile extensions are installed"
        echo ""
    fi

    if [ -n "$extra" ]; then
        print_info "Extra extensions (installed but not in profile):"
        echo "$extra" | sed 's/^/  • /'
    fi
}

# Create a project-specific extensions.json file
create_workspace_recommendations() {
    local profile_name="$1"
    local profile_file="$PROFILE_DIR/$profile_name.json"
    local output_file=".vscode/extensions.json"

    if [ ! -f "$profile_file" ]; then
        print_error "Profile '$profile_name' not found"
        exit 1
    fi

    # Create .vscode directory if it doesn't exist
    mkdir -p .vscode

    # Copy profile to workspace recommendations
    cp "$profile_file" "$output_file"

    print_success "Created $output_file from profile '$profile_name'"
    print_info "This file will recommend extensions to anyone who opens this workspace"
}

# Show usage information
show_usage() {
    cat << EOF
VSCode Profile-based Extension Manager

Usage: $0 <command> [arguments]

Commands:
  list                              List all available profiles
  install <profile>                 Install extensions from a specific profile
  install-multiple <p1> <p2> ...    Install extensions from multiple profiles
  compare <profile>                 Compare installed extensions with a profile
  workspace <profile>               Create .vscode/extensions.json from profile
  installed                         List currently installed extensions
  help                              Show this help message

Examples:
  $0 list
  $0 install core
  $0 install-multiple core web laravel
  $0 compare flutter
  $0 workspace laravel
  $0 installed

Available Profiles:
  core      - Essential extensions for all development
  web       - Web development (React, TypeScript, Tailwind)
  laravel   - PHP/Laravel development
  flutter   - Flutter/Dart development
  swift     - Swift/iOS development
  android   - Android/Kotlin development
  java      - Java development
  python    - Python development
  go        - Go development
  devops    - Docker, YAML, environment files
  api       - API development (Swagger, XML, Proto)
  markdown  - Markdown editing
  build     - Build tools (Make, TOML)
  themes    - UI themes and icon packs
  utils     - Utility extensions
  collab    - Collaboration tools
  debug     - Debugging and testing tools

EOF
}

# Main script logic
main() {
    check_vscode_cli

    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi

    command="$1"

    case "$command" in
        list)
            list_profiles
            ;;
        install)
            if [ -z "$2" ]; then
                print_error "Profile name required"
                echo "Usage: $0 install <profile>"
                exit 1
            fi
            install_profile "$2"
            ;;
        install-multiple)
            install_multiple_profiles "$@"
            ;;
        compare)
            if [ -z "$2" ]; then
                print_error "Profile name required"
                echo "Usage: $0 compare <profile>"
                exit 1
            fi
            compare_profile "$2"
            ;;
        workspace)
            if [ -z "$2" ]; then
                print_error "Profile name required"
                echo "Usage: $0 workspace <profile>"
                exit 1
            fi
            create_workspace_recommendations "$2"
            ;;
        installed)
            list_installed
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
