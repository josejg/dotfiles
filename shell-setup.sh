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

# FZF
if ! safe_git_clone "https://github.com/junegunn/fzf.git" "$HOME/.fzf"; then
    pull_repo "$HOME/.fzf"
fi
if [[ ! -f "$HOME/.fzf/bin/fzf" ]]; then
    yes | $HOME/.fzf/install
fi

LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

# DELTA (git pager)
if ! command -v delta > /dev/null 2>&1; then
    if [[ "$(uname -s)" == "Darwin" ]]; then
        brew install git-delta
    else
        DELTA_VERSION="0.18.2"
        DELTA_ARCH="$(uname -m)"
        if [[ "$DELTA_ARCH" == "x86_64" ]]; then
            DELTA_ARCH="x86_64"
        elif [[ "$DELTA_ARCH" == "aarch64" ]]; then
            DELTA_ARCH="aarch64"
        fi
        DELTA_TAR="delta-${DELTA_VERSION}-${DELTA_ARCH}-unknown-linux-gnu.tar.gz"
        curl -sSL "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/${DELTA_TAR}" | tar xz -C /tmp
        mv "/tmp/delta-${DELTA_VERSION}-${DELTA_ARCH}-unknown-linux-gnu/delta" "$LOCAL_BIN/delta"
        chmod +x "$LOCAL_BIN/delta"
    fi
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

mkdir -p "$HOME/.zsh"

# Fast syntax highlighting
FSH_DIR="$HOME/.zsh/fast-syntax-highlighting"
if ! safe_git_clone "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" "$FSH_DIR"; then
    pull_repo "$FSH_DIR"
fi

# Zsh autosuggestions
ZAS_DIR="$HOME/.zsh/zsh-autosuggestions"
if ! safe_git_clone "https://github.com/zsh-users/zsh-autosuggestions.git" "$ZAS_DIR"; then
    pull_repo "$ZAS_DIR"
fi

# Zsh history substring search
ZHSS_DIR="$HOME/.zsh/zsh-history-substring-search"
if ! safe_git_clone "https://github.com/zsh-users/zsh-history-substring-search.git" "$ZHSS_DIR"; then
    pull_repo "$ZHSS_DIR"
fi

# Zsh completions
ZC_DIR="$HOME/.zsh/zsh-completions"
if ! safe_git_clone "https://github.com/zsh-users/zsh-completions.git" "$ZC_DIR"; then
    pull_repo "$ZC_DIR"
fi

# You should use
YSU_DIR="$HOME/.zsh/zsh-you-should-use"
if ! safe_git_clone "https://github.com/MichaelAquilina/zsh-you-should-use.git" "$YSU_DIR"; then
    pull_repo "$YSU_DIR"
fi

# fzf-tab
FZFTAB_DIR="$HOME/.zsh/fzf-tab"
if ! safe_git_clone "https://github.com/Aloxaf/fzf-tab.git" "$FZFTAB_DIR"; then
    pull_repo "$FZFTAB_DIR"
fi

# zsh-autopair
AUTOPAIR_DIR="$HOME/.zsh/zsh-autopair"
if ! safe_git_clone "https://github.com/hlissner/zsh-autopair.git" "$AUTOPAIR_DIR"; then
    pull_repo "$AUTOPAIR_DIR"
fi

# Powerlevel10k
P10K_DIR="$HOME/.zsh/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    git clone --depth=1 "https://github.com/romkatv/powerlevel10k.git" "$P10K_DIR"
else
    pull_repo "$P10K_DIR"
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
