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

# Enable raw socket/network bind capability for nmap
RUN setcap cap_net_raw,cap_net_bind_service+eip /usr/lib/nmap/nmap || true

# Run Custom Installers TODO: Add more installers here!!!
COPY ./docker_setup/kali_custom/tmp/ /root/tmp/
RUN chmod +x /root/tmp/burpsuite_pro_linux.sh && \
    /root/tmp/burpsuite_pro_linux.sh -q && \
    rm -rf /root/.cache

RUN chmod +x /root/tmp/ZAP_unix.sh && \
    /root/tmp/ZAP_unix.sh -q && \
    rm -rf /root/.cache


# Set Jython version
ENV JYTHON_VERSION=2.7.4

# Download Jython standalone jar
RUN curl -L -o /opt/jython-standalone-${JYTHON_VERSION}.jar \
    https://repo1.maven.org/maven2/org/python/jython-standalone/${JYTHON_VERSION}/jython-standalone.jar

# Fix for Metasploit Framework
RUN apt -y purge llvm-18 && \
    apt clean

# Clone config repo
RUN git clone https://github.com/MrMatch246/convenience.git /root/convenience
# Add custom aliases
RUN cp /root/convenience/zsh_setup/aliases/docker_aliases.zsh /root/.oh-my-zsh/custom/docker_aliases.zsh

# Set default shell
SHELL ["/bin/zsh", "-c"]
CMD ["zsh"]
