# Plugin System Documentation

The Debian Docker Desktop includes a flexible plugin system for installing optional software. Plugins can be enabled via environment variables or installed manually.

## Available Plugins

### Google Chrome

**Description**: Google Chrome stable browser
**Enable**: `ENABLE_CHROME=true`
**Manual Install**: `/opt/desktop/scripts/plugin-manager.sh chrome`

Chrome is installed from Google's official APT repository and creates a desktop shortcut.

### NoMachine

**Description**: NoMachine remote desktop server
**Enable**: `ENABLE_NOMACHINE=true`
**Manual Install**: `/opt/desktop/scripts/plugin-manager.sh nomachine`

NoMachine provides an alternative remote desktop solution with:
- NX protocol for efficient remote access
- Audio support
- File transfer
- Multi-monitor support

**Note**: NoMachine runs alongside the VNC server and uses port 4000.

### Cursor

**Description**: AI-powered code editor based on VS Code
**Enable**: `ENABLE_CURSOR=true`
**Manual Install**: `/opt/desktop/scripts/plugin-manager.sh cursor`

Cursor is installed as an AppImage to `/opt/cursor/cursor`.

### Visual Studio Code

**Description**: Microsoft Visual Studio Code editor
**Enable**: `ENABLE_VSCODE=true`
**Manual Install**: `/opt/desktop/scripts/plugin-manager.sh vscode`

VS Code is installed from Microsoft's official APT repository.

### Claude Code

**Description**: Anthropic's Claude Code CLI tool
**Enable**: `ENABLE_CLAUDE_CODE=true`
**Manual Install**: `/opt/desktop/scripts/plugin-manager.sh claude-code`

Claude Code requires Node.js, which will be installed automatically if not present.

**Prerequisites**: Node.js (installed automatically)

### OpenCode

**Description**: OpenCode CLI tool
**Enable**: `ENABLE_OPENCODE=true`
**Manual Install**: `/opt/desktop/scripts/plugin-manager.sh opencode`

OpenCode is installed from GitHub releases.

## Configuration

### Via Environment Variables

Add plugin configuration to your `.env` file:

```bash
# Enable plugins
ENABLE_CHROME=true
ENABLE_VSCODE=true
ENABLE_CURSOR=true
ENABLE_CLAUDE_CODE=true
ENABLE_OPENCODE=true
ENABLE_NOMACHINE=true
```

Plugins are installed during container startup when their environment variables are set to `true`.

### Manual Installation

Plugins can be installed manually after the container is running:

```bash
# Enter the container
docker exec -it debian-desktop-kasmvnc bash

# List available plugins
/opt/desktop/scripts/plugin-manager.sh list

# Install specific plugins
/opt/desktop/scripts/plugin-manager.sh chrome
/opt/desktop/scripts/plugin-manager.sh vscode
/opt/desktop/scripts/plugin-manager.sh cursor
/opt/desktop/scripts/plugin-manager.sh claude-code
/opt/desktop/scripts/plugin-manager.sh opencode
/opt/desktop/scripts/plugin-manager.sh nomachine
```

## Plugin Installation Logs

Plugin installation logs are stored at `/var/log/plugin-manager.log`:

```bash
# View plugin installation logs
cat /var/log/plugin-manager.log

# Follow logs in real-time
tail -f /var/log/plugin-manager.log
```

## Creating Custom Plugins

You can extend the plugin system by adding new installation functions to `/opt/desktop/scripts/plugin-manager.sh`:

```bash
install_myapp() {
    log "Installing MyApp..."

    # Check if already installed
    if command -v myapp &> /dev/null; then
        log "MyApp is already installed"
        return 0
    fi

    # Installation steps
    # ...

    # Create desktop shortcut (optional)
    cat > "${HOME}/Desktop/MyApp.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=MyApp
Exec=/usr/bin/myapp
Icon=myapp
Terminal=false
Categories=Utility;
EOF
    chmod +x "${HOME}/Desktop/MyApp.desktop"

    log "MyApp installed successfully"
}
```

Then add the plugin to the command dispatcher:

```bash
case "${1:-install}" in
    # ... existing cases ...
    myapp)
        install_myapp
        ;;
esac
```

## Troubleshooting

### Plugin installation fails

1. Check network connectivity:
   ```bash
   ping -c 1 google.com
   ```

2. Check available disk space:
   ```bash
   df -h /
   ```

3. View detailed logs:
   ```bash
   cat /var/log/plugin-manager.log
   ```

### Plugin not starting

1. Check if the application is installed:
   ```bash
   which chrome  # or vscode, cursor, etc.
   ```

2. Try running from terminal to see error messages:
   ```bash
   google-chrome-stable --no-sandbox
   code --no-sandbox
   ```

3. Check for missing dependencies:
   ```bash
   ldd /path/to/application | grep "not found"
   ```

### Desktop shortcuts not working

1. Verify the shortcut file exists:
   ```bash
   ls -la ~/Desktop/
   ```

2. Check shortcut permissions:
   ```bash
   chmod +x ~/Desktop/MyApp.desktop
   ```

3. Verify the shortcut configuration:
   ```bash
   cat ~/Desktop/MyApp.desktop
   ```
