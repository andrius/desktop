#!/bin/bash
# NoMachine plugin - installs NoMachine remote desktop server
set -e

source /opt/desktop/scripts/env-setup.sh

LOG_FILE="/var/log/plugin-manager.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [nomachine] $1" | tee -a "$LOG_FILE"; }

# Check if already installed
if command -v nxserver &>/dev/null || [ -x /etc/NX/nxserver ]; then
    log "NoMachine is already installed"
    exit 0
fi

NOMACHINE_VERSION="9.3.7"
NOMACHINE_MAJOR_MINOR="9.3"
NOMACHINE_BUILD="1"

ARCH=$(dpkg --print-architecture)
case "$ARCH" in
    amd64)
        NOMACHINE_DEB="nomachine_${NOMACHINE_VERSION}_${NOMACHINE_BUILD}_amd64.deb"
        NOMACHINE_URL="https://download.nomachine.com/download/${NOMACHINE_MAJOR_MINOR}/Linux/${NOMACHINE_DEB}"
        ;;
    arm64)
        NOMACHINE_DEB="nomachine_${NOMACHINE_VERSION}_${NOMACHINE_BUILD}_arm64.deb"
        NOMACHINE_URL="https://download.nomachine.com/download/${NOMACHINE_MAJOR_MINOR}/Arm/${NOMACHINE_DEB}"
        ;;
    *)
        log "ERROR: NoMachine is not available for ${ARCH}"
        exit 1
        ;;
esac

log "Installing NoMachine ${NOMACHINE_VERSION} (${ARCH})..."

cd /tmp
wget -q -L "${NOMACHINE_URL}" -O "${NOMACHINE_DEB}"

# Validate download is actually a deb package
if ! dpkg-deb --info "${NOMACHINE_DEB}" &>/dev/null; then
    log "ERROR: Downloaded file is not a valid .deb package"
    rm -f "${NOMACHINE_DEB}"
    exit 1
fi

dpkg -i "${NOMACHINE_DEB}" || { apt-get install -f -y && dpkg -i "${NOMACHINE_DEB}"; }
rm -f "${NOMACHINE_DEB}"

# Stop NoMachine immediately — dpkg postinst starts it with default config,
# which tries physical display :1 (owned by KasmVNC) and crashes nxnode
log "Stopping NoMachine default services before reconfiguration..."
/etc/NX/nxserver --shutdown 2>/dev/null || true

# Configure NoMachine for virtual displays (avoid conflict with KasmVNC on :1)
log "Configuring NoMachine for virtual displays..."

SERVER_CFG="/usr/NX/etc/server.cfg"
NODE_CFG="/usr/NX/etc/node.cfg"

# Remove physical-desktop from available session types (use virtual only)
sed -i 's/^#\?AvailableSessionTypes .*/AvailableSessionTypes unix-xsession-default unix-application unix-console/' "$SERVER_CFG"
sed -i 's/^#\?AvailableSessionTypes .*/AvailableSessionTypes unix-xsession-default unix-application unix-console/' "$NODE_CFG"

# Enable virtual display creation via nxagent
sed -i 's/^#\?CreateDisplay .*/CreateDisplay 1/' "$SERVER_CFG"

# Virtual displays start at :2 (KasmVNC uses :1)
sed -i 's/^#\?DisplayBase .*/DisplayBase 2/' "$SERVER_CFG"

# Ensure XFCE4 as the default desktop
sed -i 's|^#\?DefaultDesktopCommand .*|DefaultDesktopCommand "/usr/bin/startxfce4"|' "$NODE_CFG"

# Start NoMachine with the corrected configuration
log "Starting NoMachine server..."
if /etc/NX/nxserver --startup 2>&1 | tee -a "$LOG_FILE"; then
    log "NoMachine installed successfully (port 4000, virtual displays from :2)"
else
    log "WARNING: NoMachine startup returned non-zero, check /usr/NX/var/log/server.log"
fi
