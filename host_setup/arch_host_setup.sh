#!/bin/bash
if [ "$EUID" -eq 0 ]; then
  echo "This script should not be run as root."
  exit 1
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm git zsh curl wget base-devel
# Install AUR helper (yay)
if ! command -v yay &> /dev/null; then
  git clone https://aur.archlinux.org/yay.git $HOME/yay
  cd $HOME/yay || exit
  makepkg -si --noconfirm
  cd $SCRIPT_DIR || exit
  rm -rf $HOME/yay
fi
# Install packages from AUR

su user -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended"
su root -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended"
git clone https://github.com/zsh-users/zsh-autosuggestions.git $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' /home/$(whoami)/.zshrc
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' /$(whoami)/.zshrc
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/g' /home/$(whoami)/.zshrc
sudo sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/g' /root/.zshrc
cp $SCRIPT_DIR/../zsh_setup/aliases/host_aliases.zsh /home/$(whoami)/.oh-my-zsh/custom/host_aliases.zsh
sudo cp $SCRIPT_DIR/../zsh_setup/aliases/host_aliases.zsh /root/.oh-my-zsh/custom/host_aliases.zsh