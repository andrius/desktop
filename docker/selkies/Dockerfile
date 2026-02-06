# Debian 13 Trixie Desktop with Selkies GStreamer WebRTC
# Based on the base desktop image, adds Selkies for web-based remote access
ARG BASE_IMAGE=debian-desktop:base
ARG DEBIAN_VERSION=trixie
FROM debian:${DEBIAN_VERSION}

LABEL maintainer="Desktop Docker Project"
LABEL description="Debian Trixie Desktop with XFCE4 and Selkies WebRTC"
LABEL version="1.0.0"
LABEL vnc.type="selkies"

# Build arguments
ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=1000
ARG DEBIAN_FRONTEND=noninteractive
ARG SELKIES_VERSION=latest

# Environment variables
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC \
    HOME=/home/${USERNAME} \
    USER=${USERNAME} \
    DISPLAY=:0 \
    XDG_RUNTIME_DIR=/tmp/runtime-${USERNAME}

# Selkies-specific environment
ENV SELKIES_ENCODER=x264enc \
    SELKIES_ENABLE_RESIZE=true \
    SELKIES_ENABLE_BASIC_AUTH=false \
    SELKIES_TURN_PROTOCOL=udp \
    SELKIES_WEB_PORT=8080 \
    GST_DEBUG=*:2

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
    # Python for Selkies
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    # PyGObject for GStreamer Python bindings
    python3-gi \
    python3-gi-cairo \
    gir1.2-gstreamer-1.0 \
    gir1.2-gst-plugins-base-1.0 \
    gir1.2-gst-plugins-bad-1.0 \
    && rm -rf /var/lib/apt/lists/*

# Configure locales
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen en_US.UTF-8

# Install X11 and desktop environment
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Xorg and utilities
    xorg \
    xvfb \
    x11-xserver-utils \
    x11-utils \
    x11-apps \
    xauth \
    xdg-utils \
    xdg-user-dirs \
    # Mesa/OpenGL
    mesa-utils \
    libgl1-mesa-dri \
    libgl1 \
    libegl1 \
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
    && rm -rf /var/lib/apt/lists/*

# Install GStreamer for Selkies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-pulseaudio \
    gstreamer1.0-x \
    gstreamer1.0-gl \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libsrtp2-1 \
    libnice10 \
    gstreamer1.0-nice \
    && rm -rf /var/lib/apt/lists/*

# Install Firefox ESR
RUN apt-get update && apt-get install -y --no-install-recommends \
    firefox-esr \
    && rm -rf /var/lib/apt/lists/*

# Create user with passwordless sudo
RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# Create necessary directories
RUN mkdir -p /home/${USERNAME}/.config/xfce4 \
             /home/${USERNAME}/.local/share \
             /home/${USERNAME}/.cache \
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

# Install Selkies GStreamer WebRTC from GitHub releases
RUN SELKIES_VERSION="$(curl -fsSL "https://api.github.com/repos/selkies-project/selkies/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    cd /tmp && \
    curl -O -fsSL "https://github.com/selkies-project/selkies/releases/download/v${SELKIES_VERSION}/selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" && \
    pip3 install --break-system-packages --no-cache-dir --force-reinstall \
        "selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" \
        websockets \
        aiohttp \
        prometheus-client && \
    rm -f "selkies_gstreamer-${SELKIES_VERSION}-py3-none-any.whl" && \
    # Download web interface
    mkdir -p /opt/selkies/web && \
    curl -fsSL "https://github.com/selkies-project/selkies/releases/download/v${SELKIES_VERSION}/selkies-gstreamer-web_v${SELKIES_VERSION}.tar.gz" | tar -xzf - -C /opt/selkies/web

# Copy scripts (base scripts should be copied to scripts/ directory before build)
# The GitHub workflow or build script handles copying base scripts
COPY --chmod=755 scripts/ /opt/desktop/scripts/
COPY --chmod=755 configs/ /opt/desktop/configs/

# Create plugin directory
RUN mkdir -p /opt/desktop/plugins && \
    chown -R ${USERNAME}:${USERNAME} /opt/desktop

# Expose ports
# 8080: Selkies WebRTC web interface
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -sf http://localhost:8080/ || exit 1

# Default entrypoint using tini
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/opt/desktop/scripts/entrypoint.sh"]
