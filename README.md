## JJGO's Dotfiles

My personal configuration files. They are designed for a ZSH + TMUX + NEOVIM stack.

- `./shell-setup.sh` – will bootstrap the shell environment including
  - [fzf](https://github.com/junegunn/fzf) - Fuzzy Search
  - [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy) - Better git diff
  - [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) - ZSH syntax highlight
  - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) - Fish-like autosuggestions
  - [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) - History search
  - [powerlevel10k](https://github.com/romkatv/powerlevel10k) - ZSH prompt
  - [neovim](https://github.com/neovim/neovim)
  - Rust CLI apps - [fd-find](https://github.com/sharkdp/fd), [ripgrep](https://github.com/BurntSushi/ripgrep), [tldr](https://github.com/dbrgn/tealdeer) and more

- `./setup_all.sh` - Will link dotfiles using `stow` (or python's `dploy`).
