# Configuration Guide

This guide covers all configuration options for the Debian Docker Desktop.

## Environment Variables

### User Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `USERNAME` | `user` | Username for the desktop user |
| `USER_UID` | `1000` | User ID (for volume permissions) |
| `USER_GID` | `1000` | Group ID (for volume permissions) |

### Display Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `DISPLAY` | `:1` | X display number |
| `RESOLUTION` | `1920x1080x24` | Screen resolution (WIDTHxHEIGHTxDEPTH) |
| `TZ` | `UTC` | Timezone (e.g., `America/New_York`) |

### KasmVNC Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `VNC_PORT` | `5901` | VNC protocol port |
| `VNC_WEB_PORT` | `6901` | Web interface port |
| `VNC_PW` | `vncpassword` | VNC password |
| `VNC_VIEW_ONLY_PW` | (empty) | View-only password (optional) |
| `VNC_RESOLUTION` | `1920x1080` | VNC resolution |
| `VNC_COL_DEPTH` | `24` | Color depth (16, 24, 32) |
| `KASM_SVC_AUDIO` | `1` | Enable audio streaming |
| `KASM_SVC_AUDIO_INPUT` | `1` | Enable audio input |
| `KASM_SVC_UPLOADS` | `1` | Enable file uploads |
| `KASM_SVC_DOWNLOADS` | `1` | Enable file downloads |

### Selkies Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `SELKIES_WEB_PORT` | `8080` | Web interface port |
| `SELKIES_ENCODER` | `x264enc` | Video encoder |
| `SELKIES_ENABLE_RESIZE` | `true` | Allow window resizing |
| `SELKIES_ENABLE_BASIC_AUTH` | `false` | Enable HTTP basic auth |
| `SELKIES_BASIC_AUTH_USER` | (empty) | Basic auth username |
| `SELKIES_BASIC_AUTH_PASSWORD` | (empty) | Basic auth password |
| `FRAMERATE` | `30` | Target frame rate |

#### Selkies TURN Server (for NAT traversal)

| Variable | Default | Description |
|----------|---------|-------------|
| `SELKIES_TURN_HOST` | (empty) | TURN server hostname |
| `SELKIES_TURN_PORT` | (empty) | TURN server port |
| `SELKIES_TURN_USERNAME` | (empty) | TURN username |
| `SELKIES_TURN_PASSWORD` | (empty) | TURN password |
| `SELKIES_TURN_PROTOCOL` | `udp` | TURN protocol (udp/tcp) |

### Plugin Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PLUGINS` | (empty) | Comma-separated list of plugins to install (e.g. `brew,vscode,cursor`) |
| `XRDP_PORT` | `3389` | Host port for XRDP (when xrdp plugin is enabled) |
| `NOMACHINE_PORT` | `4000` | Host port for NoMachine (when nomachine plugin is enabled) |

Available plugins: `brew`, `chrome`, `xrdp`, `nomachine`, `cursor`, `vscode`, `claude-code`, `docker`

### Homebrew Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `HOMEBREW_NO_AUTO_UPDATE` | `1` | Disable auto-updates |
| `HOMEBREW_NO_ANALYTICS` | `1` | Disable analytics |

## Configuration Files

### .env File

Create your configuration by copying the example:

```bash
cp .env.example .env
```

Example `.env` file:

```bash
# User
USERNAME=developer
USER_UID=1000
USER_GID=1000

# Display
RESOLUTION=2560x1440x24
TZ=America/New_York

# KasmVNC
VNC_PW=mysecurepassword
VNC_WEB_PORT=6901

# Plugins
PLUGINS=vscode,cursor
```

### XFCE4 Configuration

XFCE4 configuration is stored in `~/.config/xfce4/`. Key files:

- `xfconf/xfce-perchannel-xml/xfce4-session.xml` - Session settings
- `xfconf/xfce-perchannel-xml/xfce4-panel.xml` - Panel configuration
- `xfconf/xfce-perchannel-xml/xfwm4.xml` - Window manager settings
- `xfconf/xfce-perchannel-xml/xsettings.xml` - General settings

### VNC Configuration

#### KasmVNC

Configuration file: `~/.config/kasmvnc/kasmvnc.yaml`

```yaml
desktop:
  resolution:
    width: 1920
    height: 1080
  allow_resize: true

network:
  protocol: http
  interface: 0.0.0.0
  websocket_port: 6901
  ssl:
    require_ssl: false

encoding:
  max_frame_rate: 60
```

#### Selkies

Configuration is primarily via environment variables. For advanced configuration, modify `/opt/desktop/scripts/start-selkies.sh`.

## Common Configurations

### High-Resolution Display

```bash
RESOLUTION=2560x1440x24
VNC_RESOLUTION=2560x1440
```

### Low-Bandwidth Mode

```bash
RESOLUTION=1280x720x16
VNC_COL_DEPTH=16
FRAMERATE=15
SELKIES_ENCODER=vp8enc
```

### Development Setup

```bash
USERNAME=developer
PLUGINS=brew,vscode,cursor,claude-code
```

### Secure Setup

```bash
VNC_PW=very_secure_password_here
SELKIES_ENABLE_BASIC_AUTH=true
SELKIES_BASIC_AUTH_USER=admin
SELKIES_BASIC_AUTH_PASSWORD=secure_password
```

### Custom Timezone

```bash
TZ=Europe/London      # UK
TZ=America/New_York   # US Eastern
TZ=America/Los_Angeles # US Pacific
TZ=Asia/Tokyo         # Japan
TZ=Europe/Berlin      # Germany
```

## Docker Compose Overrides

For additional customization, create a `docker-compose.override.yml`:

```yaml
services:
  desktop:
    # Add GPU support (NVIDIA)
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

    # Additional volumes
    volumes:
      - ./projects:/home/user/projects
      - ~/.ssh:/home/user/.ssh:ro

    # Additional environment
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute
```

## Port Mapping

### Default Ports

| Service | Internal | Default External | Variable |
|---------|----------|------------------|----------|
| KasmVNC Web | 6901 | 6901 | `VNC_WEB_PORT` |
| KasmVNC VNC | 5901 | 5901 | `VNC_PORT` |
| Selkies Web | 8080 | 8080 | `SELKIES_WEB_PORT` |
| XRDP | 3389 | 3389 | `XRDP_PORT` |
| NoMachine | 4000 | 4000 | `NOMACHINE_PORT` |

### Custom Port Mapping

In `docker-compose.yml` or command line:

```yaml
ports:
  - "8443:6901"  # Access KasmVNC at localhost:8443
  - "5900:5901"  # Access VNC at localhost:5900
```

Or via command line:

```bash
docker run -p 8443:6901 -p 5900:5901 debian-desktop:kasmvnc
```

## Volume Configuration

### Default Volumes

```yaml
volumes:
  - desktop-home:/home/${USERNAME:-user}
```

### Additional Volume Mounts

```yaml
volumes:
  # Persist home directory
  - desktop-home:/home/user

  # Mount host directory
  - /path/on/host:/home/user/shared

  # Mount SSH keys (read-only)
  - ~/.ssh:/home/user/.ssh:ro

  # Mount Docker socket (for Docker-in-Docker)
  - /var/run/docker.sock:/var/run/docker.sock
```

## Resource Limits

### Memory

```yaml
services:
  desktop:
    mem_limit: 4g
    memswap_limit: 4g
    shm_size: 2g
```

### CPU

```yaml
services:
  desktop:
    cpus: '2.0'
    cpu_shares: 1024
```

### Combined Example

```yaml
services:
  desktop:
    deploy:
      resources:
        limits:
          cpus: '4.0'
          memory: 8G
        reservations:
          cpus: '2.0'
          memory: 4G
    shm_size: 2g
```
