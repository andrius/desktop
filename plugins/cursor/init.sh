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

CURSOR_API="https://cursor.com/api/download?platform=linux-${CURSOR_ARCH}&releaseTrack=stable"

cd /tmp

# Resolve download URL from API
CURSOR_URL=$(wget -q -O - "${CURSOR_API}" | grep -oP '"downloadUrl"\s*:\s*"\K[^"]+' | head -1)

if [ -z "$CURSOR_URL" ]; then
    # Fallback to legacy direct URL
    log "API unavailable, using fallback URL"
    CURSOR_URL="https://downloader.cursor.sh/linux/appImage/${CURSOR_ARCH}"
fi

log "Downloading from: ${CURSOR_URL}"
wget -q -O cursor.AppImage "${CURSOR_URL}"

# Validate download size
FILE_SIZE=$(stat -c%s cursor.AppImage 2>/dev/null || echo "0")
if [ "$FILE_SIZE" -lt 1000000 ]; then
    log "ERROR: Downloaded file too small (${FILE_SIZE} bytes) - likely not a valid AppImage"
    rm -f cursor.AppImage
    exit 1
fi

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
