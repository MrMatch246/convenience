alias upali="git -C /root/convenience pull;cp /root/convenience/zsh_setup/aliases/docker_aliases.zsh /root/.oh-my-zsh/custom/docker_aliases.zsh;source ~/.zshrc"
alias zenmap="nohup zenmap > /dev/null 2>&1 & disown"
alias burpnp="nohup /opt/BurpSuitePro/BurpSuitePro --user-config-file=/root/tmp/no_proxy_burp_user_settings.json > /dev/null 2>&1 & disown"
alias burp="nohup /opt/BurpSuitePro/BurpSuitePro --user-config-file=/root/tmp/default_burp_user_settings.json > /dev/null 2>&1 & disown"
alias msf="service postgresql start;msfdb run"
alias zap="nohup zap.sh > /dev/null 2>&1 & disown"
alias cleanup='\
  echo "[*] Cleaning APT..." && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  echo "[*] Removing temp files..." && \
  rm -rf /tmp/* /var/tmp/* && \
  echo "[*] Truncating logs..." && \
  find /var/log -type f -exec truncate -s 0 {} \; && \
  echo "[*] Removing shell cache & history..." && \
  unset HISTFILE && \
  rm -f ~/.bash_history ~/.zsh_history && \
  history -c || true && \
  echo "[*] Removing Zsh comp dump and caches..." && \
  rm -rf ~/.zcompdump* ~/.cache && \
  echo "[✓] Docker cleanup complete."'
alias arse='arsenal'
alias argu='source /root/argus/env/bin/activate && python3 /root/argus/argus.py'
alias proxy='proxychains -q zsh'