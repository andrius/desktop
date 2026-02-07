#!/bin/bash
# Cursor plugin - installs Cursor AI code editor
set -e

source /opt/desktop/scripts/env-setup.sh

LOG_FILE="/var/log/plugin-manager.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [cursor] $1" | tee -a "$LOG_FILE"; }

# Check if already installed
if [ -f "/opt/cursor/cursor" ] || [ -f "/usr/bin/cursor" ]; then
    log "Cursor is already installed"
    exit 0
fi

log "Installing Cursor..."

# Detect architecture for AppImage URL
ARCH=$(dpkg --print-architecture)
case "$ARCH" in
    amd64)  CURSOR_ARCH="x64" ;;
    arm64)  CURSOR_ARCH="arm64" ;;
    *)
        log "ERROR: Unsupported architecture: ${ARCH}"
        exit 1
        ;;
esac

CURSOR_URL="https://downloader.cursor.sh/linux/appImage/${CURSOR_ARCH}"

cd /tmp
wget -q -O cursor.AppImage "${CURSOR_URL}"

mkdir -p /opt/cursor
mv cursor.AppImage /opt/cursor/cursor
chmod +x /opt/cursor/cursor

# Create symlink
ln -sf /opt/cursor/cursor /usr/local/bin/cursor

# Create desktop shortcut
cat > "${HOME}/Desktop/Cursor.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Cursor
Comment=AI-powered code editor
Exec=/opt/cursor/cursor --no-sandbox %F
Icon=code
Terminal=false
Categories=Development;IDE;
EOF
chmod +x "${HOME}/Desktop/Cursor.desktop"
chown "${USERNAME}:${USERNAME}" "${HOME}/Desktop/Cursor.desktop"

log "Cursor installed successfully"
