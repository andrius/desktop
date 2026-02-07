#!/bin/bash
# VS Code plugin - installs Visual Studio Code
set -e

source /opt/desktop/scripts/env-setup.sh

LOG_FILE="/var/log/plugin-manager.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [vscode] $1" | tee -a "$LOG_FILE"; }

# Check if already installed
if command -v code &>/dev/null; then
    log "VS Code is already installed"
    exit 0
fi

log "Installing Visual Studio Code..."

# Add Microsoft GPG key and repository
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /usr/share/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
rm -f /tmp/packages.microsoft.gpg

apt-get update
apt-get install -y code
rm -rf /var/lib/apt/lists/*

# Create desktop shortcut
cat > "${HOME}/Desktop/VSCode.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Visual Studio Code
Comment=Code editing, redefined
Exec=/usr/bin/code --no-sandbox %F
Icon=vscode
Terminal=false
Categories=Development;IDE;
EOF
chmod +x "${HOME}/Desktop/VSCode.desktop"
chown "${USERNAME}:${USERNAME}" "${HOME}/Desktop/VSCode.desktop"

log "VS Code installed successfully"
