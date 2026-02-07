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

# Start NoMachine server
/etc/NX/nxserver --startup 2>/dev/null || true

log "NoMachine installed successfully (port 4000)"
