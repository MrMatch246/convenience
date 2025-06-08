#!/bin/bash

BASE_DIR="$HOME/projects/engagements"
CURRENT_FILE="$BASE_DIR/.current_project"
XSOCK="/tmp/.X11-unix"
XAUTH="/tmp/.docker.xauth"
PENTEST_IMAGE="engage-kali"

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

run_project_docker() {
  xhostUp
  docker run -dit \
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
    "$PENTEST_IMAGE" \
    tail -f /dev/null
  xhostDown
}


usage() {
  echo "Usage:"
  echo "  project create <name>"
  echo "  project switch <name>"
  echo "  project enter [name]"
  echo "  project archive <name>"
  echo "  project remove <name>"
  echo "  project export <name>"
  echo "  project exit"
}

create_project() {
  local name="$1"
  local container="pt-$name-$(date +%d-%m-%Y)"
  local folder="$BASE_DIR/$container"

  mkdir -p "$folder"
  xhostUp
  docker run -dit \
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
      -v "$folder":/root/shared \
      --name "$container" \
      --hostname "$container" \
      "$PENTEST_IMAGE:latest" \
      tail -f /dev/null

  echo "[+] Created and started project $container"
}

switch_project() {
  local container="$1"

  if ! docker ps -a --format '{{.Names}}' | grep -q "^$container$"; then
    echo "[!] Project $container does not exist. Create it first."
    exit 1
  fi

  if [ -f "$CURRENT_FILE" ]; then
    local current_container=$(cat "$CURRENT_FILE")
    if [ "$current_container" == "$container" ]; then
      echo "[!] Already in project $container."
      exit 0
    fi
    nohup docker stop "$current_container" > /dev/null 2>&1
    echo "[✓] Stopped previous project $current_container"
  fi


  docker start "$container" > /dev/null
  echo "$container" > "$CURRENT_FILE"
  echo "[✓] Switched to project $container"
}

enter_project() {
  local container="$1"

  if [ -z "$container" ]; then
    if [ ! -f "$CURRENT_FILE" ]; then
      echo "[!] No current project. Use: project switch <name>"
      exit 1
    fi
    container=$(cat "$CURRENT_FILE")
  fi
  xhostUp
  docker exec -it "$container" zsh
}

exit_project() {
  local container
  if [ -f "$CURRENT_FILE" ]; then
    container=$(cat "$CURRENT_FILE")
    docker stop "$container" >/dev/null
    echo "[✓] Project $container exited."
    rm -f "$CURRENT_FILE"
  else
    echo "[!] No current project to exit."
  fi
  xhostDown
}

archive_project() {
  local container="$1"
  local folder="$BASE_DIR/$container"
  local archive="$BASE_DIR/${container}_archived_$(date +%d-%m-%Y).tar.gz"

  docker stop "$container" >/dev/null
  tar -czf "$archive" -C "$BASE_DIR" "$container"
  echo "[✓] Archived project container to $archive"
}

remove_project() {
  local container="$1"
  if ! docker ps -a --format '{{.Names}}' | grep -q "^$container$"; then
      echo "[!] Project $container does not exist. Maybe you already removed it?"
      exit 1
  else
    docker rm -f "$container" > /dev/null
    echo "[✓] Removed project $container"
  fi
}

export_project() {
  local name="$1"
  local export_file="$BASE_DIR/${name}_container_export.tar"

  docker export "pt-$name-$(date +%d-%m-%Y)" -o "$export_file"
  echo "[✓] Exported project container to $export_file"
}

### Main
cmd="$1"
name="$2"

case "$cmd" in
  create)  create_project "$name" ;;
  switch)  switch_project "$name" ;;
  enter)   enter_project "$name" ;;
  archive) archive_project "$name" ;;
  remove)  remove_project "$name" ;;
  export)  export_project "$name" ;;
  exit)    exit_project ;;
  *)       usage ;;
esac
