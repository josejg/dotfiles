#!/usr/bin/env zsh
set -x
set -eu

mkdir -p "$HOME/bin"
cd "$HOME"

# NVIM
wget -q https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
tar -xzf nvim-linux64.tar.gz
rm ./nvim-linux64.tar.gz
mkdir -p .local
mv nvim-linux64 .local/nvim
cd bin
ln -s ../.local/nvim/bin/nvim ./nvim

# DOTFILES
cd $HOME
git clone https://github.com/josejg/dotfiles.git .dotfiles
cd .dotfiles
./shell-setup.sh
./setup_all.sh

# NEOVIM - PlugInstall
/root/bin/nvim --headless +PlugInstall +qall
/root/bin/nvim --headless +"CocInstall -sync coc-explorer coc-git coc-highlight coc-pyright coc-json coc-sh coc-yaml" +qall
/root/bin/nvim --headless +CocUpdateSync +qall

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
