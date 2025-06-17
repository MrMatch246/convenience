alias zshconfig="nano ~/.zshrc"

XSOCK="/tmp/.X11-unix"
XAUTH="/tmp/.docker.xauth"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

xhostUp() {
  nohup xhost +SI:localuser:root > /dev/null 2>&1
  if [ ! -f "$XAUTH" ]; then
    touch "$XAUTH"
    xauth nlist "$DISPLAY" | sed -e 's/^..../ffff/' | xauth -f "$XAUTH" nmerge -
    chmod 600 "$XAUTH"
  fi
}

xhostDown() {
  nohup xhost -SI:localuser:root > /dev/null 2>&1
}

guidocker() {
  xhostUp
  docker run -it \
    --net=host \
    --cap-drop=ALL \
    --cap-add=NET_ADMIN \
    --cap-add=NET_RAW \
    --cap-add=NET_BIND_SERVICE \
    --cap-add=SETGID \
    --cap-add=SETUID \
    --cap-add=SETFCAP \
    --cap-add=CHOWN \
    --cap-add=FOWNER \
    --cap-add=DAC_OVERRIDE \
    --device /dev/net/tun \
    -v "$XSOCK":"$XSOCK":ro \
    -v "$XAUTH":/root/.Xauthority:ro \
    -e DISPLAY="$DISPLAY" \
    -e XAUTHORITY=/root/.Xauthority \
    -v ~/Documents/Docker-Shared:/root/shared \
    --name $1 \
    --hostname $1 \
    $2 \
    zsh
  xhostDown
}
guikalinew() {
  guidocker $1 guikalicustom-image
}

guiDockerInteract() {
  xhostUp
  docker start -ai $1
  xhostDown
  nohup docker stop $1 > /dev/null 2>&1
}

guikali() {
  guiDockerInteract $1
}

fnano() {
    local file
    file=$(fzf --preview "cat {}") || return
    nano "$file"
}

alias gkali="guikali Kali-Gui"
alias gkalinew="guikalinew Kali-Gui"
alias upali="cp ~/REPOS/convenience/zsh_setup/aliases/host_aliases.zsh ~/.oh-my-zsh/custom/host_aliases.zsh;source ~/.zshrc"
alias docklist="docker ps -a --format 'table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}'"