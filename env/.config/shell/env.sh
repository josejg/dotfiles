# Environment Setup
# Shell Agnostic. Should work both with bash and zsh


###########################################################################################################################

# PATH

function prepend_path() {
    if [ -d "$1" ]; then
        export PATH="$1:$PATH"
    fi
}

function append_path() {
    if [ -d "$1" ]; then
        export PATH="$PATH:$1"
    fi
}

prepend_path "/usr/local/bin"
prepend_path "/usr/local/sbin"
prepend_path "$HOME/bin"           # Custom scripts
prepend_path "$HOME/.secbin"       # Secret custom scripts
prepend_path "$HOME/.local/bin"
prepend_path "$HOME/.local/bin/host"  # Machine-specific scripts (not managed by stow)
prepend_path "/usr/local/opt/ruby/bin"
append_path "$HOME/.emacs.d/bin"
prepend_path "/opt/homebrew/bin"


###########################################################################################################################

# PYTHON

# set PYTHONPATH for local user packages
export PYTHONPATH="$HOME/python-libs:$PYTHONPATH"


###########################################################################################################################

# Rust bins on PATH (lazy-load thunks are in .zshrc)
prepend_path "$HOME/.cargo/bin"


###########################################################################################################################

# DEFAULT PROGRAMS

# Browser (macOS only)
if [[ "$(uname -s)" == "Darwin" ]]; then
    export BROWSER='open'
fi

# Editors
if command -v nvim > /dev/null 2>&1; then
    export EDITOR='nvim'
    export VISUAL='nvim'
else
    export EDITOR='vim'
    export VISUAL='vim'
fi

# Pager
export PAGER='less'
export LESS='-F -g -i -M -R -S -w -z-4'

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
