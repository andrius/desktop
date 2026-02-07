#!/bin/bash
# Start KasmVNC server (runs as non-root user via gosu)
set -e

source /opt/desktop/scripts/env-setup.sh

# Start PulseAudio for audio support (runs as current user)
echo "Starting PulseAudio..."
pulseaudio --start --exit-idle-time=-1 2>/dev/null || true

# KasmVNC configuration
# Note: Internal ports are fixed; external port mapping is handled by docker-compose
VNC_DISPLAY="${DISPLAY:-:1}"
VNC_INTERNAL_PORT=5901
VNC_INTERNAL_WEB_PORT=6901
VNC_RESOLUTION="${VNC_RESOLUTION:-1920x1080}"
VNC_COL_DEPTH="${VNC_COL_DEPTH:-24}"
VNC_PW="${VNC_PW:-vncpassword}"

HOME="${HOME:-/home/${USERNAME}}"
VNC_DIR="${HOME}/.vnc"

# Create VNC directory
mkdir -p "${VNC_DIR}"

# Optional SSL support
KASMVNC_ENABLE_SSL="${KASMVNC_ENABLE_SSL:-false}"
SSL_REQUIRE="false"
SSL_PEM=""
if [ "$KASMVNC_ENABLE_SSL" = "true" ]; then
    SSL_CERT="${VNC_DIR}/self.pem"
    if [ ! -f "$SSL_CERT" ]; then
        openssl req -x509 -nodes -days 3650 \
            -newkey rsa:2048 -keyout "$SSL_CERT" -out "$SSL_CERT" \
            -subj "/CN=desktop" 2>/dev/null
    fi
    SSL_REQUIRE="true"
    SSL_PEM="$SSL_CERT"
fi

echo "Starting KasmVNC server..."
echo "  Display: ${VNC_DISPLAY}"
echo "  Resolution: ${VNC_RESOLUTION}"
echo "  VNC Port: ${VNC_INTERNAL_PORT}"
echo "  Web Port: ${VNC_INTERNAL_WEB_PORT}"
if [ "$KASMVNC_ENABLE_SSL" = "true" ]; then
    echo "  SSL: enabled (self-signed)"
fi

# Set VNC password using KasmVNC syntax
# KasmVNC uses user-based authentication
echo -e "${VNC_PW}\n${VNC_PW}\n" | vncpasswd -u "${USERNAME}" -o -w
chmod 600 "${VNC_DIR}/kasmpasswd" 2>/dev/null || true

# Pre-select XFCE to avoid interactive prompt
mkdir -p "${HOME}/.config/kasmvnc"
echo "xfce" > "${HOME}/.config/kasmvnc/.de"
echo "xfce" > "${HOME}/.vnc/.de"

# Create xstartup script
cat > "${VNC_DIR}/xstartup" << 'EOF'
#!/bin/bash
# KasmVNC xstartup script

# Load user profile
[ -r $HOME/.profile ] && . $HOME/.profile

# Set up environment
export XDG_SESSION_TYPE=x11
export XDG_RUNTIME_DIR="/tmp/runtime-${USER}"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_CACHE_HOME="${HOME}/.cache"

# Start D-Bus session
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax)
    export DBUS_SESSION_BUS_ADDRESS
fi

# Start XFCE4 desktop environment
exec startxfce4
EOF
chmod +x "${VNC_DIR}/xstartup"

# Create KasmVNC configuration — write to both system and user locations
# The user config (~/.vnc/kasmvnc.yaml) takes precedence over system config,
# and vncserver auto-creates it from defaults if missing, so we must write both.
mkdir -p "${HOME}/.config/kasmvnc"
KASMVNC_CONFIG="desktop:
  resolution:
    width: $(echo ${VNC_RESOLUTION} | cut -d'x' -f1)
    height: $(echo ${VNC_RESOLUTION} | cut -d'x' -f2)
  allow_resize: true

network:
  protocol: http
  interface: 0.0.0.0
  websocket_port: ${VNC_INTERNAL_WEB_PORT}
  ssl:
    require_ssl: ${SSL_REQUIRE}
    pem_certificate: ${SSL_PEM}

user_session:
  session_type: shared

encoding:
  max_frame_rate: 60

server:
  http:
    httpd_directory: /usr/share/kasmvnc/www"

echo "$KASMVNC_CONFIG" | sudo tee /etc/kasmvnc/kasmvnc.yaml > /dev/null
echo "$KASMVNC_CONFIG" > "${VNC_DIR}/kasmvnc.yaml"

# Clean up any existing VNC locks (may be root-owned from previous run)
sudo rm -f /tmp/.X*-lock /tmp/.X11-unix/X* 2>/dev/null || true

# Start KasmVNC server with select-de flag to avoid interactive prompt
echo "Launching vncserver..."
export SELECT_DE=xfce
vncserver ${VNC_DISPLAY} \
    -depth ${VNC_COL_DEPTH} \
    -geometry ${VNC_RESOLUTION} \
    -websocketPort ${VNC_INTERNAL_WEB_PORT} \
    -httpd /usr/share/kasmvnc/www \
    -interface 0.0.0.0 \
    -disableBasicAuth \
    -select-de xfce \
    -fg

# Keep container running
wait
