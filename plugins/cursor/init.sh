#!/bin/bash
# Cursor plugin - installs Cursor AI code editor via .deb package
set -e

source /opt/desktop/scripts/env-setup.sh

LOG_FILE="/var/log/plugin-manager.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [cursor] $1" | tee -a "$LOG_FILE"; }

# Check if already installed
if [ -f "/usr/bin/cursor" ]; then
    log "Cursor is already installed"
    exit 0
fi

log "Installing Cursor..."

# Detect architecture
ARCH=$(dpkg --print-architecture)
case "$ARCH" in
    amd64)  DEB_URL="https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/2.4" ;;
    arm64)  DEB_URL="https://api2.cursor.sh/updates/download/golden/linux-arm64-deb/cursor/2.4" ;;
    *)
        log "ERROR: Unsupported architecture: ${ARCH}"
        exit 1
        ;;
esac

log "Downloading Cursor (${ARCH}) from: ${DEB_URL}"
cd /tmp
wget -q -O cursor.deb "${DEB_URL}"

# Validate download
FILE_SIZE=$(stat -c%s cursor.deb 2>/dev/null || echo "0")
if [ "$FILE_SIZE" -lt 1000000 ]; then
    log "ERROR: Downloaded file too small (${FILE_SIZE} bytes)"
    rm -f cursor.deb
    exit 1
fi

# Install .deb package (creates /usr/bin/cursor symlink and desktop entry)
dpkg -i cursor.deb || apt-get install -f -y
rm -f cursor.deb

# Copy system desktop entry to user desktop
if [ -f /usr/share/applications/cursor.desktop ]; then
    cp /usr/share/applications/cursor.desktop "${HOME}/Desktop/Cursor.desktop"
    chmod +x "${HOME}/Desktop/Cursor.desktop"
    chown "${USERNAME}:${USERNAME}" "${HOME}/Desktop/Cursor.desktop"
fi

log "Cursor installed successfully"
