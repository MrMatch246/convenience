alias zshconfig="nano ~/.zshrc"
#alias gkalinew="docker run -it --net=host -e DISPLAY=$DISPLAY -e XAUTHORITY=/root/.Xauthority -v $HOME/.Xauthority:/root/.Xauthority -v /tmp/.X11-unix:/tmp/.X11-unix -v ~/Documents/Docker-Shared:/root/shared --name guikali kalilinux/kali-rolling bash"
alias kali="docker start kalihl;docker exec -it kalihl zsh;nohup docker stop kalihl > /dev/null 2>&1 & disown"
alias kalinew="docker run --name kalihl --tty --interactive kalilinux/kali-rolling"
xhostUp() {
  xhost +SI:localuser:root
}
xhostDown() {
  xhost -SI:localuser:root
}
guidocker() {
  xhostUp
  docker run -it \
    --net=host \
    -e DISPLAY=$DISPLAY \
    -e XAUTHORITY=/root/.Xauthority \
    -v $HOME/.Xauthority:/root/.Xauthority \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v ~/Documents/Docker-Shared:/root/shared \
    --name $1 \
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
  nohup docker stop $1 > /dev/null 2>&1 & disown
}

guiKaliInteract() {
  guiDockerInteract guikali
}

alias gkali="guiKaliInteract guikali"
alias gkalinew="guikalinew guikali"
