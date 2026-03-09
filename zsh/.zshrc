# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ---------------------------------------------------------------------------
# Shell Options
# ---------------------------------------------------------------------------
setopt AUTO_CD              # cd by typing directory name
setopt EXTENDED_GLOB        # extended globbing (#, ~, ^)
setopt CORRECT              # command correction
setopt NO_BEEP              # no bell on error
setopt MULTIOS              # allow multiple redirections
setopt LONG_LIST_JOBS       # list jobs in long format

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------
export HISTFILE=~/.zsh_history
export HISTSIZE=100000
export SAVEHIST=100000
setopt EXTENDED_HISTORY       # record timestamp
setopt HIST_IGNORE_SPACE      # ignore commands starting with space
setopt HIST_IGNORE_ALL_DUPS   # remove older duplicate
setopt HIST_SAVE_NO_DUPS      # don't write duplicates
setopt HIST_FIND_NO_DUPS      # skip duplicates in search
setopt SHARE_HISTORY          # share history between sessions (implies INC_APPEND_HISTORY)

# ---------------------------------------------------------------------------
# Completion
# ---------------------------------------------------------------------------
# Extra completions (must be in fpath before compinit)
[[ -d $HOME/.zsh/zsh-completions/src ]] && fpath=($HOME/.zsh/zsh-completions/src $fpath)
fpath=(/usr/local/share/zsh-completions $fpath)

autoload -Uz compinit
# Rebuild compdump once per day
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Completion styles
zstyle ':completion:*' menu select                          # menu selection
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"     # colorized output
zstyle ':completion:*' group-name ''                        # group by category
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'

# SSH host completion from known_hosts and ssh config
zstyle -e ':completion:*:hosts' hosts 'reply=(
  ${=${=${=${${(f)"$(cat {/etc/ssh/ssh_,~/.ssh/}known_hosts(|2)(N) 2> /dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
  ${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2> /dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
)'
export COMP_KNOWN_HOSTS_WITH_HOSTFILE=""

# ---------------------------------------------------------------------------
# Editor / Keybindings
# ---------------------------------------------------------------------------
bindkey -e  # emacs keybindings

# Dot expansion: ... -> ../..
function expand-dot-to-parent-directory-path {
  if [[ $LBUFFER = *.. ]]; then
    LBUFFER+='/..'
  else
    LBUFFER+='.'
  fi
}
zle -N expand-dot-to-parent-directory-path
bindkey '.' expand-dot-to-parent-directory-path

# Remap clear-screen since ^L is taken by tmux-vim
bindkey "^O" clear-screen
bindkey "^L" end-of-line

# Alt left/right moves words
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word

# Alt up/down goes to beginning/end of line
bindkey "^[[1;3A" beginning-of-line
bindkey "^[[1;3B" end-of-line

# ---------------------------------------------------------------------------
# Terminal Title
# ---------------------------------------------------------------------------
function set-terminal-title-precmd {
  print -Pn "\e]0;%n@%m: %~\a"
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd set-terminal-title-precmd

# ---------------------------------------------------------------------------
# Plugins (sourced from ~/.zsh/)
# ---------------------------------------------------------------------------
# fzf-tab must be loaded after compinit but before autosuggestions/syntax-highlighting
if [[ -f $HOME/.zsh/fzf-tab/fzf-tab.plugin.zsh ]]; then
  source $HOME/.zsh/fzf-tab/fzf-tab.plugin.zsh
  # Preview for files/directories
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always $realpath'
  zstyle ':fzf-tab:complete:ls:*' fzf-preview 'ls --color=always $realpath'
  zstyle ':fzf-tab:*' fzf-min-height 20
fi

if [[ -f $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [[ -f $HOME/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]]; then
  source $HOME/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fi

if [[ -f $HOME/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
  source $HOME/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi

if [[ -f $HOME/.zsh/zsh-you-should-use/you-should-use.plugin.zsh ]]; then
  source $HOME/.zsh/zsh-you-should-use/you-should-use.plugin.zsh
fi

if [[ -f $HOME/.zsh/zsh-autopair/autopair.zsh ]]; then
  source $HOME/.zsh/zsh-autopair/autopair.zsh
  autopair-init
fi

# ---------------------------------------------------------------------------
# Sudo widget (Esc-Esc to toggle sudo prefix, from OMZ sudo plugin)
# ---------------------------------------------------------------------------
sudo-command-line() {
  [[ -z $BUFFER ]] && LBUFFER="$(fc -ln -1)"
  if [[ $BUFFER == sudo\ * ]]; then
    LBUFFER="${LBUFFER#sudo }"
  else
    LBUFFER="sudo $LBUFFER"
  fi
}
zle -N sudo-command-line
bindkey '\e\e' sudo-command-line

# ---------------------------------------------------------------------------
# Colored man pages (via LESS_TERMCAP)
# ---------------------------------------------------------------------------
export LESS_TERMCAP_mb=$'\e[1;31m'      # begin bold
export LESS_TERMCAP_md=$'\e[1;36m'      # begin blink (section headers)
export LESS_TERMCAP_me=$'\e[0m'         # end bold/blink
export LESS_TERMCAP_so=$'\e[01;44;33m'  # begin reverse (status line)
export LESS_TERMCAP_se=$'\e[0m'         # end reverse
export LESS_TERMCAP_us=$'\e[1;32m'      # begin underline
export LESS_TERMCAP_ue=$'\e[0m'         # end underline

# ---------------------------------------------------------------------------
# AI command suggestion (Ctrl+G) — requires `llm` CLI
# ---------------------------------------------------------------------------
if command -v llm > /dev/null; then
  ai-suggest() {
    local suggestion
    suggestion=$(llm -s "Convert to a shell command for $(uname). Output ONLY the command, nothing else." "$BUFFER" 2>/dev/null)
    if [[ -n $suggestion ]]; then
      BUFFER=$suggestion
      CURSOR=${#BUFFER}
    fi
  }
  zle -N ai-suggest
  bindkey '^G' ai-suggest
fi

# ---------------------------------------------------------------------------
# FZF
# ---------------------------------------------------------------------------
if command -v fzf &>/dev/null && fzf --zsh &>/dev/null; then
  eval "$(fzf --zsh)"
elif [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
fi

# ---------------------------------------------------------------------------
# Powerlevel10k
# ---------------------------------------------------------------------------
if [[ -f $HOME/.zsh/powerlevel10k/powerlevel10k.zsh-theme ]]; then
  source $HOME/.zsh/powerlevel10k/powerlevel10k.zsh-theme
fi
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# For env with run name
if [[ -f /tmp/runname ]]; then
  function prompt_context() {
    p10k segment -t "@ $(cat /tmp/runname)"
  }
fi

# ---------------------------------------------------------------------------
# Environment & Aliases
# ---------------------------------------------------------------------------
for f in ~/.config/shell/*.sh; do
  [[ -f "$f" ]] && source "$f"
done

# Zoxide
if command -v zoxide > /dev/null; then
  eval "$(zoxide init zsh)"
fi

# ---------------------------------------------------------------------------
# Optional: LM Studio, Bun
# ---------------------------------------------------------------------------
# LM Studio CLI
export PATH="$PATH:$HOME/.lmstudio/bin"

# Bun
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
