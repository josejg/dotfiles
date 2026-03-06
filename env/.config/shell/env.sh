# Environment Setup
# Shell Agnostic. Should work both with bash and zsh


###########################################################################################################################

# PATH

function prepend_path() {
    if [ -d $1 ]; then
        export PATH="$1:$PATH"
    fi
}

function append_path() {
    if [ -d $1 ]; then
        export PATH="$PATH:$1"
    fi
}

prepend_path "/usr/local/bin"
prepend_path "/usr/local/sbin"
prepend_path "$HOME/bin"           # Custom scripts
prepend_path "$HOME/.secbin"       # Secret custom scripts
prepend_path "$HOME/.local/bin"
prepend_path "/usr/local/opt/ruby/bin"
prepend_path "$HOME/.neovim/bin"
append_path "$HOME/.neovim/node/bin"
append_path "$HOME/.emacs.d/bin"
append_path "/opt/homebrew/bin"

here() {
    local loc
    if [ "$#" -eq 1 ]; then
        loc=$(realpath "$1")
    else
        loc=$(realpath ".")
    fi
    ln -sfn "${loc}" "$HOME/.shell.here"
    echo "here -> $(readlink $HOME/.shell.here)"
}

there="$HOME/.shell.here"

there() {
    cd "$(readlink "${there}")"
}


###########################################################################################################################

# PYTHON

# set PYTHONPATH for local user packages
export PYTHONPATH="$HOME/python-libs:$PYTHONPATH"


###########################################################################################################################

# Lazy-load cargo/rust
if [[ -f "$HOME/.cargo/env" ]]; then
    cargo()  { unfunction cargo rustc rustup 2>/dev/null; unset -f cargo rustc rustup 2>/dev/null; source "$HOME/.cargo/env"; cargo "$@"; }
    rustc()  { unfunction cargo rustc rustup 2>/dev/null; unset -f cargo rustc rustup 2>/dev/null; source "$HOME/.cargo/env"; rustc "$@"; }
    rustup() { unfunction cargo rustc rustup 2>/dev/null; unset -f cargo rustc rustup 2>/dev/null; source "$HOME/.cargo/env"; rustup "$@"; }
fi

# Rust bins still need to be on PATH for non-cargo tools
prepend_path "$HOME/.cargo/bin"


###########################################################################################################################

# DEFAULT PROGRAMS

# Browser (macOS only)
if [[ "$(uname -s)" == "Darwin" ]]; then
    export BROWSER='open'
fi

# Editors
export EDITOR='vim'
export VISUAL='vim'

# Pager
export PAGER='less'
export LESS='-F -g -i -M -R -S -w -X -z-4'

# lesspipe
if command -v lesspipe > /dev/null 2>&1; then
    export LESSOPEN="| /usr/bin/env lesspipe %s 2>&-"
elif command -v lesspipe.sh > /dev/null 2>&1; then
    export LESSOPEN="| /usr/bin/env lesspipe.sh %s 2>&-"
fi

# CLI colors
export CLICOLOR=1
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx

# Language
if [[ -z "$LANG" ]]; then
    export LANGUAGE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
fi


###########################################################################################################################

# Misc Software

# Zoxide init
if command -v zoxide > /dev/null; then
    eval "$(zoxide init zsh)"
    cd() { builtin cd "$@" 2>/dev/null || z "$@" }
fi

# Ansible
export ANSIBLE_NOCOWS=1

export ET_NO_TELEMETRY=1


###########################################################################################################################

# Ring
if [ -f ~/.ring ]; then
    source ~/.ring
fi

# LOCAL ENV
if [ -f ~/.local-env ]; then
    source ~/.local-env
fi
