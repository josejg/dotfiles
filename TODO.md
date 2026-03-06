# Dotfiles Modernization TODOs

## Hammerspoon cleanup (`mac/.hammerspoon/`)
- Audit which modules in init.lua are still loaded/used
- Likely stale: `zoom-mute.lua`, `cpm-backup.lua`, `pomo.lua`, `distractions.lua`, `multidisplay-black.lua`
- Likely active: `autoreload.lua`, `keyboard.lua`, `yabai.lua`, `windows.lua`
- Remove `.arch/` and `old/` archive directories
- Consider consolidating into fewer files
- Migrate audio device switching into Hammerspoon (replace deleted `next-audio-output`, `toggle-audio-output.sh`, `audiodevice` binary). Look into existing Hammerspoon audio device picker spoons or build a chooser-based UI picker.

## Unify setup scripts
- `setup_all.sh`, `shell-setup.sh`, `ubuntu-home.sh` overlap in purpose
- Goal: single entrypoint (e.g., `install.sh`) that detects OS and runs the right steps
- `install-neovim.sh` removed (using precompiled binaries now) — neovim install should be part of unified script
- `plug_vim.sh` removed (no longer using CoC) — neovim plugin install should use lazy.nvim or similar

## Stow layout for `latex/`
- Currently a flat directory (not stow-ready)
- Decide where templates/scripts should land (`~/.local/bin/`, `~/.local/share/latex_includes/`, etc.)
- Wire into `setup_all.sh` stow list
