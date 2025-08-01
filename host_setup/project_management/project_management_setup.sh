#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Setting up project management tools..."
LINE='export PATH="$PATH:/home/$USER/.local/bin"'
ZSHRC="$HOME/.zshrc"
mkdir -p /home/$(whoami)/.local/bin
ln -sf "$SCRIPT_DIR/project.sh" /home/$(whoami)/.local/bin/project
chmod +x /home/$(whoami)/.local/bin/project
cp $SCRIPT_DIR/../../zsh_setup/aliases/project_aliases.zsh /home/$(whoami)/.oh-my-zsh/custom/project_aliases.zsh
if ! grep -Fxq "$LINE" "$ZSHRC"; then
  echo "$LINE" >> "$ZSHRC"
fi