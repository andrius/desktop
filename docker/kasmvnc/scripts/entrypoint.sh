#!/bin/bash
# Entrypoint script for Debian Desktop Docker with KasmVNC
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

# Configure display
export DISPLAY=${DISPLAY:-:1}

# Start PulseAudio for audio support
echo "Starting PulseAudio..."
pulseaudio --start --exit-idle-time=-1 2>/dev/null || true

# Start KasmVNC
echo "Starting KasmVNC server..."
exec /opt/desktop/scripts/start-kasmvnc.sh
