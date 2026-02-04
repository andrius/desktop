#!/bin/bash
# Entrypoint script for Debian Desktop Docker
set -e

# Source environment configuration
source /opt/desktop/scripts/env-setup.sh

# Initialize user environment
/opt/desktop/scripts/init-user.sh

# Start D-Bus
if [ ! -d /run/dbus ]; then
    sudo mkdir -p /run/dbus
fi
sudo dbus-daemon --system --fork 2>/dev/null || true

# Initialize XDG runtime directory
export XDG_RUNTIME_DIR="/tmp/runtime-${USER}"
if [ ! -d "$XDG_RUNTIME_DIR" ]; then
    mkdir -p "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"
fi

# Install plugins if configured
if [ -f "/opt/desktop/scripts/plugin-manager.sh" ]; then
    /opt/desktop/scripts/plugin-manager.sh install
fi

# Start X virtual framebuffer if not running
if ! pgrep -x "Xvfb" > /dev/null; then
    echo "Starting Xvfb on display ${DISPLAY}..."
    Xvfb ${DISPLAY} -screen 0 ${RESOLUTION:-1920x1080x24} &
    sleep 2
fi

# Export display for applications
export DISPLAY=${DISPLAY:-:1}

# Start XFCE4 session
echo "Starting XFCE4 desktop environment..."
exec /opt/desktop/scripts/start-desktop.sh "$@"
