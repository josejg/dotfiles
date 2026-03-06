# Dotfiles Modernization TODOs

## Hammerspoon cleanup (`mac/.hammerspoon/`)
- Audit which modules in init.lua are still loaded/used
- Likely stale: `zoom-mute.lua`, `cpm-backup.lua`, `pomo.lua`, `distractions.lua`, `multidisplay-black.lua`
- Likely active: `autoreload.lua`, `keyboard.lua`, `yabai.lua`, `windows.lua`
- Remove `.arch/` and `old/` archive directories
- Consider consolidating into fewer files

## Scripts cleanup (`scripts/bin/`)
- Audit ~50 scripts for active use
- Candidates for removal: media scripts (`mp43`, `to264`, `video-quality`, `tvshow`, `imguralbum.py`, `unsplash-sort`, `mkfavicon`), crypto (`enc-ssl`, `dec-ssl`), old utilities (`vmrun`, `mkvswap`, `epr`, `blankpage-pdf`, `check-docppt-pdf`), productivity (`pomo`, `pomol`, `quit-telegram`, `typewrite`, `draft`)
- Candidates to keep: `yaml-sort-as` (used by yd/vyd functions), `git-fire`, `nato`, `alert` (if hammerspoon stays), audio scripts (if still used)
- LaTeX scripts (`latex-init`, `latex-sep`, `clean_latex`, `latex_includes/`) — keep if still writing LaTeX

## Unify setup scripts
- `setup_all.sh`, `shell-setup.sh`, `ubuntu-home.sh` overlap in purpose
- Goal: single entrypoint (e.g., `install.sh`) that detects OS and runs the right steps
- `install-neovim.sh` removed (using precompiled binaries now) — neovim install should be part of unified script
- `plug_vim.sh` removed (no longer using CoC) — neovim plugin install should use lazy.nvim or similar
