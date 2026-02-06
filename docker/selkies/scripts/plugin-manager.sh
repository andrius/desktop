#!/bin/bash
# Plugin Manager for Debian Desktop Docker
# Handles installation of optional software based on .env configuration
set -e

PLUGIN_DIR="/opt/desktop/plugins"
LOG_FILE="/var/log/plugin-manager.log"

# Source environment
source /opt/desktop/scripts/env-setup.sh

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | sudo tee -a "$LOG_FILE"
}

# Plugin installation functions
install_chrome() {
    log "Installing Google Chrome Stable..."

    if command -v google-chrome-stable &> /dev/null; then
        log "Google Chrome is already installed"
        return 0
    fi

    # Add Google Chrome repository
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list

    sudo apt-get update
    sudo apt-get install -y google-chrome-stable

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
    chmod +x "${HOME}/Desktop/Chrome.desktop"

    log "Google Chrome installed successfully"
}

install_nomachine() {
    log "Installing NoMachine Server..."

    if command -v nxserver &> /dev/null; then
        log "NoMachine is already installed"
        return 0
    fi

    # Download and install NoMachine
    NOMACHINE_VERSION="8.14.2"
    NOMACHINE_BUILD="1"
    NOMACHINE_DEB="nomachine_${NOMACHINE_VERSION}_${NOMACHINE_BUILD}_amd64.deb"

    cd /tmp
    wget -q "https://download.nomachine.com/download/8.14/Linux/${NOMACHINE_DEB}"
    sudo dpkg -i "${NOMACHINE_DEB}" || sudo apt-get install -f -y
    rm -f "${NOMACHINE_DEB}"

    log "NoMachine installed successfully"
}

install_cursor() {
    log "Installing Cursor Editor..."

    if [ -f "/opt/cursor/cursor" ] || [ -f "/usr/bin/cursor" ]; then
        log "Cursor is already installed"
        return 0
    fi

    # Download latest Cursor AppImage
    cd /tmp
    CURSOR_URL="https://downloader.cursor.sh/linux/appImage/x64"
    wget -q -O cursor.AppImage "${CURSOR_URL}"

    # Install Cursor
    sudo mkdir -p /opt/cursor
    sudo mv cursor.AppImage /opt/cursor/cursor
    sudo chmod +x /opt/cursor/cursor

    # Create symlink
    sudo ln -sf /opt/cursor/cursor /usr/local/bin/cursor

    # Create desktop shortcut
    cat > "${HOME}/Desktop/Cursor.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Cursor
Comment=AI-powered code editor
Exec=/opt/cursor/cursor --no-sandbox %F
Icon=code
Terminal=false
Categories=Development;IDE;
EOF
    chmod +x "${HOME}/Desktop/Cursor.desktop"

    log "Cursor installed successfully"
}

install_vscode() {
    log "Installing Visual Studio Code..."

    if command -v code &> /dev/null; then
        log "VS Code is already installed"
        return 0
    fi

    # Add Microsoft repository
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /usr/share/keyrings/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f /tmp/packages.microsoft.gpg

    sudo apt-get update
    sudo apt-get install -y code

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

    log "VS Code installed successfully"
}

install_claude_code() {
    log "Installing Claude Code..."

    if command -v claude &> /dev/null; then
        log "Claude Code is already installed"
        return 0
    fi

    # Install via npm (requires Node.js)
    if ! command -v node &> /dev/null; then
        log "Installing Node.js first..."
        # Install Node.js via Homebrew
        if command -v brew &> /dev/null; then
            brew install node
        else
            # Fallback: install from NodeSource
            curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi
    fi

    # Install Claude Code globally
    sudo npm install -g @anthropic-ai/claude-code

    log "Claude Code installed successfully"
}

install_opencode() {
    log "Installing OpenCode..."

    if command -v opencode &> /dev/null; then
        log "OpenCode is already installed"
        return 0
    fi

    # Install OpenCode via go install or download binary
    if command -v brew &> /dev/null; then
        brew install opencode
    else
        # Download from GitHub releases
        cd /tmp
        OPENCODE_VERSION="latest"
        wget -q -O opencode.tar.gz "https://github.com/opencode-ai/opencode/releases/latest/download/opencode_Linux_x86_64.tar.gz" || {
            log "Failed to download OpenCode"
            return 1
        }
        tar -xzf opencode.tar.gz
        sudo mv opencode /usr/local/bin/
        rm -f opencode.tar.gz
    fi

    log "OpenCode installed successfully"
}

# Main installation logic
install_plugins() {
    log "Starting plugin installation..."

    if [ "$ENABLE_CHROME" = "true" ]; then
        install_chrome || log "Failed to install Chrome"
    fi

    if [ "$ENABLE_NOMACHINE" = "true" ]; then
        install_nomachine || log "Failed to install NoMachine"
    fi

    if [ "$ENABLE_CURSOR" = "true" ]; then
        install_cursor || log "Failed to install Cursor"
    fi

    if [ "$ENABLE_VSCODE" = "true" ]; then
        install_vscode || log "Failed to install VS Code"
    fi

    if [ "$ENABLE_CLAUDE_CODE" = "true" ]; then
        install_claude_code || log "Failed to install Claude Code"
    fi

    if [ "$ENABLE_OPENCODE" = "true" ]; then
        install_opencode || log "Failed to install OpenCode"
    fi

    log "Plugin installation completed"
}

# List available plugins
list_plugins() {
    echo "Available plugins:"
    echo "  - chrome      : Google Chrome browser"
    echo "  - nomachine   : NoMachine remote desktop server"
    echo "  - cursor      : Cursor AI code editor"
    echo "  - vscode      : Visual Studio Code"
    echo "  - claude-code : Anthropic's Claude Code CLI"
    echo "  - opencode    : OpenCode CLI tool"
    echo ""
    echo "Enable plugins by setting environment variables:"
    echo "  ENABLE_CHROME=true"
    echo "  ENABLE_NOMACHINE=true"
    echo "  ENABLE_CURSOR=true"
    echo "  ENABLE_VSCODE=true"
    echo "  ENABLE_CLAUDE_CODE=true"
    echo "  ENABLE_OPENCODE=true"
}

# Command dispatcher
case "${1:-install}" in
    install)
        install_plugins
        ;;
    list)
        list_plugins
        ;;
    chrome)
        install_chrome
        ;;
    nomachine)
        install_nomachine
        ;;
    cursor)
        install_cursor
        ;;
    vscode)
        install_vscode
        ;;
    claude-code)
        install_claude_code
        ;;
    opencode)
        install_opencode
        ;;
    *)
        echo "Usage: $0 {install|list|chrome|nomachine|cursor|vscode|claude-code|opencode}"
        exit 1
        ;;
esac
