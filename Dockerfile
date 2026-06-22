FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

ARG SYSTEM_USER=mrwest
ARG SYSTEM_PASSWORD=changeme
ARG SYSTEM_HOSTNAME=neverland

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

# Usuário principal
RUN groupadd ${SYSTEM_USER} && \
    useradd -m -s /bin/bash -g ${SYSTEM_USER} ${SYSTEM_USER} && \
    echo "${SYSTEM_USER}:${SYSTEM_PASSWORD}" | chpasswd && \
    usermod -aG sudo ${SYSTEM_USER}

ENV PATH="/usr/local/go/bin:/usr/local/cargo/bin:/home/${SYSTEM_USER}/.local/bin:/root/.local/bin:${PATH}"

RUN echo 'export PATH="/usr/local/go/bin:/usr/local/cargo/bin:/home/'"${SYSTEM_USER}"'/.local/bin:$PATH"' >> /home/${SYSTEM_USER}/.bashrc && \
    echo 'export TERM=xterm-256color' >> /home/${SYSTEM_USER}/.bashrc

# =========================================================
# Ferramentas OSINT
# =========================================================

USER ${SYSTEM_USER}

RUN pipx install maigret && \
    pipx install ghunt

# Ambiente Python dedicado
RUN python3 -m venv /home/${SYSTEM_USER}/.venvs/osint

RUN /home/${SYSTEM_USER}/.venvs/osint/bin/pip install --upgrade pip

RUN /home/${SYSTEM_USER}/.venvs/osint/bin/pip install \
    google-search-results \
    requests \
    ghunt

RUN echo 'alias osint-python="/home/'"${SYSTEM_USER}"'/.venvs/osint/bin/python3"' >> /home/${SYSTEM_USER}/.bashrc && \
    echo 'alias osint-pip="/home/'"${SYSTEM_USER}"'/.venvs/osint/bin/pip"' >> /home/${SYSTEM_USER}/.bashrc

USER root

RUN mkdir -p /var/run/sshd

# MOTD customizado
RUN chmod -x /etc/update-motd.d/* 2>/dev/null || true

COPY motd /etc/motd

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
