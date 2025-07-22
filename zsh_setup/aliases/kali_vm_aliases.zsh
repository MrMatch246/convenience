fnano() {
    local file
    if [ -f /etc/arch-release ]; then
        file=$(fzf --preview "bat --paging=never --color=always --style=plain {}") || return
    else
        file=$(fzf --preview "batcat --paging=never --color=always --style=plain {}") || return
    fi
    nano "$file"
}
alias upali="git -C ~/REPOS/convenience pull;cp ~/REPOS/convenience/zsh_setup/aliases/kali_vm_aliases.zsh ~/.oh-my-zsh/custom/kali_vm_aliases.zsh;cp ~/REPOS/convenience/zsh_setup/aliases/kali_vm_project_aliases.zsh ~/.oh-my-zsh/custom/kali_vm_project_aliases.zsh;source ~/.zshrc"
alias msf="sudo service postgresql start;sudo msfdb run"
alias burp="nohup /opt/BurpSuitePro/BurpSuitePro --user-config-file=~/tmp/default_burp_user_settings.json > /dev/null 2>&1 & disown"
alias zap="nohup zap.sh > /dev/null 2>&1 & disown"
alias arse='arsenal'
alias argu='source ~/REPOS/argus/env/bin/activate && python3 ~/REPOS/argus/argus.py'
alias legion='sudo ~/REPOS/legion/startLegion.sh'