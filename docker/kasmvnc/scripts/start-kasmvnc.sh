#!/bin/bash
# Start KasmVNC server
set -e

source /opt/desktop/scripts/env-setup.sh

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

echo "Starting KasmVNC server..."
echo "  Display: ${VNC_DISPLAY}"
echo "  Resolution: ${VNC_RESOLUTION}"
echo "  VNC Port: ${VNC_INTERNAL_PORT}"
echo "  Web Port: ${VNC_INTERNAL_WEB_PORT}"

# Create VNC directory
mkdir -p "${VNC_DIR}"

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

# Create KasmVNC configuration - minimal config to disable SSL
mkdir -p "${HOME}/.config/kasmvnc"
# Update system config to ensure SSL settings are applied
sudo tee /etc/kasmvnc/kasmvnc.yaml > /dev/null << EOF
desktop:
  resolution:
    width: $(echo ${VNC_RESOLUTION} | cut -d'x' -f1)
    height: $(echo ${VNC_RESOLUTION} | cut -d'x' -f2)
  allow_resize: true

network:
  protocol: http
  interface: 0.0.0.0
  websocket_port: ${VNC_INTERNAL_WEB_PORT}
  ssl:
    require_ssl: false

user_session:
  session_type: shared

encoding:
  max_frame_rate: 60

server:
  http:
    httpd_directory: /usr/share/kasmvnc/www
EOF

# Clean up any existing VNC locks
rm -f /tmp/.X*-lock /tmp/.X11-unix/X* 2>/dev/null || true

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
