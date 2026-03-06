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
setopt SHARE_HISTORY          # share history between sessions
setopt INC_APPEND_HISTORY     # write immediately, not on exit

# ---------------------------------------------------------------------------
# Completion
# ---------------------------------------------------------------------------
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

fpath=(/usr/local/share/zsh-completions $fpath)
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
if [[ -f $HOME/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]]; then
  source $HOME/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fi

if [[ -f $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [[ -f $HOME/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
  source $HOME/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi

# ---------------------------------------------------------------------------
# FZF
# ---------------------------------------------------------------------------
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

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
if [[ -f ~/.common ]]; then
  source ~/.common
fi

if [[ -f ~/.aliases ]]; then
  source ~/.aliases
fi

# Tmuxinator completions
if [[ -f ~/.bin/tmuxinator.zsh ]]; then
  source ~/.bin/tmuxinator.zsh
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
