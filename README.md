## JJGO's Dotfiles

Personal configuration files for a **ZSH + TMUX + Neovim** stack on macOS and Linux.

Managed with [GNU Stow](https://www.gnu.org/software/stow/) -- each top-level directory is a stow package that symlinks into `$HOME`.

### Stow packages

| Package | Contents |
|---------|----------|
| `bash` | `.bashrc`, `.bash_profile`, `.bash_logout` |
| `env` | `~/.config/shell/{env,aliases,functions}.sh` -- shared shell config sourced by both zsh and bash |
| `git` | `.gitconfig` -- delta pager, histogram diff, rerere, zdiff3 |
| `latex` | LaTeX template system (`latex-init`, `clean-latex`, `md2list`) |
| `mac` | macOS-specific: Alacritty, Karabiner, yabai, Hammerspoon |
| `python` | IPython, matplotlib, ruff, pyright configs |
| `scripts` | Utility scripts in `~/.local/bin/` |
| `terminal` | Kitty config |
| `tmux` | `.tmux.conf` + TPM plugins |
| `vim` | Neovim / Vim configuration |
| `zsh` | Hand-rolled zsh config (8 plugins, compinit, keybindings, p10k) |

### Setup

```bash
# 1. Bootstrap shell tooling (fzf, delta, zsh plugins, tmux TPM, etc.)
./shell-setup.sh

# 2. Symlink dotfiles into $HOME
./setup_all.sh
```

### Key tools

- [delta](https://github.com/dandavison/delta) -- git pager
- [fzf](https://github.com/junegunn/fzf) -- fuzzy finder
- [zoxide](https://github.com/ajeetdsouza/zoxide) -- smarter cd
- [eza](https://github.com/eza-community/eza) -- modern ls
- [ripgrep](https://github.com/BurntSushi/ripgrep) -- fast grep
- [fd](https://github.com/sharkdp/fd) -- fast find
- [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) -- zsh syntax highlight
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) -- fish-like autosuggestions
- [powerlevel10k](https://github.com/romkatv/powerlevel10k) -- zsh prompt

### Docker testing

```bash
docker compose build --no-cache && docker compose run --rm shell
```
