#!/bin/bash
# Entrypoint script for Debian Desktop Docker with KasmVNC
# Phase 1: System init (root, fast)
# Phase 2: Background plugin processing (root, after display ready)
# Phase 3: Start KasmVNC (exec gosu → user, foreground)
set -e

# Phase 1: System initialization (root, fast)

# Create/adjust runtime user
source /opt/desktop/scripts/setup-user.sh

# Source environment configuration
source /opt/desktop/scripts/env-setup.sh

# Initialize user environment (desktop shortcuts, XFCE config)
/opt/desktop/scripts/init-user.sh

# System D-Bus
mkdir -p /run/dbus
dbus-daemon --system --fork 2>/dev/null || true

# XDG runtime directory
export XDG_RUNTIME_DIR="/tmp/runtime-${USERNAME}"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
chown "${USERNAME}:${USERNAME}" "$XDG_RUNTIME_DIR"

# Phase 2: Background plugin processing (root)
# Runs after KasmVNC creates the display — desktop is accessible immediately
if [ -n "${PLUGINS:-}" ]; then
    (
        # Wait for X display
        for i in $(seq 1 60); do
            [ -e "/tmp/.X11-unix/X${DISPLAY#:}" ] && break
            sleep 1
        done

        # Update from remote (first boot only)
        if [ ! -f "/opt/desktop/plugins/.updated" ]; then
            /opt/desktop/scripts/plugin-manager.sh update || true
            touch /opt/desktop/plugins/.updated
        fi

        # Install and start plugins
        /opt/desktop/scripts/plugin-manager.sh install
        /opt/desktop/scripts/plugin-manager.sh start

        # Fix ownership after plugin installs
        chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}"
    ) &
fi

# Phase 3: Start KasmVNC (drop privileges)
export DISPLAY=${DISPLAY:-:1}
exec gosu "${USERNAME}" /opt/desktop/scripts/start-kasmvnc.sh
