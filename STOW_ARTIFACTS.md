# Stow Artifacts

Directories and files that were accidentally committed because stow symlinking
caused runtime state to appear inside the repo. A future install tool should
avoid creating these by symlinking individual files rather than entire
directories, or by using an allowlist approach.

## python/
- `.ipython/profile_default/db/` — IPython autorestore/dhist runtime database
- `.ipython/profile_default/log/` — IPython log files
- `.ipython/profile_default/pid/` — IPython pid files
- `.ipython/profile_default/security/` — IPython security tokens
- `.ipython/profile_default/startup/.ruff_cache/` — ruff lint cache
- `.ipython/profile_default/history.sqlite` — IPython command history
- `.mypy_cache/` — mypy type-checking cache
- `.matplotlib/fontList.json`, `.matplotlib/fontlist-v300.json` — matplotlib font cache

## vim/
- `.vim/plugged/` — vim-plug plugin downloads
- `.vim/undodir/` — persistent undo files
- `.vim/spell/` — spell files (downloaded at runtime)

## mac/
- `.config/karabiner/automatic_backups/` — karabiner auto-generated backups

## terminal/
- `.config/alacritty/themes/` — cloned theme repo
- `.config/alacritty/current-theme.toml` — generated symlink

## Lesson
When a stow package symlinks a parent directory (e.g., `~/.ipython` ->
`dotfiles/python/.ipython`), any runtime files written inside that directory
end up in the repo. The replacement tool should symlink leaf files or use
directory-level ignore rules.
