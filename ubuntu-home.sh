#!/usr/bin/env zsh
set -x
set -eu

LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

cd "$HOME"

mkdir -p /tmp/downloads

# NVIM
cd /tmp/downloads
wget -q https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
tar -xzf nvim-linux64.tar.gz
mv nvim-linux64 "$HOME/.local/nvim"
cd $LOCAL_BIN
ln -s ../.local/nvim/bin/nvim ./nvim

# Fd-find
cd /tmp/downloads
wget -q https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-unknown-linux-gnu.tar.gz
tar -xzf fd-v10.2.0-x86_64-unknown-linux-gnu.tar.gz
mv fd-v10.2.0-x86_64-unknown-linux-gnu/fd "$LOCAL_BIN/fd"

# Ripgrep
cd /tmp/downloads
wget -q https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep-14.1.0-aarch64-unknown-linux-gnu.tar.gz
tar -xzf ripgrep-14.1.0-aarch64-unknown-linux-gnu.tar.gz
mv ripgrep-14.1.0-aarch64-unknown-linux-gnu/rg "$LOCAL_BIN/rg"

# Difftastic
cd /tmp/downloads
wget -q https://github.com/Wilfred/difftastic/releases/download/0.60.0/difft-x86_64-unknown-linux-gnu.tar.gz
tar -xzf difft-x86_64-unknown-linux-gnu.tar.gz
rm ./difft-x86_64-unknown-linux-gnu.tar.gz
mv difft "$LOCAL_BIN/difft"

# Delta
cd /tmp/downloads
wget -q https://github.com/dandavison/delta/releases/download/0.18.1/delta-0.18.1-x86_64-unknown-linux-gnu.tar.gz
tar -xzf delta-0.18.1-x86_64-unknown-linux-gnu.tar.gz
rm ./delta-0.18.1-x86_64-unknown-linux-gnu.tar.gz
mv delta-0.18.1-x86_64-unknown-linux-gnu/delta "$LOCAL_BIN/delta"

# Lazygit
cd /tmp/downloads
wget -q https://github.com/jesseduffield/lazygit/releases/download/v0.43.1/lazygit_0.43.1_Linux_x86_64.tar.gz
tar -xzf lazygit_0.43.1_Linux_x86_64.tar.gz
rm ./lazygit_0.43.1_Linux_x86_64.tar.gz
mv lazygit "$LOCAL_BIN/lazygit"

# Cleanup
rm -rf /tmp/downloads

# DOTFILES
cd $HOME
git clone https://github.com/josejg/dotfiles.git .dotfiles
cd .dotfiles
./shell-setup.sh
./setup_all.sh

# NEOVIM - PlugInstall
NVIM="$HOME/.local/bin/nvim"
$NVIM --headless +PlugInstall +qall
$NVIM --headless +"CocInstall -sync coc-explorer coc-git coc-highlight coc-pyright coc-json coc-sh coc-yaml" +qall
$NVIM --headless +CocUpdateSync +qall

# # Cleanup
if [ -n "${CLEANUP:-}" ]; then
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    # rm -rf /root/.cache/nvim
    # rm -rf /tmp/*
    # rm -rf /var/tmp/*
    # rm -rf /root/.npm
    # rm -rf /root/.cache
    git --git-dir=$HOME/.dotfiles/.git clean -fxd
fi 
