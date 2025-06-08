#!/bin/bash
ENGAGEMENTS_DIR="$HOME/Documents/Engagements"
RUNNING_ENGAGEMENTS_DIR="$ENGAGEMENTS_DIR/Running"
ARCHIVED_ENGAGEMENTS_DIR="$ENGAGEMENTS_DIR/Archive"
CURRENT_FILE="$RUNNING_ENGAGEMENTS_DIR/.current_project"
XSOCK="/tmp/.X11-unix"
XAUTH="/tmp/.docker.xauth"
PENTEST_IMAGE="engage-kali"

GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
RESET="\033[0m"

CHECKMARK="[${GREEN}✓${RESET}]"
ADD="[${BLUE}+${RESET}]"
WARN="[${RED}!${RESET}]"



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

usage() {
  echo -e  "Usage:"
  echo -e  "  project create <name>"
  echo -e  "  project enter [name]"
  echo -e  "  project switch <name>"
  echo -e  "  project archive <name>"
  echo -e  "  project remove <name>"
  #echo -e  "  project export <name>"
  echo -e  "  project exit"
}

create_project() {
  local name="$1"
  local container="${name}_$(date +%d-%m-%Y)_Pentest"
  local folder="$RUNNING_ENGAGEMENTS_DIR/$container"

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
      --hostname "$name" \
      "$PENTEST_IMAGE:latest" \
      tail -f /dev/null

  echo -e  "$ADD Created and started project $container"
  if [ ! -f "$CURRENT_FILE" ]; then
    echo -e  "$container" > "$CURRENT_FILE"
    echo -e  "$CHECKMARK Set current project to $container"
  fi
}

switch_project() {
  local container="$1"
  if [ -z "$container" ]; then
    echo -e  "$WARN Please specify a project name to switch to."
    exit 1
  fi
  if ! docker ps -a --format '{{.Names}}' | grep -q "^$container$"; then
    echo -e  "$WARN Project $container does not exist. Create it first."
    exit 1
  fi

  if [ -f "$CURRENT_FILE" ]; then
    local current_container=$(cat "$CURRENT_FILE")
    if [ "$current_container" == "$container" ]; then
      echo -e  "$WARN Already in project $container."
      exit 0
    fi
    nohup docker stop "$current_container" > /dev/null 2>&1
    echo -e  "$CHECKMARK Stopped previous project $current_container"
  fi


  docker start "$container" > /dev/null
  echo -e  "$container" > "$CURRENT_FILE"
  echo -e  "$CHECKMARK Switched to project $container"
}

enter_project() {
  local container="$1"

  # Check for current project
  if [ -f "$CURRENT_FILE" ]; then
    local current_container
    current_container=$(cat "$CURRENT_FILE")
  else
    current_container=""
  fi

  # If no container was passed, default to current
  if [ -z "$container" ]; then
    if [ -z "$current_container" ]; then
      echo -e "$WARN No current project. Use: project switch <name>"
      exit 1
    fi
    container="$current_container"
  fi

  # If switching to a different container, prompt the user
  if [ -n "$current_container" ] && [ "$current_container" != "$container" ]; then
    echo -e "$WARN You are currently in project '$current_container'."
    echo -e "[?] Entering '$container' will stop '$current_container'. Are you sure? (y/N)"
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo -e "$INFO Aborted switching to $container."
      exit 0
    fi
    nohup docker stop "$current_container" > /dev/null 2>&1
    echo -e "$CHECKMARK Stopped project $current_container"
  fi

  # Start and enter the new container
  docker start "$container" > /dev/null
  echo "$container" > "$CURRENT_FILE"
  xhostUp
  docker exec -it "$container" zsh
}

exit_project() {
  local container
  if [ -f "$CURRENT_FILE" ]; then
    container=$(cat "$CURRENT_FILE")
    docker stop "$container" >/dev/null
    echo -e  "$CHECKMARK Project $container exited."
    rm -f "$CURRENT_FILE"
  else
    echo -e  "$WARN No current project to exit."
  fi
  xhostDown
}

archive_project() {
  local container="$1"
  local folder="$RUNNING_ENGAGEMENTS_DIR/$container"
  local archive_dir="$ARCHIVED_ENGAGEMENTS_DIR"
  local archive="$archive_dir/${container}_archived_$(date +%d-%m-%Y).tar.gz"

  # Ensure archive directory exists
  mkdir -p "$archive_dir"

  # Stop the container
  docker stop "$container" >/dev/null

  # Archive the folder
  if tar -czf "$archive" -C "$RUNNING_ENGAGEMENTS_DIR" "$container"; then
    echo -e "$CHECKMARK Archived project container to $archive"
    touch "$folder/.archived"
  else
    echo -e "$ERROR Failed to archive project container."
    return 1
  fi
}


remove_project() {
  local container="$1"
  if [ -z "$container" ]; then
    echo -e  "$WARN Please specify a project name to remove."
    exit 1
  fi

  if [ -f "$CURRENT_FILE" ] && grep -q "^$container$" "$CURRENT_FILE"; then
    rm -f "$CURRENT_FILE"
  fi

  if ! docker ps -a --format '{{.Names}}' | grep -q "^$container$"; then
    echo -e  "$WARN Project $container does not exist. Maybe you already removed it?"
    exit 1
  fi

  local folder="$RUNNING_ENGAGEMENTS_DIR/$container"
  local archived_flag="$folder/.archived"

  if [ ! -f "$archived_flag" ]; then
    echo -e  "$WARN This project has not been archived. Are you sure you want to permanently remove it? (y/N)"
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo -e  "$WARN Aborted removal of $container."
      exit 0
    fi
  fi

  docker rm -f "$container" > /dev/null

  if [ -d "$folder" ]; then
    rm -rf "$folder"
  fi

  echo -e "$CHECKMARK Removed project $container"
}

export_project() {
  #local container="$1"
  #local export_file="$RUNNING_ENGAGEMENTS_DIR/${container}_exported_$(date +%d-%m-%Y).tar"
  #docker export "$container" -o "$export_file"
  #echo -e  "$CHECKMARK Exported project container to $export_file"
  echo -e  "$WARN Export functionality is not implemented yet."
}

### Main
cmd="$1"
name="$2"

case "$cmd" in
  create)  create_project "$name" ;;
  enter)   enter_project "$name" ;;
  switch)  switch_project "$name" ;;
  archive) archive_project "$name" ;;
  remove)  remove_project "$name" ;;
  #export)  export_project "$name" ;;
  exit)    exit_project ;;
  *)       usage ;;
esac
