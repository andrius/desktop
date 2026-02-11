#!/bin/bash
# Chrome plugin - installs Google Chrome
source /opt/desktop/scripts/plugin-lib.sh

# Check if already installed
if command -v google-chrome-stable &>/dev/null; then
    log "Google Chrome is already installed"
    exit 0
fi

# Chrome only provides amd64 Linux packages
ARCH=$(dpkg --print-architecture)
if [ "$ARCH" != "amd64" ]; then
    log "ERROR: Google Chrome is only available for amd64 (current: ${ARCH})"
    exit 1
fi

log "Installing Google Chrome..."

# Add Google GPG key and repository
wget -qO- https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /tmp/google-chrome.gpg
install -D -o root -g root -m 644 /tmp/google-chrome.gpg /usr/share/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
rm -f /tmp/google-chrome.gpg

apt-get update
apt-get install -y google-chrome-stable
rm -rf /var/lib/apt/lists/*

# Disable suid sandbox — Chromium's credentials.cc aborts in Docker containers
# that lack user namespace support, even with --no-sandbox
if [ -f /opt/google/chrome/chrome-sandbox ]; then
    chmod 0755 /opt/google/chrome/chrome-sandbox
fi

# Patch system .desktop entry with --no-sandbox for application menu
if [ -f /usr/share/applications/google-chrome.desktop ]; then
    sed -i 's|Exec=/usr/bin/google-chrome-stable|Exec=/usr/bin/google-chrome-stable --no-sandbox|g' /usr/share/applications/google-chrome.desktop
fi

# Create desktop shortcut
cat > "${HOME}/Desktop/Chrome.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Google Chrome
Comment=Access the Internet
Exec=/usr/bin/google-chrome-stable --no-sandbox %U
Icon=google-chrome
Terminal=false
Categories=Network;WebBrowser;
EOF
chown "${USERNAME}:${USERNAME}" "${HOME}/Desktop/Chrome.desktop"

# Wrap Chrome binaries so any direct invocation gets --no-sandbox
# (apps like Cursor/VS Code call the binary directly, bypassing .desktop files)
for chrome_bin in /usr/bin/google-chrome-stable /usr/bin/google-chrome; do
    if [ -f "$chrome_bin" ] && [ ! -f "${chrome_bin}.real" ]; then
        mv "$chrome_bin" "${chrome_bin}.real"
        cat > "$chrome_bin" << WRAPPER
#!/bin/bash
exec "${chrome_bin}.real" --no-sandbox "\$@"
WRAPPER
        chmod +x "$chrome_bin"
    fi
done

log "Google Chrome installed successfully"
