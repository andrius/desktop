#!/bin/bash
# OpenCode plugin - installs the OpenCode AI coding agent
source /opt/desktop/scripts/plugin-lib.sh

# Check if already installed
if command -v opencode &>/dev/null; then
    log "OpenCode is already installed"
    exit 0
fi

log "Installing OpenCode..."

# Detect architecture
ARCH=$(dpkg --print-architecture)

# Fetch latest release .deb URL from GitHub API
RELEASE_URL=$(curl -fsSL https://api.github.com/repos/opencode-ai/opencode/releases/latest \
    | grep "browser_download_url.*opencode-linux-${ARCH}.deb" \
    | cut -d '"' -f 4)

if [ -z "$RELEASE_URL" ]; then
    log "ERROR: No .deb package found for architecture: ${ARCH}"
    exit 1
fi

log "Downloading OpenCode (${ARCH}) from: ${RELEASE_URL}"
cd /tmp
wget -q -O opencode.deb "$RELEASE_URL"

# Validate download
FILE_SIZE=$(stat -c%s opencode.deb 2>/dev/null || echo "0")
if [ "$FILE_SIZE" -lt 1000000 ]; then
    log "ERROR: Downloaded file too small (${FILE_SIZE} bytes)"
    rm -f opencode.deb
    exit 1
fi

# Install
dpkg -i opencode.deb || apt-get install -f -y
rm -f opencode.deb

log "OpenCode installed successfully"
