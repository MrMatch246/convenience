alias upali="cp /root/convenience/zsh_setup/aliases/docker_aliases.zsh /root/.oh-my-zsh/custom/docker_aliases.zsh;source ~/.zshrc"
alias zenmap="nohup zenmap > /dev/null 2>&1 & disown"
alias burp="nohup /opt/BurpSuitePro/BurpSuitePro --user-config-file ~/tmp/default_burp_user_settings.json > /dev/null 2>&1 & disown"
alias msf="service postgresql start;msfdb run"