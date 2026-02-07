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

# Disable suid sandbox — Chromium's credentials.cc aborts in Docker containers
# that lack user namespace support, even with --no-sandbox
chmod 0755 /usr/share/cursor/chrome-sandbox

# Create desktop shortcut with --no-sandbox (required in containers)
cat > "${HOME}/Desktop/Cursor.desktop" << 'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Cursor
Comment=The AI Code Editor
Exec=/usr/share/cursor/cursor --no-sandbox %F
Icon=co.anysphere.cursor
Terminal=false
Categories=Development;IDE;
StartupNotify=false
StartupWMClass=Cursor
DESKTOP
chmod +x "${HOME}/Desktop/Cursor.desktop"
chown "${USERNAME}:${USERNAME}" "${HOME}/Desktop/Cursor.desktop"

# Also patch the system .desktop entry for application menu
if [ -f /usr/share/applications/cursor.desktop ]; then
    sed -i 's|Exec=/usr/share/cursor/cursor|Exec=/usr/share/cursor/cursor --no-sandbox|g' /usr/share/applications/cursor.desktop
fi

log "Cursor installed successfully"
