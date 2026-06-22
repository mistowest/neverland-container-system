FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

ARG SYSTEM_USER=mrwest
ARG SYSTEM_PASSWORD=changeme
ARG SYSTEM_HOSTNAME=neverland
# ---- Opcionais: defina no .env para espelhar o UID/GID do host (fix bind mount em ./data) ----
# Necessário em Linux. No Windows (Docker Desktop) não é preciso.
ARG SYSTEM_UID=
ARG SYSTEM_GID=

RUN echo "${SYSTEM_HOSTNAME}" > /etc/hostname

RUN apt-get update && apt-get install -y \
    sudo \
    openssh-server \
    curl \
    wget \
    nano \
    vim \
    git \
    unzip \
    zip \
    jq \
    whois \
    dnsutils \
    net-tools \
    build-essential \
    pkg-config \
    libssl-dev \
    ca-certificates \
    software-properties-common \
    kitty-terminfo \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    pipx \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://go.dev/dl/go1.23.4.linux-amd64.tar.gz -o /tmp/go.tar.gz && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz

ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
RUN chmod -R a+w /usr/local/rustup /usr/local/cargo

RUN apt-get update && apt-get install -y default-jdk && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y ruby-full && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y php php-cli && rm -rf /var/lib/apt/lists/*

# ---- Cria usuário ----
# Se SYSTEM_UID/SYSTEM_GID estiverem definidos, o usuário será criado com o mesmo
# UID/GID do host — necessário para escrita no bind mount de ./data em Linux.
# Se não estiverem definidos, o Docker escolhe os IDs automaticamente.
RUN groupadd ${SYSTEM_GID:+-g $SYSTEM_GID} ${SYSTEM_USER} && \
    useradd -m -s /bin/bash ${SYSTEM_UID:+-u $SYSTEM_UID} -g ${SYSTEM_USER} ${SYSTEM_USER} && \
    echo "${SYSTEM_USER}:${SYSTEM_PASSWORD}" | chpasswd && \
    usermod -aG sudo ${SYSTEM_USER}

ENV PATH="/usr/local/go/bin:/usr/local/cargo/bin:/home/${SYSTEM_USER}/.local/bin:/root/.local/bin:${PATH}"
RUN echo 'export PATH="/usr/local/go/bin:/usr/local/cargo/bin:/home/'"${SYSTEM_USER}"'/.local/bin:$PATH"' >> /home/${SYSTEM_USER}/.bashrc
RUN echo 'export TERM=xterm-256color' >> /home/${SYSTEM_USER}/.bashrc

# =========================================================
# ---- FERRAMENTAS OSINT (CLI, via pipx — usuário, não root) ----
# Estrutura aberta: adicione novas ferramentas CLI abaixo
# =========================================================
USER ${SYSTEM_USER}

RUN pipx install maigret && \
    pipx install ghunt
# RUN pipx install sherlock-project
# RUN pipx install holehe
# RUN pipx install theHarvester
# RUN pipx install socialscan

# =========================================================
# ---- VENV DEDICADO PARA LIBS PYTHON (não-CLI, ex: serpapi) ----
# Isolado do Python do sistema, sem --break-system-packages
# =========================================================
RUN python3 -m venv /home/${SYSTEM_USER}/.venvs/osint
RUN /home/${SYSTEM_USER}/.venvs/osint/bin/pip install --upgrade pip
RUN /home/${SYSTEM_USER}/.venvs/osint/bin/pip install \
    google-search-results \
    requests \
    ghunt

RUN echo 'alias osint-python="/home/'"${SYSTEM_USER}"'/.venvs/osint/bin/python3"' >> /home/${SYSTEM_USER}/.bashrc
RUN echo 'alias osint-pip="/home/'"${SYSTEM_USER}"'/.venvs/osint/bin/pip"' >> /home/${SYSTEM_USER}/.bashrc

USER root

# --- Via apt (ferramentas de sistema/rede) ---
# RUN apt-get update && apt-get install -y nmap recon-ng && rm -rf /var/lib/apt/lists/*

# --- Via git clone + instalação manual ---
# RUN git clone https://github.com/exemplo/ferramenta.git /opt/ferramenta && \
#     cd /opt/ferramenta && pip3 install -r requirements.txt

# =========================================================
RUN mkdir /var/run/sshd

# ---- MOTD customizado ----
RUN chmod -x /etc/update-motd.d/* 2>/dev/null || true
COPY motd /etc/motd

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
