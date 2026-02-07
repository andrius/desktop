#!/bin/bash
# NoMachine plugin - installs NoMachine remote desktop server
source /opt/desktop/scripts/plugin-lib.sh

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

# NoMachine bundles its own libraries in /usr/NX/lib — DO NOT register with ldconfig
# (NoMachine's libcrypt.so.1 conflicts with system libcrypt and breaks vncpasswd/chpasswd)
# NoMachine wrapper scripts (nxnode, nxserver) set LD_LIBRARY_PATH internally

# Stop NoMachine immediately — dpkg postinst starts it with default config
log "Stopping NoMachine default services before reconfiguration..."
/etc/NX/nxserver --shutdown 2>/dev/null || true

# Configure NoMachine for physical desktop mode (free edition — shares KasmVNC display :1)
# Virtual desktops require NoMachine Enterprise; free edition connects to the existing X display
log "Configuring NoMachine for physical desktop mode..."

SERVER_CFG="/usr/NX/etc/server.cfg"
NODE_CFG="/usr/NX/etc/node.cfg"

# Physical-desktop only (free edition limitation)
sed -i 's/^#\?AvailableSessionTypes .*/AvailableSessionTypes physical-desktop/' "$SERVER_CFG"
sed -i 's/^#\?AvailableSessionTypes .*/AvailableSessionTypes physical-desktop/' "$NODE_CFG"

# Disable virtual display creation (not supported in free edition)
sed -i 's/^#\?CreateDisplay .*/CreateDisplay 0/' "$SERVER_CFG"

# Ensure XFCE4 as the default desktop
sed -i 's|^#\?DefaultDesktopCommand .*|DefaultDesktopCommand "/usr/bin/startxfce4"|' "$NODE_CFG"

# KasmVNC runs on display :1, not the default :0
sed -i 's/^#\?PhysicalDisplays .*/PhysicalDisplays :1/' "$NODE_CFG"

# Disable "your desktop is currently viewed" popup (annoying in headless/remote use)
sed -i 's/^#\?ShowDesktopViewed .*/ShowDesktopViewed 0/' "$NODE_CFG"

# Hide system tray icon
sed -i 's/^#\?DisplayMonitorIcon .*/DisplayMonitorIcon 0/' "$NODE_CFG"

log "NoMachine installed successfully (port 4000, physical desktop on display :1)"
