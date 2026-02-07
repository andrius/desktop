#!/bin/bash
# XRDP plugin - installs XRDP remote desktop server (coexists with KasmVNC)
source /opt/desktop/scripts/plugin-lib.sh

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

log "XRDP installed successfully (port 3389)"
