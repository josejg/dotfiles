#!/bin/zsh
set -e
export TERM=${TERM:-xterm-256color}

echo "=== Symlink check ==="
ERRORS=0
for f in ~/.zshrc ~/.zshenv ~/.zprofile ~/.zlogin ~/.p10k.zsh \
         ~/.config/shell/env.sh ~/.config/shell/aliases.sh ~/.config/shell/functions.sh \
         ~/.gitconfig ~/.bashrc ~/.bash_profile ~/.tmux.conf; do
  if [[ -L "$f" ]]; then
    target=$(readlink "$f")
    echo "  OK: $f -> $target"
  elif [[ -e "$f" ]]; then
    echo "  WARN: $f exists but is not a symlink"
    ((ERRORS++))
  else
    echo "  MISS: $f does not exist"
    ((ERRORS++))
  fi
done
[[ $ERRORS -eq 0 ]] && echo "All symlinks OK" || echo "$ERRORS issues found"

echo ""
echo "=== Plugins ==="
for p in \
  "$HOME/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" \
  "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "$HOME/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh" \
  "$HOME/.zsh/powerlevel10k/powerlevel10k.zsh-theme" \
  "$HOME/.zsh/zsh-completions/src" \
  "$HOME/.zsh/zsh-you-should-use/you-should-use.plugin.zsh" \
  "$HOME/.zsh/fzf-tab/fzf-tab.plugin.zsh" \
  "$HOME/.zsh/zsh-autopair/autopair.zsh" \
  "$HOME/.fzf.zsh"; do
  name=${p:t}
  [[ -f $p || -d $p ]] && echo "$name: OK" || echo "$name: MISSING"
done

echo ""
echo "=== Source zshrc ==="
source ~/.zshrc 2>&1 && echo "zshrc: OK" || echo "zshrc: FAILED"

echo ""
echo "=== Startup time ==="
time zsh -i -c exit
