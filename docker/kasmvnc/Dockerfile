# Debian 13 Trixie Desktop with KasmVNC
# Based on the base desktop image, adds KasmVNC for web-based remote access
ARG DEBIAN_VERSION=trixie
FROM debian:${DEBIAN_VERSION}

LABEL maintainer="Desktop Docker Project"
LABEL description="Debian Trixie Desktop with XFCE4 and KasmVNC"
LABEL version="1.0.0"
LABEL vnc.type="kasmvnc"

# Build arguments
ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=1000
ARG DEBIAN_FRONTEND=noninteractive
ARG KASMVNC_VERSION=1.3.3

# Environment variables
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC \
    HOME=/home/${USERNAME} \
    USER=${USERNAME} \
    DISPLAY=:1 \
    XDG_RUNTIME_DIR=/tmp/runtime-${USERNAME}

# KasmVNC-specific environment
ENV VNC_PORT=5901 \
    VNC_WEB_PORT=6901 \
    VNC_RESOLUTION=1920x1080 \
    VNC_COL_DEPTH=24 \
    VNC_PW=vncpassword \
    VNC_VIEW_ONLY_PW= \
    KASM_SVC_AUDIO=1 \
    KASM_SVC_AUDIO_INPUT=1 \
    KASM_SVC_UPLOADS=1 \
    KASM_SVC_DOWNLOADS=1

# Install base system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Init system
    tini \
    dumb-init \
    # Locales and utilities
    locales \
    sudo \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    git \
    vim \
    nano \
    htop \
    procps \
    psmisc \
    net-tools \
    iputils-ping \
    dnsutils \
    unzip \
    zip \
    xz-utils \
    bzip2 \
    file \
    less \
    jq \
    # Build essentials for Homebrew
    build-essential \
    # SSL for KasmVNC
    openssl \
    ssl-cert \
    && rm -rf /var/lib/apt/lists/*

# Configure locales
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen en_US.UTF-8

# Install X11 and desktop environment
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Xorg and utilities
    xorg \
    x11-xserver-utils \
    x11-utils \
    x11-apps \
    xauth \
    xdg-utils \
    xdg-user-dirs \
    # Mesa/OpenGL
    mesa-utils \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    libegl1-mesa \
    libglu1-mesa \
    # XFCE4 desktop
    xfce4 \
    xfce4-terminal \
    xfce4-taskmanager \
    xfce4-screenshooter \
    xfce4-notifyd \
    xfce4-power-manager \
    xfce4-settings \
    xfce4-panel \
    thunar \
    thunar-archive-plugin \
    # Desktop utilities
    dbus-x11 \
    at-spi2-core \
    # Fonts
    fonts-dejavu-core \
    fonts-liberation \
    fonts-noto-core \
    fonts-noto-color-emoji \
    fontconfig \
    # Audio
    pulseaudio \
    pulseaudio-utils \
    libpulse0 \
    # Themes and icons
    adwaita-icon-theme \
    gnome-themes-extra \
    papirus-icon-theme \
    # KasmVNC dependencies
    libjpeg62-turbo \
    libpng16-16 \
    libwebp7 \
    libssl3 \
    libx11-6 \
    libxau6 \
    libxcursor1 \
    libxfixes3 \
    libxinerama1 \
    libxrandr2 \
    libxtst6 \
    x11-xkb-utils \
    xkb-data \
    && rm -rf /var/lib/apt/lists/*

# Install Firefox ESR
RUN apt-get update && apt-get install -y --no-install-recommends \
    firefox-esr \
    && rm -rf /var/lib/apt/lists/*

# Install KasmVNC
RUN cd /tmp && \
    KASM_ARCH="amd64" && \
    KASM_RELEASE="bookworm" && \
    wget -q "https://github.com/kasmtech/KasmVNC/releases/download/v${KASMVNC_VERSION}/kasmvncserver_${KASM_RELEASE}_${KASMVNC_VERSION}_${KASM_ARCH}.deb" -O kasmvnc.deb && \
    apt-get update && \
    apt-get install -y ./kasmvnc.deb && \
    rm -f kasmvnc.deb && \
    rm -rf /var/lib/apt/lists/*

# Create user with passwordless sudo
RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# Create necessary directories
RUN mkdir -p /home/${USERNAME}/.config/xfce4 \
             /home/${USERNAME}/.local/share \
             /home/${USERNAME}/.cache \
             /home/${USERNAME}/.vnc \
             /home/${USERNAME}/Desktop \
             /home/${USERNAME}/Downloads \
             /home/${USERNAME}/Documents \
             /tmp/runtime-${USERNAME} && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} && \
    chmod 700 /tmp/runtime-${USERNAME}

# Install Homebrew
USER ${USERNAME}
WORKDIR /home/${USERNAME}

RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
ENV HOMEBREW_NO_AUTO_UPDATE=1
ENV HOMEBREW_NO_ANALYTICS=1

# Configure shell for Homebrew
RUN echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/${USERNAME}/.bashrc && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/${USERNAME}/.profile

# Switch back to root for system configuration
USER root

# Copy scripts (base scripts should be copied to scripts/ directory before build)
# The GitHub workflow or build script handles copying base scripts
COPY --chmod=755 scripts/ /opt/desktop/scripts/
COPY --chmod=755 configs/ /opt/desktop/configs/

# Create plugin directory
RUN mkdir -p /opt/desktop/plugins && \
    chown -R ${USERNAME}:${USERNAME} /opt/desktop

# Expose ports
# 5901: VNC port
# 6901: KasmVNC web interface
EXPOSE 5901 6901

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -sf http://localhost:6901/ || exit 1

# Default entrypoint using tini
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/opt/desktop/scripts/entrypoint.sh"]
