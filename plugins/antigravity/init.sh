#!/bin/bash
# Antigravity plugin - installs Google Antigravity IDE
source /opt/desktop/scripts/plugin-lib.sh

# Check if already installed
if command -v antigravity &>/dev/null; then
    log "Antigravity is already installed"
    exit 0
fi

# Antigravity only provides amd64 Linux packages
ARCH=$(dpkg --print-architecture)
if [ "$ARCH" != "amd64" ]; then
    log "ERROR: Antigravity is only available for amd64 (current: ${ARCH})"
    exit 1
fi

log "Installing Antigravity..."

# Add Google GPG key and repository
wget -qO- https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | gpg --dearmor > /tmp/google-antigravity.gpg
install -D -o root -g root -m 644 /tmp/google-antigravity.gpg /usr/share/keyrings/google-antigravity.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-antigravity.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" > /etc/apt/sources.list.d/google-antigravity.list
rm -f /tmp/google-antigravity.gpg

apt-get update
apt-get install -y antigravity
rm -rf /var/lib/apt/lists/*

# Disable suid sandbox — Chromium's credentials.cc aborts in Docker containers
# that lack user namespace support, even with --no-sandbox
if [ -f /usr/share/antigravity/chrome-sandbox ]; then
    chmod 0755 /usr/share/antigravity/chrome-sandbox
fi

# Patch system .desktop entry with --no-sandbox for application menu
for desktop_file in /usr/share/applications/antigravity*.desktop; do
    [ -f "$desktop_file" ] || continue
    sed -i 's|Exec=/usr/share/antigravity/antigravity|Exec=/usr/share/antigravity/antigravity --no-sandbox|g' "$desktop_file"
    sed -i 's|Exec=antigravity |Exec=antigravity --no-sandbox |g' "$desktop_file"
done

# Create desktop shortcut
cat > "${HOME}/Desktop/Antigravity.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Antigravity
Comment=AI-first code editor
Exec=/usr/bin/antigravity --no-sandbox %F
Icon=antigravity
Terminal=false
Categories=Development;IDE;
EOF
chown "${USERNAME}:${USERNAME}" "${HOME}/Desktop/Antigravity.desktop"

log "Antigravity installed successfully"
