#!/bin/bash

set -euo pipefail

USER_NAME="user"
USER_HOME="/home/$USER_NAME"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$USER_HOME/tmp"
OH_MY_ZSH_DIR="$USER_HOME/.oh-my-zsh"
ZSHRC="$USER_HOME/.zshrc"
PYENV_ROOT="$USER_HOME/.pyenv"
PYTHON_VERSION="3.12.9"
JYTHON_VERSION="2.7.4"
WSTG_CHECKLIST_URL="https://github.com/OWASP/wstg/raw/refs/heads/master/checklists/checklist.xlsx"

# === System packages ===
export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y \
  kali-linux-default \
  zsh \
  fonts-powerline \
  git \
  curl \
  nano \
  pyenv \
  tealdeer \
  feroxbuster \
  lnav \
  ca-certificates \
  python3-venv \
  pipx
apt clean

# === Set ownership for user if needed ===
chown -R $USER_NAME:$USER_NAME "$USER_HOME"

# === Install Oh My Zsh for user ===
if [ ! -d "$OH_MY_ZSH_DIR" ]; then
  sudo -u $USER_NAME sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# === Set ZSH theme and plugins ===
if [ ! -d "$OH_MY_ZSH_DIR/custom/plugins/zsh-autosuggestions" ]; then
  sudo -u $USER_NAME git clone https://github.com/zsh-users/zsh-autosuggestions.git $OH_MY_ZSH_DIR/custom/plugins/zsh-autosuggestions
  sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/g' "$ZSHRC"
fi
if [ ! -d "$OH_MY_ZSH_DIR/custom/plugins/zsh-syntax-highlighting" ]; then
  sudo -u $USER_NAME git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $OH_MY_ZSH_DIR/custom/plugins/zsh-syntax-highlighting
  sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' "$ZSHRC"
fi

# === Run Burp Suite Installer (if exists) ===
if [ -f "$TMP_DIR/burpsuite_pro_linux.sh" ]; then
  chmod +x "$TMP_DIR/burpsuite_pro_linux.sh"
  sudo -u $USER_NAME "$TMP_DIR/burpsuite_pro_linux.sh" -q
  rm -f "$TMP_DIR/burpsuite_pro_linux.sh"
fi

# === Run ZAP Installer (if exists) ===
if [ -f "$TMP_DIR/ZAP_unix.sh" ]; then
  chmod +x "$TMP_DIR/ZAP_unix.sh"
  sudo "$TMP_DIR/ZAP_unix.sh" -q
  rm -f "$TMP_DIR/ZAP_unix.sh"
fi

# === Jython ===
curl -L -o /opt/jython-standalone.jar \
  "https://repo1.maven.org/maven2/org/python/jython-standalone/${JYTHON_VERSION}/jython-standalone-${JYTHON_VERSION}.jar"

# === WSTG Checklist ===
mkdir -p "$TMP_DIR"
curl -L -o "$TMP_DIR/wstg_checklist.xlsx" "$WSTG_CHECKLIST_URL"
chown -R $USER_NAME:$USER_NAME "$TMP_DIR"

# === pipx ===
sudo -u $USER_NAME pipx ensurepath
sudo -u $USER_NAME pipx install arsenal-cli
#sudo -u $USER_NAME pipx install tldr

# === Install Argus ===
cd "$REPO_DIR/.."
sudo -u $USER_NAME bash -c "
git clone https://github.com/jasonxtn/argus.git &&
cd argus &&
python3 -m venv env &&
source env/bin/activate &&
pip install --upgrade pip &&
pip install -r requirements.txt &&
deactivate
"

# === Proxychains config update ===
#sed -i 's/^socks4[ \t]*127\.0\.0\.1[ \t]*9050$/socks5 127.0.0.1 9050/' /etc/proxychains4.conf

# === Clone convenience repo and apply configs ===
cp "$REPO_DIR/zsh_setup/aliases/kali_vm_aliases.zsh" "$OH_MY_ZSH_DIR/custom/kali_vm_aliases.zsh"
echo "source $REPO_DIR/zsh_setup/zsh_config/docker_zshrc" >> "$ZSHRC"

# === Install pyenv ===
sudo -u $USER_NAME bash -c "curl https://pyenv.run | bash"

# === Set up pyenv in .zshrc ===
echo 'export PYENV_ROOT="$HOME/.pyenv"'
