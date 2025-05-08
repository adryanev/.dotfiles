#!/bin/bash

# Function to safely stow a directory
stow_directory() {
    local dir=$1
    local target=$2

    echo "Linking $dir to $target..."

    # Create source directory if it doesn't exist
    if [ ! -d "$dir" ]; then
        echo "Directory $dir not found, creating it..."
        mkdir -p "$dir"
    fi

    # Create target directory if it doesn't exist
    mkdir -p "$target"

    # Perform stow operation
    if [ -d "$target/$dir" ]; then
        echo "Found existing directory $target/$dir, removing..."
        rm -rf "$target/$dir"
    fi

    # Create symlink for the entire directory
    ln -sf "$(pwd)/$dir" "$target/$dir"

    if [ $? -eq 0 ]; then
        echo "Successfully linked $dir to $target/$dir"
    else
        echo "Error: Failed to link $dir"
        return 1
    fi
}

# Function to stow individual files
stow_files() {
    local source_dir=$1
    local target_dir=$2
    local file_pattern=$3  # Optional: can be a specific filename or pattern

    echo "Stowing files from $source_dir to $target_dir..."

    # Create source directory if it doesn't exist
    if [ ! -d "$source_dir" ]; then
        echo "Source directory $source_dir not found, creating it..."
        mkdir -p "$source_dir"
    fi

    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"

    # Set appropriate permissions for sensitive directories
    if [[ "$target_dir" == *".gnupg"* ]]; then
        chmod 700 "$target_dir"
    fi

    # If a specific file pattern is provided
    if [ -n "$file_pattern" ]; then
        if [ -f "$source_dir/$file_pattern" ]; then
            echo "Stowing $file_pattern..."
            # Remove existing file if it exists
            if [ -f "$target_dir/$file_pattern" ]; then
                rm -f "$target_dir/$file_pattern"
            fi
            # Create symlink
            ln -sf "$(pwd)/$source_dir/$file_pattern" "$target_dir/$file_pattern"
            echo "Successfully stowed $file_pattern"
        else
            echo "Warning: $file_pattern not found in $source_dir, skipping..."
        fi
    else
        # Stow all files, but not directories
        echo "Stowing all files from $source_dir..."
        for file in "$source_dir"/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                echo "Stowing $filename..."
                # Remove existing file if it exists
                if [ -f "$target_dir/$filename" ]; then
                    rm -f "$target_dir/$filename"
                fi
                # Create symlink
                ln -sf "$(pwd)/$source_dir/$filename" "$target_dir/$filename"
            fi
        done
        echo "Successfully stowed files from $source_dir"
    fi
}

# Function to stow all files in a directory
stow_directory_files() {
    local source_dir=$1
    local target_dir=$2

    echo "Stowing all files from $source_dir to $target_dir..."

    # Create source directory if it doesn't exist
    if [ ! -d "$source_dir" ]; then
        echo "Source directory $source_dir not found, creating it..."
        mkdir -p "$source_dir"
    fi

    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"

    # Stow all files in the directory including hidden files
    shopt -s dotglob # Enable expansion to include hidden files
    for file in "$source_dir"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            echo "Stowing $filename..."
            # Remove existing file if it exists
            if [ -f "$target_dir/$filename" ]; then
                rm -f "$target_dir/$filename"
            fi
            # Create symlink
            ln -sf "$(pwd)/$source_dir/$filename" "$target_dir/$filename"
            echo "Successfully stowed $filename"
        fi
    done
    shopt -u dotglob # Disable dotglob after we're done
    echo "Successfully stowed all files from $source_dir"
}

# Move to the dotfiles root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$(dirname "$SCRIPT_DIR")"
echo "Working directory set to: $(pwd)"

echo "Creating symlinks for dotfiles..."

# Ensure .config directory exists
mkdir -p "$HOME/.config"

# Stow each directory
stow_directory "ghostty" "$HOME/.config"
stow_directory "nvim" "$HOME/.config"
stow_directory "yazi" "$HOME/.config"
# For git, stow only specific files (exclude .gitconfig)
echo "Stowing Git files (excluding .gitconfig)..."
stow_files "git" "$HOME" ".gitmessage"
stow_files "git" "$HOME" ".gitignore_global"

# Stow all files from tmux directory
stow_directory_files "tmux" "$HOME"

# Stow .zshrc
stow_files "zsh" "$HOME" ".zshrc"

# Stow .zshrc_sourced files
stow_directory_files "zsh/.zshrc_sourced" "$HOME/.zshrc_sourced"

# Stow only gpg-agent.conf
stow_files "gnupg" "$HOME/.gnupg" "gpg-agent.conf"

echo "Stowing completed successfully!"
