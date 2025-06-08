#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ln -s "$SCRIPT_DIR/project.sh" /home/$(whoami)/.local/bin/project
chmod +x /home/$(whoami)/.local/bin/project
cp "$SCRIPT_DIR/project.zsh" /home/$(whoami)/.oh-my-zsh/custom/plugins/project/project.zsh
cp $SCRIPT_DIR/../../zsh_setup/aliases/project_aliases.zsh /home/$(whoami)/.oh-my-zsh/custom/project_aliases.zsh
