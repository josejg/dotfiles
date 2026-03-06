#!/usr/bin/env bash
PATH="/opt/homebrew/bin/:$PATH"
if [[ "$1" = "dark" ]]; then
    cd "$HOME/.config/alacritty" || exit 1
    rm current-theme.toml
    touch alacritty.toml
    # npx alacritty-themes Tomorrow-Night
elif [[ "$1" = "light" ]]; then
    cd "$HOME/.config/alacritty" || exit 1
    ln -sf themes/more_themes/Atelierdune.light.toml current-theme.toml
    touch alacritty.toml
    # npx alacritty-themes Atelierdune.light
fi

# rm /Users/j.gonzalez/.config/alacritty/alacritty.yml.*.bak

