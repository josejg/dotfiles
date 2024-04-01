set -euo pipefail
nvim --headless +PlugInstall +qall
nvim --headless +"CocInstall -sync coc-explorer coc-git coc-highlight coc-pyright coc-json coc-sh coc-yaml" +qall
nvim --headless +CocUpdateSync +qall
