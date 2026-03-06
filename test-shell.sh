#!/bin/zsh
set -e

echo "=== Stow check ==="
ls -la ~/.zshrc ~/.zprofile ~/.zshenv ~/.zlogin ~/.common ~/.aliases ~/.p10k.zsh

echo ""
echo "=== Plugins ==="
for p in \
  "$HOME/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" \
  "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "$HOME/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh" \
  "$HOME/.zsh/powerlevel10k/powerlevel10k.zsh-theme" \
  "$HOME/.fzf.zsh"; do
  name=${p:t}
  [[ -f $p ]] && echo "$name: OK" || echo "$name: MISSING"
done

echo ""
echo "=== Source zshrc ==="
source ~/.zshrc 2>&1 && echo "zshrc: OK" || echo "zshrc: FAILED"

echo ""
echo "=== Startup time ==="
time zsh -i -c exit
