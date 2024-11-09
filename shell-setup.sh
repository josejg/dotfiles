#!/usr/bin/env zsh
set -x
set -eu

#######################
# Helper Functions
#######################

function safe_git_clone() {
    local repo=$1
    local dest=$2
    if [[ ! -d "$dest" ]]; then
        git clone "$repo" "$dest"
        return 0
    fi
    return 1
}

function pull_repo() {
    local dir=$1
    if [[ -d "$dir/.git" ]]; then
        cd "$dir"
        git pull
        cd - > /dev/null
    else
        echo "Warning: $dir is not a git repository"
    fi
}

function safe_link() {
    local source=$1
    local target=$2
    if [[ -L "$target" ]]; then
        rm "$target"
    elif [[ -f "$target" ]]; then
        mv "$target" "${target}.bk"
    fi
    ln -s "$source" "$target"
}

function backup_file() {
    local file=$1
    if [[ -f "$file" && ! -L "$file" ]]; then
        mv "$file" "${file}.bk"
    fi
}

#######################
# BIN
#######################

mkdir -p "$HOME/bin"
cd "$HOME"

# FASD
if [[ ! -f "$HOME/bin/fasd" ]]; then
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT
    safe_git_clone "https://github.com/clvv/fasd.git" "$TEMP_DIR/fasd"
    cd "$TEMP_DIR/fasd"
    PREFIX=$HOME make install
    cd - > /dev/null
fi

# FZF
if ! safe_git_clone "https://github.com/junegunn/fzf.git" "$HOME/.fzf"; then
    pull_repo "$HOME/.fzf"
fi
if [[ ! -f "$HOME/.fzf/bin/fzf" ]]; then
    yes | $HOME/.fzf/install
fi

LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

# DIFF-SO-FANCY
if [[ ! -f "$LOCAL_BIN/diff-so-fancy" ]]; then
    curl -L -o "$LOCAL_BIN/diff-so-fancy" https://github.com/so-fancy/diff-so-fancy/releases/download/v1.4.4/diff-so-fancy
    chmod +x "$LOCAL_BIN/diff-so-fancy"
fi

#######################
# TMUX
#######################

TMUX_TPM_DIR="$HOME/.tmux/plugins/tpm"
if ! safe_git_clone "https://github.com/tmux-plugins/tpm" "$TMUX_TPM_DIR"; then
    pull_repo "$TMUX_TPM_DIR"
fi

#######################
# ZSH
#######################

ZPREZTO_DIR="${ZDOTDIR:-$HOME}/.zprezto"
if ! safe_git_clone "https://github.com/sorin-ionescu/prezto.git" "$ZPREZTO_DIR"; then
    cd "$ZPREZTO_DIR"
    git pull
    git submodule update --init --recursive
    cd - > /dev/null
else
    # Only create symlinks on fresh install
    backup_file ~/.zshrc
    backup_file ~/.zprofile

    setopt EXTENDED_GLOB
    for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
        safe_link "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
    done
fi

mkdir -p "$HOME/.zsh"

# Fast syntax highlighting
FSH_DIR="$HOME/.zsh/fast-syntax-highlighting"
if ! safe_git_clone "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" "$FSH_DIR"; then
    pull_repo "$FSH_DIR"
fi

#######################
# NEOVIM
#######################

NVIM="$HOME/.neovim"
mkdir -p "$NVIM"

# Create Python3 environment
if [[ ! -d "$NVIM/py3" ]]; then
    python3 -m venv "$NVIM/py3"
    "$NVIM/py3/bin/pip" install -q --upgrade pip
    "$NVIM/py3/bin/pip" install -q neovim 'python-language-server[all]' pylint isort jedi flake8 black yapf ruff
else
    # Update packages in existing environment
    "$NVIM/py3/bin/pip" install -q --upgrade neovim 'python-language-server[all]' pylint isort jedi flake8 black yapf ruff
fi

# Create node env
if [[ ! -d "$NVIM/node" ]]; then
    mkdir -p "$NVIM/node"
    NODE_SCRIPT=$(mktemp)
    curl -sL install-node.now.sh/lts -o "$NODE_SCRIPT"
    chmod +x "$NODE_SCRIPT"
    PREFIX="$NVIM/node" "$NODE_SCRIPT" -y
    rm "$NODE_SCRIPT"
    
    PATH="$NVIM/node/bin:$PATH"
    if ! npm list -g neovim > /dev/null 2>&1; then
        npm install -g neovim
    fi
else
    # Update neovim package in existing environment
    PATH="$NVIM/node/bin:$PATH"
    npm update -g neovim
fi

#######################
# Alacritty themes
#######################

ALACRITTY_THEMES_DIR="$HOME/.config/alacritty/themes"
if ! safe_git_clone "https://github.com/JJGO/alacritty-theme.git" "$ALACRITTY_THEMES_DIR"; then
    pull_repo "$ALACRITTY_THEMES_DIR"
fi
