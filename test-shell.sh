#!/bin/zsh
set -e
export TERM=${TERM:-xterm-256color}
export PATH="$HOME/.local/bin:$PATH"

FAIL=0
pass() { echo "  OK: $1"; }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Symlink check ==="
for f in ~/.zshrc ~/.zshenv ~/.zprofile ~/.zlogin ~/.p10k.zsh \
         ~/.config/shell/env.sh ~/.config/shell/aliases.sh ~/.config/shell/functions.sh \
         ~/.gitconfig ~/.bashrc ~/.bash_profile ~/.tmux.conf; do
  if [[ -L "$f" ]]; then
    pass "$f -> $(readlink "$f")"
  elif [[ -e "$f" ]]; then
    fail "$f exists but is not a symlink"
  else
    fail "$f does not exist"
  fi
done

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
  "$HOME/.zsh/zsh-defer/zsh-defer.plugin.zsh"; do
  name=${p:t}
  [[ -f $p || -d $p ]] && pass "$name" || fail "$name MISSING"
done

echo ""
echo "=== Binary tools (--version) ==="
typeset -A version_flags=(
  [fzf]="--version"
  [delta]="--version"
  [fd]="--version"
  [rg]="--version"
  [difft]="--version"
  [lazygit]="--version"
  [zoxide]="--version"
  [eza]="--version"
  [bat]="--version"
  [nvim]="--version"
  [jq]="--version"
  [gh]="--version"
  [uv]="--version"
  [node]="--version"
  [ruff]="--version"
  [yamllint]="--version"
)
for cmd flag in "${(@kv)version_flags}"; do
  if command -v "$cmd" &>/dev/null; then
    ver=$("$cmd" "$flag" 2>&1 | head -1)
    pass "$cmd: $ver"
  else
    fail "$cmd: not found"
  fi
done

echo ""
echo "=== Source zshrc ==="
source ~/.zshrc 2>&1 && pass "zshrc sourced" || fail "zshrc source failed"

echo ""
echo "=== Startup time (zsh) ==="
time zsh -i -c exit

echo ""
echo "=== Startup time (nvim) ==="
if command -v nvim &>/dev/null; then
  time nvim --headless +qa
else
  fail "nvim not found, skipping startup test"
fi

echo ""
if [[ $FAIL -gt 0 ]]; then
  echo "RESULT: $FAIL failures"
  exit 1
else
  echo "RESULT: all checks passed"
fi
