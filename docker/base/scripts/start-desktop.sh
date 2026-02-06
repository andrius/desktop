#!/bin/bash
# Start XFCE4 desktop environment
set -e

source /opt/desktop/scripts/env-setup.sh

echo "Starting XFCE4 desktop on display ${DISPLAY}..."

# Ensure X is running
if ! pgrep -x "Xvfb" > /dev/null; then
    echo "ERROR: Xvfb is not running"
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

# Start xfce4-session
exec startxfce4
