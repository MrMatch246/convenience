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
      nano \
      pyenv \
      lnav \
      ca-certificates && \
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
    rm -f /root/tmp/burpsuite_pro_linux.sh && \
    rm -rf /root/.cache

COPY ./docker_setup/kali_custom/tmp/ /root/tmp/
RUN chmod +x /root/tmp/ZAP_unix.sh && \
    /root/tmp/ZAP_unix.sh -q && \
    rm -f /root/tmp/ZAP_unix.sh && \
    rm -rf /root/.cache

# Set Jython version
ENV JYTHON_VERSION=2.7.4

# Download Jython standalone jar
RUN curl -L -o /opt/jython-standalone-${JYTHON_VERSION}.jar \
    https://repo1.maven.org/maven2/org/python/jython-standalone/${JYTHON_VERSION}/jython-standalone.jar

# Add Arsenal CLI
RUN pipx ensurepath && \
    pipx install arsenal-cli && \
    pipx install tldr



# Fix for Metasploit Framework
RUN apt -y purge llvm-18, llvm-19 && \
    apt autoremove && \
    apt clean

# Install Argus
WORKDIR /root/
RUN git clone https://github.com/jasonxtn/argus.git
WORKDIR /root/argus
RUN python3 -m venv env && \
    . ./env/bin/activate && \
    pip install --upgrade pip && \
    pip install -r requirements.txt

# Clone config repo
RUN git clone https://github.com/MrMatch246/convenience.git /root/convenience
# Add custom aliases
RUN cp /root/convenience/zsh_setup/aliases/docker_aliases.zsh /root/.oh-my-zsh/custom/docker_aliases.zsh
RUN echo "source /root/convenience/zsh_setup/zsh_config/docker_zshrc" >> /root/.zshrc

#Install Python3.12
ENV PYENV_ROOT="/root/.pyenv"

ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

RUN pyenv install 3.12.9 && pyenv global 3.12.9

RUN pipx install nettacker --python python3

RUN rm /root/.pyenv/version && \
    rm -rf /root/.cache \

ENV PATH="/root/.local/bin:$PATH"


WORKDIR /

# Set default shell
SHELL ["/bin/zsh", "-c"]
CMD ["zsh"]
