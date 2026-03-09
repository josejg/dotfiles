
# Environment & Aliases
for f in ~/.config/shell/*.sh; do
    [ -f "$f" ] && source "$f"
done

# Bash Prompt
PS1="\[\033[36m\][\[\033[m\]\[\033[34m\]\u@\h\[\033[m\] \[\033[32m\]\W\[\033[m\]\[\033[36m\]]\[\033[m\] $ "

# Zoxide
if command -v zoxide > /dev/null; then
    eval "$(zoxide init bash)"
fi

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
HISTIGNORE="$HISTIGNORE:jrnl *"
