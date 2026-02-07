#!/bin/bash
# XRDP plugin - installs XRDP remote desktop server (coexists with KasmVNC)
set -e

source /opt/desktop/scripts/env-setup.sh

LOG_FILE="/var/log/plugin-manager.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [xrdp] $1" | tee -a "$LOG_FILE"; }

# Check if already installed
if command -v xrdp &>/dev/null; then
    log "XRDP is already installed"
    exit 0
fi

log "Installing XRDP..."

apt-get update
apt-get install -y --no-install-recommends xrdp xorgxrdp
rm -rf /var/lib/apt/lists/*

# Create .xsession for XFCE
cat > "${HOME}/.xsession" << 'EOF'
#!/bin/bash
exec xfce4-session
EOF
chmod +x "${HOME}/.xsession"
chown "${USERNAME}:${USERNAME}" "${HOME}/.xsession"

# Start XRDP service
/etc/init.d/xrdp start 2>/dev/null || true

log "XRDP installed successfully (port 3389)"
