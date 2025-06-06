FROM kalilinux/kali-rolling
LABEL maintainer="MrMatch246"

# Pre-install system packages
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
      kali-linux-default \
      zsh \
      fonts-powerline \
      git \
      curl \
      ca-certificates && \
    apt clean

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
      lnav && \
    apt clean

# Install Oh My Zsh (unattended)
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Set up ZSH theme and plugins
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/g' /root/.zshrc && \
    git clone https://github.com/zsh-users/zsh-autosuggestions.git /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' /root/.zshrc


# Clone config repo
RUN git clone https://github.com/MrMatch246/convenience.git /root/convenience
# Add custom aliases
RUN cp /root/convenience/zsh_setup/aliases/docker_aliases.zsh /root/.oh-my-zsh/custom/docker_aliases.zsh


# Enable raw socket/network bind capability for nmap
RUN setcap cap_net_raw,cap_net_bind_service+eip /usr/lib/nmap/nmap || true

# Set default shell
SHELL ["/bin/zsh", "-c"]
CMD ["zsh"]
