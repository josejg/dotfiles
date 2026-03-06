
# Environment & Aliases
for f in ~/.config/shell/*.sh; do
    [ -f "$f" ] && source "$f"
done

# Bash Prompt
PS1="\[\e]0;\u@\h: \W\a\]\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[00;36m\]\W\[\033[00m\]\$ "
PS1="\[\033[36m\][\[\033[m\]\[\033[34m\]\u@\h\[\033[m\] \[\033[32m\]\W\[\033[m\]\[\033[36m\]]\[\033[m\] $ "

# Tmuxinator completions
if [ -f ~/.bin/tmuxinator.bash ]; then
    source ~/.bin/tmuxinator.bash
fi


[ -f ~/.fzf.bash ] && source ~/.fzf.bash
HISTIGNORE="$HISTIGNORE:jrnl *"
export TERM=xterm-256color
