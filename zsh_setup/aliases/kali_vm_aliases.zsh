fnano() {
    local file
    if [ -f /etc/arch-release ]; then
        file=$(fzf --preview "bat --paging=never --color=always --style=plain {}") || return
    else
        file=$(fzf --preview "batcat --paging=never --color=always --style=plain {}") || return
    fi
    nano "$file"
}
alias upali="cp ~/REPOS/convenience/zsh_setup/aliases/kali_vm_aliases.zsh ~/.oh-my-zsh/custom/kali_vm_aliases.zsh;cp ~/REPOS/convenience/zsh_setup/aliases/kali_vm_project_aliases.zsh ~/.oh-my-zsh/custom/kali_vm_project_aliases.zsh;source ~/.zshrc"