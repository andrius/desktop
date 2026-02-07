# Debian Docker Desktop

A fully-featured Debian 13 (Trixie) desktop environment running in Docker with web-based remote access. Choose between **KasmVNC** or **Selkies WebRTC** for remote desktop access.

## Features

- **Debian 13 Trixie** base with lightweight init (tini/dumb-init, no systemd)
- **XFCE4** desktop environment
- **Homebrew** package manager
- **Firefox ESR** pre-installed
- **Two VNC variants**:
  - **KasmVNC**: Web-based VNC with file transfer, audio, and clipboard support
  - **Selkies**: WebRTC-based streaming with lower latency
- **Plugin system** for optional software installation
- **Configurable** via environment variables
- **Passwordless sudo** for the desktop user

## Quick Start

### Using KasmVNC (Recommended)

```bash
# Clone the repository
git clone <repository-url>
cd debian-docker-desktop

# Copy and configure environment
cp .env.example .env

# Start the container
docker compose -f docker-compose.kasmvnc.yml up -d

# Access the desktop at http://localhost:6901
```

### Using Selkies WebRTC

```bash
# Start the Selkies variant
docker compose -f docker-compose.selkies.yml up -d

# Access the desktop at http://localhost:8080
```

## Configuration

Copy `.env.example` to `.env` and customize the settings:

```bash
cp .env.example .env
```

### Key Configuration Options

| Variable | Default | Description |
|----------|---------|-------------|
| `USERNAME` | `user` | Desktop username |
| `RESOLUTION` | `1920x1080x24` | Screen resolution |
| `TZ` | `UTC` | Timezone |
| `VNC_PW` | `vncpassword` | VNC password (KasmVNC) |
| `VNC_WEB_PORT` | `6901` | KasmVNC web port |
| `SELKIES_WEB_PORT` | `8080` | Selkies web port |

### Plugin Configuration

Enable optional software via the `PLUGINS` environment variable (comma-separated):

```bash
PLUGINS=brew,vscode,cursor
```

## Available Plugins

| Plugin | Description |
|--------|-------------|
| `brew` | Homebrew package manager |
| `chrome` | Google Chrome browser (amd64 only) |
| `xrdp` | XRDP remote desktop (port 3389) |
| `nomachine` | NoMachine remote desktop (port 4000) |
| `cursor` | Cursor AI code editor |
| `vscode` | Visual Studio Code |
| `claude-code` | Claude Code CLI |
| `docker` | Docker Engine (DinD) |

Each plugin is a self-contained directory with `init.sh`, `tests.sh`, and `README.md`. Plugins install on first boot and are skipped on restart.

### Manual Plugin Installation

```bash
# List available plugins
/opt/desktop/scripts/plugin-manager.sh list

# Install a specific plugin
/opt/desktop/scripts/plugin-manager.sh vscode

# Test a plugin
/opt/desktop/scripts/plugin-manager.sh test vscode
```

### Plugin Testing

```bash
# Test plugins in isolated containers
./scripts/test-plugins.sh brew vscode --verbose

# Test all plugins
./scripts/test-plugins.sh --all --verbose
```

## Image Variants

### KasmVNC

- **Best for**: General use, file transfer needs, enterprise deployments
- **Port**: 6901 (web), 5901 (VNC)
- **Features**: File upload/download, clipboard sync, audio streaming
- **Access**: `http://localhost:6901`

### Selkies WebRTC

- **Best for**: Low-latency requirements, real-time applications
- **Port**: 8080
- **Features**: WebRTC streaming, hardware acceleration support
- **Access**: `http://localhost:8080`
- **Note**: May require TURN server for NAT traversal

## Port Forwarding

| Service | Port | Protocol | Notes |
|---------|------|----------|-------|
| KasmVNC Web | 6901 | HTTP/WebSocket | Built-in, always available |
| Selkies Web | 8080 | WebRTC | Built-in, may need TURN server |
| XRDP | 3389 | RDP/TCP | Requires `xrdp` plugin |
| NoMachine | 4000 | NX/TCP+UDP | Requires `nomachine` plugin |

XRDP and NoMachine ports are pre-configured in all compose files. Enable the corresponding plugin to activate the service.

## Building Images

### Build Locally

```bash
# Build KasmVNC variant
docker compose -f docker-compose.kasmvnc.yml build

# Build Selkies variant
docker compose -f docker-compose.selkies.yml build
```

### Using GitHub Actions

The repository includes GitHub Actions workflows that automatically build and push images to GitHub Container Registry on:
- Push to main/master branch
- Pull requests
- Weekly schedule (security updates)
- Manual trigger

## Maintenance

### System Updates

```bash
# Enter the container
docker exec -it debian-desktop-kasmvnc bash

# Run system update
/opt/desktop/scripts/maintenance/update-system.sh
```

### Cleanup

```bash
# Clean temporary files and caches
/opt/desktop/scripts/maintenance/cleanup.sh
```

### Health Check

```bash
# Check system health
/opt/desktop/scripts/maintenance/health-check.sh
```

## Directory Structure

```
.
├── docker/
│   ├── base/           # Shared base scripts (canonical source)
│   │   └── scripts/    # env-setup.sh, init-user.sh, plugin-manager.sh
│   ├── kasmvnc/        # KasmVNC variant
│   │   ├── Dockerfile
│   │   ├── scripts/
│   │   └── configs/
│   └── selkies/        # Selkies variant
│       ├── Dockerfile
│       ├── scripts/
│       └── configs/
├── plugins/            # Plugin system (each has init.sh, tests.sh, README.md)
│   ├── brew/
│   ├── chrome/
│   ├── claude-code/
│   ├── cursor/
│   ├── docker/
│   ├── nomachine/
│   ├── vscode/
│   └── xrdp/
├── scripts/
│   ├── test-image.sh       # Integration test script
│   └── test-plugins.sh     # Plugin test runner
├── docs/                    # Documentation
├── .github/
│   └── workflows/           # GitHub Actions workflows
├── docker-compose.yml              # Combined compose (profiles)
├── docker-compose.kasmvnc.yml     # KasmVNC-specific compose
├── docker-compose.selkies.yml     # Selkies-specific compose
├── .env.example                    # Environment template
└── README.md
```

## Pre-installed Software

- XFCE4 desktop environment
- Firefox ESR browser
- Xfce4-terminal
- Thunar file manager
- Basic development tools (git, vim, nano, curl, wget)
- Homebrew package manager
- Mesa OpenGL utilities
- PulseAudio (audio support)

## Troubleshooting

### Cannot connect to VNC

1. Check if the container is running: `docker ps`
2. Check container logs: `docker logs debian-desktop-kasmvnc`
3. Verify ports are not in use: `netstat -tlnp | grep 6901`

### Slow performance

1. Increase shared memory: Add `--shm-size=2g` or use the compose file
2. Lower resolution in `.env`
3. For Selkies, try a different encoder (x264enc, vp8enc)

### Plugins not installing

1. Check internet connectivity inside container
2. View plugin manager logs: `cat /var/log/plugin-manager.log`
3. Try manual installation: `/opt/desktop/scripts/plugin-manager.sh <plugin>`

### Display issues

1. Check X server: `docker exec debian-desktop-kasmvnc pgrep Xvfb`
2. Verify display variable: `docker exec debian-desktop-kasmvnc echo $DISPLAY`
3. Restart the container

## Security Considerations

- Change the default VNC password in production
- Consider using HTTPS/TLS termination with a reverse proxy
- The container runs with `seccomp:unconfined` for desktop functionality
- Use network isolation in production environments
- Regularly update the container for security patches

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please read the contributing guidelines and submit pull requests.

## Acknowledgments

- [KasmVNC](https://github.com/kasmtech/KasmVNC) - Kasm Technologies
- [Selkies GStreamer](https://github.com/selkies-project/selkies-gstreamer) - Selkies Project
- [Homebrew](https://brew.sh/) - Homebrew contributors
- [XFCE](https://xfce.org/) - XFCE Development Team
