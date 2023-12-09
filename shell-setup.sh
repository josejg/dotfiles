#!/usr/bin/env zsh
set -x
set -eu

#######################
# BIN
#######################

function pull_repo() {
    cd "$1"
    git pull
    cd -
}

mkdir -p "$HOME/bin"
cd "$HOME" 

# FASD
if [[ ! -f "$HOME/bin/fasd" ]]; then
    git clone https://github.com/clvv/fasd.git /tmp/fasd
    cd /tmp/fasd
    PREFIX=$HOME make install
    cd -
fi

# FZF
if [[ ! -f "$HOME/.fzf/bin/fzf" ]]; then
    git clone https://github.com/junegunn/fzf.git $HOME/.fzf
    yes | $HOME/.fzf/install
fi

# DIFF-SO-FANCY
if [[ ! -f "$HOME/bin/diff-so-fancy" ]]; then
    curl -o $HOME/bin/diff-so-fancy https://github.com/so-fancy/diff-so-fancy/releases/download/v1.4.4/diff-so-fancy
    chmod +x $HOME/bin/diff-so-fancy
fi


#######################
# TMUX
#######################

if [[ ! -d $HOME/.tmux/plugins/tpm ]]; then
    mkdir -p $HOME/.tmux/plugins
    git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
fi
pull_repo $HOME/.tmux/plugins/tpm


#######################
# ZSH
#######################

if [[ ! -d $HOME/.zprezto ]]; then
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

    if [[ -f ~/.zshrc ]]; then
        mv ~/.zshrc ~/.zshrc.bk
    fi

    if [[ -f ~/.zprofile ]]; then
        mv ~/.zprofile ~/.zprofile.bk
    fi

    setopt EXTENDED_GLOB
    for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
      ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
    done
fi
cd $HOME/.zprezto
git pull
git submodule update --init --recursive
cd - 

mkdir -p $HOME/.zsh

# Fast syntax highlighting
if [[ ! -d $HOME/.zsh/fast-syntax-highlighting ]]; then
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git $HOME/.zsh/fast-syntax-highlighting
fi
pull_repo $HOME/.zsh/fast-syntax-highlighting

#######################
# NEOVIM
#######################

NVIM=$HOME/.neovim
mkdir -p $NVIM

# AppImage in case the computer does not have a fallback nvim (appimage does not self update)
# AppImage does not work in Docker
# if command -v nvim > /dev/null; then
#     echo "NVIM appears to be installed"
# else
#     mkdir -p $NVIM/bin
#     cd $NVIM/bin
#     curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
#     chmod u+x nvim.appimage
#     mv nvim.appimage nvim
#     cd -
# fi

# Create Python3 environment
if [[ ! -d $NVIM/py3 ]]; then
    python3 -m venv $NVIM/py3
    $NVIM/py3/bin/pip install neovim 'python-language-server[all]' pylint isort jedi flake8 black yapf ruff
fi

# Create node env
if [[ ! -d $NVIM/node ]]; then
    mkdir -p $NVIM/node
    NODE_SCRIPT=/tmp/install-node.sh
    curl -sL install-node.now.sh/lts -o $NODE_SCRIPT
    chmod +x $NODE_SCRIPT
    PREFIX=$NVIM/node $NODE_SCRIPT -y
    PATH="$NVIM/node/bin:$PATH"
    npm install -g neovim
fi

#######################
# RUST
#######################

# if [[ ! -d $HOME/.rustup ]]; then
#     curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# fi

# for crate in bat fd-find ripgrep exa tealdeer procs ytop hyperfine bandwhich
# do
#     $HOME/.cargo/bin/cargo install $crate
# done
