#!/bin/bash
ENGAGEMENTS_DIR="$HOME/Documents/Engagements"
RUNNING_ENGAGEMENTS_DIR="$ENGAGEMENTS_DIR/Running"
ARCHIVED_ENGAGEMENTS_DIR="$ENGAGEMENTS_DIR/Archive"
CURRENT_FILE="$RUNNING_ENGAGEMENTS_DIR/.current_project"
XSOCK="/tmp/.X11-unix"
XAUTH="/tmp/.docker.xauth"
PENTEST_IMAGE="engage-kali"
FEATURES="/.features"

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
  if [ -z "$name" ]; then
    echo -e  "$WARN Please specify a project name."
    exit 1
  fi
  local container="${name}_$(date +%d-%m-%Y)"
  local folder="$RUNNING_ENGAGEMENTS_DIR/$container"

  mkdir -p "$folder"/{Scope,Admin,Deliverables,ProjectFiles,Evidence/{Findings,Scans/{Vuln,Service,Web,ADEnum},Notes,OSINT,Logs,Misc},Retest}
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
  touch "$folder$FEATURES"
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

get_current_container(){
  if [ -f "$CURRENT_FILE" ]; then
    cat "$CURRENT_FILE"
  else
    echo ""
  fi
}


enter_project() {
  local container="$1"

  # Check for current project
  local current_container=$(get_current_container)

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
    nohup docker stop "$current_container" > /dev/null 2>&1 & disown
    echo -e "$CHECKMARK Stopped project $current_container"
  fi

  # Start and enter the new container
  xhostUp
  docker start "$container" > /dev/null
  echo "$container" > "$CURRENT_FILE"
  docker exec -it "$container" zsh
}

exit_project() {
  local container=$(get_current_container)

  if [ -n "$container" ]; then
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
  sudo chown -R "$USER" "$folder"
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
    echo -e "$WARN Please specify a project name to remove."
    exit 1
  fi

  if [ -f "$CURRENT_FILE" ] && grep -q "^$container$" "$CURRENT_FILE"; then
    rm -f "$CURRENT_FILE"
  fi

  if ! docker ps -a --format '{{.Names}}' | grep -q "^$container$"; then
    echo -e "$WARN Project $container does not exist. Maybe you already removed it?"
    exit 1
  fi

  local folder="$RUNNING_ENGAGEMENTS_DIR/$container"
  local archived_flag="$folder/.archived"

  # Check if folder exists and is empty
  if [ -d "$folder" ] && [ -z "$(ls -A "$folder")" ]; then
    docker rm -f "$container" > /dev/null
    sudo rm -rf "$folder"
    echo -e "$CHECKMARK Removed empty project $container"
    return
  fi

  if [ ! -f "$archived_flag" ]; then
    echo -e "$WARN This project has not been archived. Are you sure you want to permanently remove it? (y/N)"
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo -e "$WARN Aborted removal of $container."
      exit 0
    fi
  fi

  docker rm -f "$container" > /dev/null

  if [ -d "$folder" ]; then
    sudo rm -rf "$folder"
  fi

  echo -e "$CHECKMARK Removed project $container"
}


add_feature() {
  local feature="$1"
  local container=$(get_current_container)
  if [ -z "$container" ]; then
    echo -e "$WARN No current project. Use: project switch <name>"
    exit 1
  fi
  case "$feature" in
    "mobsf") add_mobsf ;;
    *) echo -e "$WARN Unknown feature: $feature. Available features: mobsf" ;;
  esac

}

enter_feature() {
  local feature="$1"
  local container=$(get_current_container)
  if [ -z "$container" ]; then
    echo -e "$WARN No current project. Use: project switch <name>"
    exit 1
  fi
  case "$feature" in
    "mobsf") enter_mobsf ;;
    *) echo -e "$WARN Unknown feature: $feature. Available features: mobsf" ;;
  esac

}

add_to_feature_file(){
  if ! grep -Fxq "$1" "$2"; then
    echo "$1" >> "$2"
  fi
}


add_mobsf() {
  local container=$(get_current_container)
  if [ -z "$container" ]; then
    echo -e "$WARN No current project. Use: project switch <name>"
    exit 1
  fi
  local folder="$RUNNING_ENGAGEMENTS_DIR/$container"
  local mobsf="$folder/Features/MobSF"
  mkdir -p "$mobsf"
  sudo chown -R 9901:9901 "$mobsf"
  add_to_feature_file "mobsf" "$folder$FEATURES"
  docker pull opensecurity/mobile-security-framework-mobsf:latest
}

enter_mobsf(){
  local container=$(get_current_container)
  if [ -z "$container" ]; then
    echo -e "$WARN No current project. Use: project switch <name>"
    exit 1
  fi
  local feature_folder="$RUNNING_ENGAGEMENTS_DIR/$container/Features/MobSF"
  local features=$(cat "$RUNNING_ENGAGEMENTS_DIR/$container$FEATURES" 2>/dev/null || echo "")
  local
  if [[ ! "$features" =~ mobsf ]]; then
    echo -e "$WARN MobSF feature is not enabled for this project. Use: project addfeat mobsf"
    exit 1
  fi

  echo -e "$CHECKMARK Entering MobSF for project $container"
  echo -e "$YELLOW You can now access the MobSF web interface by opening http://127.0.0.1:8000 in your browser. Use the default login credentials: mobsf/mobsf.$RESET"
  docker run -it --rm --name mobsf \
  -p 8000:8000 -v "$feature_folder":/home/mobsf/.MobSF opensecurity/mobile-security-framework-mobsf:latest

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
  addfeat)  add_feature "$name" ;;
  enterfeat) enter_feature "$name" ;;
  #export)  export_project "$name" ;;
  exit)    exit_project ;;
  *)       usage ;;
esac
