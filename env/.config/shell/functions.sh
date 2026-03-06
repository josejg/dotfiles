# Shell functions
# Shell Agnostic. Should work both with bash and zsh


mvr() {
    # reverse mv
    mv $2 $1
}

gacp() {
    git add $@ && git commit -m fix && git push
}

gds() {
    git diff $@ | delta -s
}

# Rename terminal windows
#   $1 = type; 0 - both, 1 - tab, 2 - title
setTerminalText() {
    local mode=$1 ; shift
    echo -ne "\033]$mode;$@\007"
}
stt_both()  { setTerminalText 0 $@; }
stt_tab()   { setTerminalText 1 $@; }
stt_title() { setTerminalText 2 $@; }

tn() { stt_tab $@ && tmux new -s $@; }
ta() { stt_tab $@ && tmux a -t $@; }

sort-yaml() {
    yq -P 'sort_keys(..)' "$1"
}

diff-yaml() {
    diff -y <( yq -P 'sort_keys(..)' "$1") <( yq -P 'sort_keys(..)' "$2") | colordiff
}

vdiff-yaml() {
    yq -P 'sort_keys(..)' "$1" >! ".sorted_$1"
    yq -P 'sort_keys(..)' "$2" >! ".sorted_$2"
    nvim -d ".sorted_$1" ".sorted_$2"
    \rm ".sorted_$1" ".sorted_$2"
}

yd() {
    if [ $# -ne 2 ]; then
        echo "YAML diff - Usage: yd <file1> <file2>"
        return 1
    fi
    difft <(yaml-sort-as $1 $2) $2
}

vyd() {
    if [ $# -ne 2 ]; then
        echo "VIM YAML diff - Usage: vyd <file1> <file2>"
        return 1
    fi
    yaml-sort-as $1 $2 -o ".sorted_$1"
    nvim -d ".sorted_$1" $2
    \rm ".sorted_$1"
}

notify-complete() {
    pid=$1
    msg=$(ps -o cmd fp $pid | tail -n 1)
    tail --pid=$pid -f /dev/null && notifiers telegram notify "$msg"
}

res() { echo $1 && mediainfo $1 | grep -i height; }

# Find docker container address with a given name
daddr() {
    docker network ls | tail -n +2 | awk '{print $2}' | xargs docker network inspect | jq --arg NAME "$1" '.[].Containers | .[] | select(.Name == $NAME) | .IPv4Address'
}

shellfix() {
    shellcheck -f diff "$1" | git apply
}

# Separator + ripgrep (without shadowing the rg binary)
rgs() { printf '=%.0s' {1..${COLUMNS:-80}}; echo; rg "$@"; }


###########################################################################################################################

# fzf functions
if command -v fzf > /dev/null; then

  # fkill - kill process
  fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    if [ "x$pid" != "x" ]; then
      echo $pid | xargs kill -${1:-9}
    fi
  }

  v() {
    local file
    if [[ -f $1 ]]; then
        vim $1
    else
        file="$(fd -t f | fzf -1 -0 --query="$1" +m)" && vim "${file}" || return 1
    fi
  }

  fl() {
    less $(fzf)
  }

fi

## Ripgrep-all interactive
if command -v rga > /dev/null; then
    rga-fzf() {
        RG_PREFIX="rga --files-with-matches"
        local file
        file="$(
            FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'" \
                fzf --sort --preview="[[ ! -z {} ]] && rga --pretty --context 5 {q} {}" \
                    --phony -q "$1" \
                    --bind "change:reload:$RG_PREFIX {q}" \
                    --preview-window="70%:wrap"
        )" &&
        echo "opening $file" &&
        xdg-open "$file"
    }
fi


###########################################################################################################################

# OS dependent functions
case "$(uname -s)" in

   Darwin)
     op() {
       local file
       if [[ -f $1 ]]; then
           open $1
       else
           file="$(fd -t f | fzf -1 -0 --query="$1" +m)" && open "${file}" || return 1
       fi
     }
     ;;

   Linux)
    logs() {
        if [ -z "$1" ]; then
            echo "Usage: logs <service-name>"
            echo "Example: logs docker"
            return 1
        fi
        sudo journalctl -u "$1" -f
    }
     ;;

esac
