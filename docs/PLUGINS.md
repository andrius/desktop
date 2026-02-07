# Plugin System

The Debian Docker Desktop uses a directory-based plugin system for installing optional software. Each plugin is a self-contained folder with an install script, tests, and documentation.

## Quick Start

Set the `PLUGINS` environment variable to a comma-separated list of plugins:

```bash
# .env
PLUGINS=brew,vscode,cursor
```

Plugins install automatically on first container start and are skipped on restart.

## Available Plugins

| Plugin | Description | Port | Arch |
|--------|-------------|------|------|
| `brew` | Homebrew package manager | - | all |
| `chrome` | Google Chrome browser | - | amd64 |
| `xrdp` | XRDP remote desktop server | 3389 | all |
| `nomachine` | NoMachine remote desktop server | 4000 | all |
| `cursor` | Cursor AI code editor | - | amd64 |
| `vscode` | Visual Studio Code | - | all |
| `claude-code` | Claude Code CLI | - | all |
| `docker` | Docker Engine (DinD) | - | all |

## Plugin Configuration

### Via Environment Variables

```bash
# .env
PLUGINS=brew,chrome,vscode,xrdp

# Plugin-specific ports
XRDP_PORT=3389
NOMACHINE_PORT=4000
```

### Manual Installation

Install plugins inside a running container:

```bash
# List available plugins
/opt/desktop/scripts/plugin-manager.sh list

# Install a specific plugin
/opt/desktop/scripts/plugin-manager.sh vscode

# Install all configured plugins
/opt/desktop/scripts/plugin-manager.sh install
```

### Plugin Ordering

Plugins install in the order listed. Some have dependencies:

```bash
# claude-code needs Node.js; brew can provide it
PLUGINS=brew,claude-code
```

## Remote Access & Port Forwarding

The desktop can be accessed via multiple methods. KasmVNC is built-in; plugin methods require the corresponding plugin.

| Method | Protocol | Port | Plugin | Notes |
|--------|----------|------|--------|-------|
| KasmVNC | HTTP/WebSocket | 6901 | built-in | Web browser access, file transfer, audio |
| XRDP | RDP/TCP | 3389 | `xrdp` | Standard RDP clients (mstsc, Remmina, FreeRDP) |
| NoMachine | NX/TCP+UDP | 4000 | `nomachine` | NoMachine client required |

### Port Forwarding in Compose Files

KasmVNC ports are always exposed. XRDP and NoMachine ports are pre-configured in the compose file so they're ready when the plugins are enabled:

```yaml
# docker-compose.yml
ports:
  - "${XRDP_PORT:-3389}:3389"
  - "${NOMACHINE_PORT:-4000}:4000"
```

### Docker Socket Passthrough

The `docker` plugin runs Docker-in-Docker by default. Alternatively, mount the host Docker socket:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

## Plugin Directory Structure

Each plugin lives at `plugins/<name>/`:

```
plugins/
├── brew/
│   ├── init.sh       # Installation script
│   ├── tests.sh      # Automated tests
│   └── README.md     # Documentation
├── chrome/
├── claude-code/
├── cursor/
├── docker/
├── nomachine/
├── vscode/
├── xrdp/
└── ...
```

### Plugin Lifecycle

1. `entrypoint.sh` reads `PLUGINS` env var
2. For each plugin, `plugin-manager.sh` checks for a marker file at `/opt/desktop/plugins/.installed/<name>`
3. If no marker, runs `plugins/<name>/init.sh`
4. On success, creates the marker file (skips on next boot)
5. On failure, logs the error and continues to next plugin

## Remote Plugin Updates

On first boot (when `PLUGINS` is set), the plugin manager can fetch updated plugins from the repository via sparse-checkout:

```bash
# Manual update
/opt/desktop/scripts/plugin-manager.sh update
```

## Creating Custom Plugins

### Contract

`init.sh` must follow these rules:

- **Runs as root** (before `gosu` in entrypoint)
- **Environment available**: `USERNAME`, `HOME`, `DISPLAY` (from `env-setup.sh`)
- **Must be idempotent** — check if already installed, skip if so
- **Desktop shortcuts** go in `$HOME/Desktop/`, `chown` to user
- **Logs** to `/var/log/plugin-manager.log`
- **Exit 0** on success, non-zero on failure (non-fatal to container)

### Example Plugin

```bash
#!/bin/bash
# plugins/myapp/init.sh
set -e

source /opt/desktop/scripts/env-setup.sh

LOG_FILE="/var/log/plugin-manager.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [myapp] $1" | tee -a "$LOG_FILE"; }

# Idempotency check
if command -v myapp &>/dev/null; then
    log "MyApp is already installed"
    exit 0
fi

log "Installing MyApp..."

# Installation logic here
apt-get update
apt-get install -y myapp
rm -rf /var/lib/apt/lists/*

# Desktop shortcut
cat > "${HOME}/Desktop/MyApp.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=MyApp
Exec=/usr/bin/myapp
Icon=myapp
Terminal=false
EOF
chmod +x "${HOME}/Desktop/MyApp.desktop"
chown "${USERNAME}:${USERNAME}" "${HOME}/Desktop/MyApp.desktop"

log "MyApp installed successfully"
```

### Testing

```bash
# Test a specific plugin
/opt/desktop/scripts/plugin-manager.sh test myapp

# Test plugins in isolated containers
./scripts/test-plugins.sh myapp --verbose
```

## Backward Compatibility

The old `ENABLE_*` environment variables still work but are deprecated:

```bash
# Old style (deprecated)
ENABLE_VSCODE=true
ENABLE_XRDP=true

# New style
PLUGINS=vscode,xrdp
```

When `ENABLE_*` variables are detected, the plugin manager converts them to the `PLUGINS` list and logs a deprecation warning.

## Troubleshooting

### Plugin installation fails

1. Check logs: `cat /var/log/plugin-manager.log`
2. Check network: `ping -c 1 google.com`
3. Check disk space: `df -h /`

### Plugin installs every restart

The marker file at `/opt/desktop/plugins/.installed/<name>` may be missing. This happens if the plugins directory is on a non-persistent volume.

### Force reinstall

Remove the marker file and restart:

```bash
rm /opt/desktop/plugins/.installed/vscode
/opt/desktop/scripts/plugin-manager.sh install
```

## Plugin Installation Logs

```bash
# View all logs
cat /var/log/plugin-manager.log

# Follow in real-time
tail -f /var/log/plugin-manager.log
```
