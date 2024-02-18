#!/usr/bin/env bash
PATH="/opt/homebrew/bin/:$PATH"
if [[ "$1" = "dark" ]]; then
    cd ~/.config/alacritty
    rm current-theme.toml
    touch alacritty.toml
    # npx alacritty-themes Tomorrow-Night
elif [[ "$1" = "light" ]]; then
    cd ~/.config/alacritty
    ln -sf themes/more_themes/Atelierdune.light.toml current-theme.toml
    touch alacritty.toml
    # npx alacritty-themes Atelierdune.light
fi

# rm /Users/j.gonzalez/.config/alacritty/alacritty.yml.*.bak

