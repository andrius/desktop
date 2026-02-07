#!/bin/bash
# Entrypoint script for Debian Desktop Docker with Selkies
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

# Update plugins from remote on first boot
if [ ! -f "/opt/desktop/plugins/.updated" ] && [ -n "${PLUGINS:-}" ]; then
    /opt/desktop/scripts/plugin-manager.sh update || true
    touch /opt/desktop/plugins/.updated
fi

# Install configured plugins
/opt/desktop/scripts/plugin-manager.sh install

# Start system services installed by plugins
[ -x /etc/init.d/xrdp ] && /etc/init.d/xrdp start 2>/dev/null || true
[ -x /etc/NX/nxserver ] && /etc/NX/nxserver --startup 2>/dev/null || true
if command -v dockerd &>/dev/null && [ ! -S /var/run/docker.sock ]; then
    dockerd &>/dev/null &
fi

# Configure display
export DISPLAY=${DISPLAY:-:0}
RESOLUTION=${RESOLUTION:-1920x1080x24}
RESOLUTION_X=$(echo $RESOLUTION | cut -d'x' -f1)
RESOLUTION_Y=$(echo $RESOLUTION | cut -d'x' -f2)

# Clean up any stale X server locks
rm -f /tmp/.X*-lock /tmp/.X11-unix/X* 2>/dev/null || true

# Start X virtual framebuffer
echo "Starting Xvfb on display ${DISPLAY}..."
Xvfb ${DISPLAY} -screen 0 ${RESOLUTION} +extension GLX +extension RANDR +extension MIT-SHM &
XVFB_PID=$!
sleep 2

# Verify Xvfb started
if ! kill -0 $XVFB_PID 2>/dev/null; then
    echo "ERROR: Xvfb failed to start"
    exit 1
fi

# Wait for X server to be ready
TIMEOUT=30
COUNT=0
while ! xdpyinfo -display ${DISPLAY} >/dev/null 2>&1; do
    sleep 1
    COUNT=$((COUNT + 1))
    if [ $COUNT -ge $TIMEOUT ]; then
        echo "ERROR: X server did not start within ${TIMEOUT} seconds"
        exit 1
    fi
done

echo "X server is ready on display ${DISPLAY}"

# Set keyboard layout
setxkbmap -layout us 2>/dev/null || true

# Start PulseAudio for audio support
echo "Starting PulseAudio..."
pulseaudio --start --exit-idle-time=-1 2>/dev/null || true

# Start XFCE4 session in background
echo "Starting XFCE4 desktop environment..."
startxfce4 &
sleep 3

# Start Selkies GStreamer WebRTC
echo "Starting Selkies GStreamer WebRTC..."
/opt/desktop/scripts/start-selkies.sh
