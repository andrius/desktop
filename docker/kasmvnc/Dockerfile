# Debian 13 Trixie Desktop with KasmVNC
# XFCE4 desktop with xfwm4 window manager
ARG DEBIAN_VERSION=trixie
FROM debian:${DEBIAN_VERSION}

LABEL maintainer="Desktop Docker Project"
LABEL description="Debian Trixie Desktop with XFCE4 and KasmVNC"
LABEL version="1.1.0"
LABEL vnc.type="kasmvnc"

# Build arguments
ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=1000
ARG DEBIAN_FRONTEND=noninteractive
ARG KASMVNC_VERSION=1.4.0
ARG TARGETARCH

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

# RUN 1: Install all system packages + minimal desktop + KasmVNC deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Init system and privilege drop
    tini \
    gosu \
    # Locales and utilities
    locales \
    sudo \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    apt-transport-https \
    git \
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
    # SSL for KasmVNC
    openssl \
    ssl-cert \
    # Xorg and utilities
    xorg \
    x11-xserver-utils \
    x11-utils \
    xauth \
    xdg-utils \
    xdg-user-dirs \
    # Mesa/OpenGL
    mesa-utils \
    libgl1-mesa-dri \
    libgl1 \
    libegl1 \
    libglu1-mesa \
    # Window manager (native XFCE window manager)
    xfwm4 \
    # XFCE4 components (selective - not full xfce4 metapackage)
    libxfce4ui-utils \
    xfce4-panel \
    xfce4-session \
    xfce4-settings \
    xfce4-terminal \
    xfconf \
    xfdesktop4 \
    # File manager (PCManFM for user-facing UI, Thunar for xfdesktop D-Bus service)
    pcmanfm \
    thunar \
    # Desktop utilities
    dbus-x11 \
    libglib2.0-bin \
    gvfs \
    # Fonts (minimal)
    fonts-dejavu-core \
    fonts-liberation \
    fontconfig \
    # Audio
    pulseaudio \
    pulseaudio-utils \
    libpulse0 \
    # Theme (single - adwaita only)
    adwaita-icon-theme \
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
    # Browser
    firefox-esr \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    # Remove unnecessary autostart items
    && rm -f /etc/xdg/autostart/xfce4-power-manager.desktop 2>/dev/null || true \
    && rm -f /etc/xdg/autostart/xscreensaver.desktop 2>/dev/null || true

# RUN 2: Configure locale + Install KasmVNC + Create user + Setup directories
# Re-declare TARGETARCH for this stage (provided by buildx)
ARG TARGETARCH
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen en_US.UTF-8 && \
    # Install KasmVNC (architecture auto-detected from buildx TARGETARCH)
    cd /tmp && \
    KASM_ARCH="${TARGETARCH:-amd64}" && \
    KASM_RELEASE="trixie" && \
    wget -q "https://github.com/kasmtech/KasmVNC/releases/download/v${KASMVNC_VERSION}/kasmvncserver_${KASM_RELEASE}_${KASMVNC_VERSION}_${KASM_ARCH}.deb" -O kasmvnc.deb && \
    apt-get update && \
    apt-get install -y ./kasmvnc.deb && \
    rm -f kasmvnc.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    # Create user with passwordless sudo
    groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME} && \
    # Create necessary directories
    mkdir -p /home/${USERNAME}/.config/xfce4 \
             /home/${USERNAME}/.local/share \
             /home/${USERNAME}/.cache \
             /home/${USERNAME}/.vnc \
             /home/${USERNAME}/Desktop \
             /home/${USERNAME}/Downloads \
             /home/${USERNAME}/Documents \
             /tmp/runtime-${USERNAME} && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} && \
    chmod 700 /tmp/runtime-${USERNAME}

# Copy scripts and plugins
COPY --chmod=755 scripts/ /opt/desktop/scripts/
COPY --chmod=755 configs/ /opt/desktop/configs/
COPY --chmod=755 plugins/ /opt/desktop/plugins/

# Ensure plugin directory structure
RUN mkdir -p /opt/desktop/plugins/.installed && \
    chown -R ${USERNAME}:${USERNAME} /opt/desktop

# Set working directory (use /home not /home/${USERNAME} — runtime USERNAME may differ)
WORKDIR /home

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
