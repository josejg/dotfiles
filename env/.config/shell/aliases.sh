#!/usr/bin/env zsh
function alias_if_exists() {
    if command -v $2 > /dev/null; then
        alias "$1"="$2"
    fi
}


# Better defaults
alias crontab="VIM_CRONTAB=true crontab"
alias_if_exists 'diff' 'colordiff'
alias_if_exists 'vim' 'nvim'
alias_if_exists 'fdupes' 'jdupes'


# Shortcuts

## cd & ls
alias dc="cd"
if command -v eza > /dev/null; then
  alias ls=eza
  alias l="eza -1"
  alias la="eza -a"
fi
alias sl=ls

alias cf='cd $(fd -t d | fzf)'


## Git
alias ga='git add'
alias gs='git status'
alias gu='git pull'
alias gg='git graph'
alias gd='git diff'
alias gsu='git stash && git pull && git stash pop'
alias ghostscript="/usr/local/bin/gs"
alias gdt="git -c diff.external=difft diff"

## Jupyter
alias jc="jupyter console"
alias jco="jupyter nbconvert"
alias jn="jupyter notebook"
alias jn-b="jupyter notebook --no-browser"

# Youtube-DL
alias yt="yt-dlp"
alias yta="yt-dlp --extract-audio --audio-format mp3"
alias ytad="yt-dlp --extract-audio --audio-format mp3 --write-description --add-metadata --embed-thumbnail --write-info-json"
alias yt-dlp8="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4"
alias llmf="llm --model openrouter/google/gemma-3-27b-it:free"
alias gdl="gallery-dl"

## Misc
alias my-ip="curl ipinfo.io/ip 2> /dev/null"
alias sb='subl'
alias spell='aspell check --dont-backup'
alias printpath='echo $PATH | sed "s/:/\\n/g"'
alias sep='tput cols | python -c "import sys; print(\"=\"*int(sys.stdin.read().strip()))"'
alias clock='watch -n 0.1 "date +"%H:%M:%S" | toilet -f bigmono9"'
alias docker="DOCKER_BUILDKIT=1 docker"
alias tel="notifiers telegram notify"

## Ripgrep-all
if command -v rga > /dev/null; then
    alias rgim="rga --rga-adapters=+tesseract -j4"
fi


###########################################################################################################################

# OS dependent aliases
case "$(uname -s)" in

   Darwin)
     alias clear-dnscache="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
     alias bu="brew update && brew outdated | xargs brew upgrade  && brew cleanup -s --prune=0"

     alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome &"
     alias chromec="/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary &"

     alias mvf='mv "$(pfs)"' # Move current finder selection

     # MacOS GNUs
     for i in awk cat chgrp chmod chown chroot cut date df du echo egrep env false fgrep find grep join kill link ln logname make mkdir mknod mktemp mv nice nohup paste perf printf pwd readlink realpath rm rmdir sed sort split tac tail tar tee test touch tr true truncate tty uniq unlink unzip uptime users who whoami yes zip; do
       alias_if_exists "$i" "g$i"
     done
     alias_if_exists "id" "/usr/local/bin/gid"
     alias rm="/opt/homebrew/bin/grm -i"
     alias mv="/opt/homebrew/bin/gmv -i"
     alias cp="/opt/homebrew/bin/gcp -i"
     alias sudoedit="sudo -E vim"
     ;;

   Linux)
    alias sss='sudo systemctl status'
    alias ssd='sudo systemctl stop'
    alias ssu='sudo systemctl start'
    alias ssr='sudo systemctl restart'
    alias sj='sudo journalctl'
    alias agi='sudo apt install -y'
    alias svim='sudo -Es vim'
     ;;

esac
