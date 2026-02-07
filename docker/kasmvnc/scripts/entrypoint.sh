#!/bin/bash
# Entrypoint script for Debian Desktop Docker with KasmVNC
# Phase 1: Root setup — user creation, environment, plugins
# Phase 2: Drop to target user via gosu for VNC server
set -e

# Phase 1: Root operations

# Create/adjust runtime user
source /opt/desktop/scripts/setup-user.sh

# Source environment configuration
source /opt/desktop/scripts/env-setup.sh

# Initialize user environment (desktop shortcuts, XFCE config)
/opt/desktop/scripts/init-user.sh

# Start system D-Bus
if [ ! -d /run/dbus ]; then
    mkdir -p /run/dbus
fi
dbus-daemon --system --fork 2>/dev/null || true

# Initialize XDG runtime directory with correct ownership
export XDG_RUNTIME_DIR="/tmp/runtime-${USERNAME}"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
chown "${USERNAME}:${USERNAME}" "$XDG_RUNTIME_DIR"

# Update plugins from remote on first boot
if [ ! -f "/opt/desktop/plugins/.updated" ] && [ -n "${PLUGINS:-}" ]; then
    /opt/desktop/scripts/plugin-manager.sh update || true
    touch /opt/desktop/plugins/.updated
fi

# Install configured plugins
/opt/desktop/scripts/plugin-manager.sh install

# Start system services installed by plugins
[ -x /etc/init.d/xrdp ] && /etc/init.d/xrdp start 2>/dev/null || true
if command -v dockerd &>/dev/null && [ ! -S /var/run/docker.sock ]; then
    dockerd &>/dev/null &
fi

# NoMachine must start AFTER KasmVNC (needs the X display running)
# Launch a background helper that waits for the display, then starts NoMachine
if [ -x /etc/NX/nxserver ]; then
    (
        # Wait for KasmVNC to create the display
        for i in $(seq 1 30); do
            [ -e "/tmp/.X11-unix/X${DISPLAY#:}" ] && break
            sleep 1
        done
        /etc/NX/nxserver --startup 2>/dev/null || true
    ) &
fi

# Fix ownership after plugin installs may have modified home
chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}"

# Configure display
export DISPLAY=${DISPLAY:-:1}

# Phase 2: Drop privileges and start KasmVNC as target user
echo "Switching to user ${USERNAME} for VNC server..."
exec gosu "${USERNAME}" /opt/desktop/scripts/start-kasmvnc.sh
