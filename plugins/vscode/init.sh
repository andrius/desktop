#!/bin/bash
# VS Code plugin - installs Visual Studio Code
source /opt/desktop/scripts/plugin-lib.sh

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

# Disable suid sandbox — Chromium's credentials.cc aborts in Docker containers
# that lack user namespace support, even with --no-sandbox
if [ -f /usr/share/code/chrome-sandbox ]; then
    chmod 0755 /usr/share/code/chrome-sandbox
fi

# Patch system .desktop entry with --no-sandbox for application menu
if [ -f /usr/share/applications/code.desktop ]; then
    sed -i 's|Exec=/usr/share/code/code|Exec=/usr/share/code/code --no-sandbox|g' /usr/share/applications/code.desktop
fi

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
chown "${USERNAME}:${USERNAME}" "${HOME}/Desktop/VSCode.desktop"

log "VS Code installed successfully"
