#!/usr/bin/env bash

set -e          # Exit on error
set -u          # Exit on unset ENVVAR
set -x          # Enable verbosity

#######################
# Helper Functions
#######################

function check_dependencies() {
    local missing_deps=()
    for dep in stow find date mkdir; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Error: Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

function safe_backup() {
    local path=$1
    local backup_dir=$2
    
    if [ -e "$path" ]; then
        if [ ! -L "$path" ]; then  # Only backup if it's not a symlink
            echo "Backing up $path"
            mv "$path" "$backup_dir/"
            return 0
        else
            echo "Removing existing symlink $path"
            rm "$path"
            return 1
        fi
    fi
    return 1
}

function safe_stow() {
    local program=$1
    local target=$2
    
    if [ ! -d "$program" ]; then
        echo "Warning: Program directory $program does not exist, skipping"
        return 1
    fi
    
    # First try to stow normally
    if stow -v --target="$target" "$program" 2>/dev/null; then
        echo "Successfully stowed $program"
        return 0
    fi
    
    # If stow fails, handle conflicts
    echo "Handling conflicts for $program"
    local conflicts=$(stow -v --target="$target" "$program" 2>&1 | grep 'existing target is' | awk '{print $NF}')
    
    if [ -n "$conflicts" ]; then
        while IFS= read -r conflict; do
            local full_path="$target/$conflict"
            safe_backup "$full_path" "$BACKUP_DIR"
        done <<< "$conflicts"
        
        # Try stow again after handling conflicts
        if stow -v --target="$target" "$program"; then
            echo "Successfully stowed $program after handling conflicts"
            return 0
        fi
    fi
    
    echo "Error: Failed to stow $program"
    return 1
}

#######################
# Main Script
#######################

# Check for required dependencies
check_dependencies

# Define programs to stow
PROGRAMS=(bash env git python tmux vim zsh)
# PROGRAMS=(alias aspell bash env git latex python scripts stow tmux vim zsh mac terminal)

# Create backup directory with timestamp
BACKUP_DIR="dotfiles_backup_$(date -u +"%Y%m%d%H%M%S")"
mkdir -p "$BACKUP_DIR"

# Clean up .DS_Store files
find . -name ".DS_Store" -type f -delete

# Create required directories
mkdir -p ~/.vim/undodir

# Backup common configuration files
COMMON_CONFIGS=(
    ~/.bash_profile
    ~/.bash_logout
    ~/.bashrc
    ~/.gitconfig
    ~/.tmux.conf
    ~/.profile
)

for config in "${COMMON_CONFIGS[@]}"; do
    safe_backup "$config" "$BACKUP_DIR"
done

# Handle zprezto files if they exist
if [ -d ~/.zprezto/runcoms ]; then
    while IFS= read -r -d '' zfile; do
        safe_backup "$zfile" "$BACKUP_DIR"
    done < <(find ~/.zprezto/runcoms -name "z*" -type f -print0)
fi

# Stow each program
STOW_ERRORS=()
for program in "${PROGRAMS[@]}"; do
    echo "Configuring $program"
    if ! safe_stow "$program" "$HOME"; then
        STOW_ERRORS+=("$program")
    fi
done

# Report results
if [ ${#STOW_ERRORS[@]} -eq 0 ]; then
    echo "All programs successfully configured!"
    
    # Clean up empty backup directory if nothing was backed up
    if [ -z "$(ls -A "$BACKUP_DIR")" ]; then
        rmdir "$BACKUP_DIR"
        echo "No backups were needed, removed empty backup directory"
    else
        echo "Backup directory: $BACKUP_DIR"
    fi
else
    echo "The following programs had errors during configuration:"
    printf '%s\n' "${STOW_ERRORS[@]}"
    echo "Please check the output above for details"
    echo "Backup directory: $BACKUP_DIR"
    exit 1
fi
