#!/usr/bin/env zsh
set -x
set -eu

LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

cd "$HOME"

# Create temporary directory with cleanup trap
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Function to check if a binary exists and meets version requirement
check_binary_version() {
    local binary=$1
    local version=$2
    if [ -f "$LOCAL_BIN/$binary" ]; then
        echo "$binary already installed, skipping..."
        return 0
    fi
    return 1
}

# Function to safely create symlink
safe_link() {
    local source=$1
    local target=$2
    if [ -L "$target" ]; then
        rm "$target"
    fi
    ln -s "$source" "$target"
}

# NVIM
if [ ! -d "$HOME/.local/nvim" ]; then
    cd "$TEMP_DIR"
    wget -q https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
    tar -xzf nvim-linux64.tar.gz
    rm -rf "$HOME/.local/nvim"
    mv nvim-linux64 "$HOME/.local/nvim"
    safe_link "../nvim/bin/nvim" "$LOCAL_BIN/nvim"
fi

# Fd-find
if ! check_binary_version "fd" "10.2.0"; then
    cd "$TEMP_DIR"
    wget -q https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-unknown-linux-gnu.tar.gz
    tar -xzf fd-v10.2.0-x86_64-unknown-linux-gnu.tar.gz
    mv fd-v10.2.0-x86_64-unknown-linux-gnu/fd "$LOCAL_BIN/fd"
fi

# Ripgrep
if ! check_binary_version "rg" "14.1.0"; then
    cd "$TEMP_DIR"
    wget -q https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep-14.1.0-x86_64-unknown-linux-musl.tar.gz
    tar -xzf ripgrep-14.1.0-x86_64-unknown-linux-musl.tar.gz
    mv ripgrep-14.1.0-x86_64-unknown-linux-musl/rg "$LOCAL_BIN/rg"
fi

# Difftastic
if ! check_binary_version "difft" "0.60.0"; then
    cd "$TEMP_DIR"
    wget -q https://github.com/Wilfred/difftastic/releases/download/0.60.0/difft-x86_64-unknown-linux-gnu.tar.gz
    tar -xzf difft-x86_64-unknown-linux-gnu.tar.gz
    mv difft "$LOCAL_BIN/difft"
fi

# Delta
if ! check_binary_version "delta" "0.18.1"; then
    cd "$TEMP_DIR"
    wget -q https://github.com/dandavison/delta/releases/download/0.18.1/delta-0.18.1-x86_64-unknown-linux-gnu.tar.gz
    tar -xzf delta-0.18.1-x86_64-unknown-linux-gnu.tar.gz
    mv delta-0.18.1-x86_64-unknown-linux-gnu/delta "$LOCAL_BIN/delta"
fi

# Lazygit
if ! check_binary_version "lazygit" "0.43.1"; then
    cd "$TEMP_DIR"
    wget -q https://github.com/jesseduffield/lazygit/releases/download/v0.43.1/lazygit_0.43.1_Linux_x86_64.tar.gz
    tar -xzf lazygit_0.43.1_Linux_x86_64.tar.gz
    mv lazygit "$LOCAL_BIN/lazygit"
fi

# DOTFILES
if [ ! -d "$HOME/.dotfiles" ]; then
    cd "$HOME"
    git clone https://github.com/josejg/dotfiles.git .dotfiles
    cd .dotfiles
    ./shell-setup.sh
    ./setup_all.sh
else
    echo "Dotfiles already installed, skipping..."
    cd "$HOME/.dotfiles"
    git pull
fi

# NEOVIM - PlugInstall
NVIM="$LOCAL_BIN/nvim"
export PATH="$HOME/.neovim/node/bin:$PATH"
export PATH="$HOME/.neovim/py3/bin/:$PATH"

# Function to check if plugin is installed
check_vim_plugin() {
    local plugin_dir="$HOME/.vim/plugged/$1"
    [ -d "$plugin_dir" ]
}

# Only run PlugInstall if plugins directory doesn't exist
if [ ! -d "$HOME/.vim/plugged" ]; then
    $NVIM --headless +PlugInstall +qall
fi

# Function to check if CoC extension is installed
check_coc_extension() {
    local extension=$1
    [ -d "$HOME/.config/coc/extensions/node_modules/$extension" ]
}

# Install CoC extensions if not already installed
for ext in coc-explorer coc-git coc-highlight coc-pyright coc-json coc-sh coc-yaml; do
    if ! check_coc_extension "$ext"; then
        $NVIM --headless +"CocInstall -sync $ext" +qall
    fi
done

# Only run CocUpdateSync if extensions are installed
if [ -d "$HOME/.config/coc/extensions" ]; then
    $NVIM --headless +CocUpdateSync +qall
fi

# Cleanup
if [ -n "${CLEANUP:-}" ]; then
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    git --git-dir=$HOME/.dotfiles/.git clean -fxd
fi
