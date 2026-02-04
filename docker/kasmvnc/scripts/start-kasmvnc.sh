#!/bin/bash
# Start KasmVNC server
set -e

source /opt/desktop/scripts/env-setup.sh

# KasmVNC configuration
VNC_DISPLAY="${DISPLAY:-:1}"
VNC_PORT="${VNC_PORT:-5901}"
VNC_WEB_PORT="${VNC_WEB_PORT:-6901}"
VNC_RESOLUTION="${VNC_RESOLUTION:-1920x1080}"
VNC_COL_DEPTH="${VNC_COL_DEPTH:-24}"
VNC_PW="${VNC_PW:-vncpassword}"

HOME="${HOME:-/home/${USERNAME}}"
VNC_DIR="${HOME}/.vnc"

echo "Starting KasmVNC server..."
echo "  Display: ${VNC_DISPLAY}"
echo "  Resolution: ${VNC_RESOLUTION}"
echo "  VNC Port: ${VNC_PORT}"
echo "  Web Port: ${VNC_WEB_PORT}"

# Create VNC directory
mkdir -p "${VNC_DIR}"

# Set VNC password
echo "${VNC_PW}" | vncpasswd -f > "${VNC_DIR}/passwd"
chmod 600 "${VNC_DIR}/passwd"

# Set view-only password if specified
if [ -n "${VNC_VIEW_ONLY_PW}" ]; then
    echo "${VNC_VIEW_ONLY_PW}" | vncpasswd -f >> "${VNC_DIR}/passwd"
fi

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

# Create KasmVNC configuration
mkdir -p "${HOME}/.config/kasmvnc"
cat > "${HOME}/.config/kasmvnc/kasmvnc.yaml" << EOF
desktop:
  resolution:
    width: $(echo ${VNC_RESOLUTION} | cut -d'x' -f1)
    height: $(echo ${VNC_RESOLUTION} | cut -d'x' -f2)
  allow_resize: true

network:
  protocol: http
  interface: 0.0.0.0
  websocket_port: ${VNC_WEB_PORT}
  ssl:
    pem_certificate:
    pem_key:
    require_ssl: false

user_session:
  session_type: xfce

server:
  http_server_enable: true
  http_server_path: /usr/share/kasmvnc/www/

encoding:
  max_frame_rate: 60
  rect_encoding_mode:
    min_quality: 5
    max_quality: 9
  video_encoding_mode:
    jpeg_quality: -1
    webp_quality: -1
    max_resolution:
      width: 1920
      height: 1080
    enter_video_mode_factor: 5
    enter_video_mode_area_fraction: 50
    exit_video_mode_area_fraction: 35
    logging:
      level: off
    scaling_algorithm: progressive_bilinear

security:
  authentication:
    type: vnc
EOF

# Clean up any existing VNC locks
rm -f /tmp/.X*-lock /tmp/.X11-unix/X* 2>/dev/null || true

# Start KasmVNC server
echo "Launching vncserver..."
vncserver ${VNC_DISPLAY} \
    -depth ${VNC_COL_DEPTH} \
    -geometry ${VNC_RESOLUTION} \
    -websocketPort ${VNC_WEB_PORT} \
    -httpd /usr/share/kasmvnc/www \
    -interface 0.0.0.0 \
    -disableBasicAuth \
    -fg

# Keep container running
wait
