#!/bin/bash
# Initialize user environment
set -e

USERNAME="${USERNAME:-user}"
HOME="/home/${USERNAME}"

echo "Initializing user environment for: ${USERNAME}"

# Detect installed file manager for desktop shortcut
if command -v pcmanfm >/dev/null 2>&1; then
    FILE_MANAGER="pcmanfm"
elif command -v thunar >/dev/null 2>&1; then
    FILE_MANAGER="thunar"
else
    FILE_MANAGER="xdg-open"
fi
echo "Detected file manager: ${FILE_MANAGER}"

# Ensure user directories exist
mkdir -p "${HOME}/.config/xfce4" \
         "${HOME}/.local/share" \
         "${HOME}/.local/bin" \
         "${HOME}/.cache" \
         "${HOME}/Desktop" \
         "${HOME}/Downloads" \
         "${HOME}/Documents" \
         "${HOME}/Pictures" \
         "${HOME}/Videos" \
         "${HOME}/Music"

# Create XDG runtime directory
export XDG_RUNTIME_DIR="/tmp/runtime-${USERNAME}"
mkdir -p "${XDG_RUNTIME_DIR}"
chmod 700 "${XDG_RUNTIME_DIR}"

# Set up XFCE4 configuration if not exists
if [ ! -f "${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml" ]; then
    mkdir -p "${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml"

    # Create basic XFCE4 session configuration
    # Note: Client2 must be Thunar --daemon because xfdesktop depends on
    # Thunar's D-Bus service (org.xfce.FileManager) to launch .desktop files.
    # The user-facing file manager (Exec= in .desktop shortcut) can differ.
    cat > "${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-session" version="1.0">
  <property name="general" type="empty">
    <property name="FailsafeSessionName" type="string" value="Failsafe"/>
    <property name="SessionName" type="string" value="Default"/>
    <property name="SaveOnExit" type="bool" value="false"/>
    <property name="AutoSave" type="bool" value="false"/>
  </property>
  <property name="sessions" type="empty">
    <property name="Failsafe" type="empty">
      <property name="IsFailsafe" type="bool" value="true"/>
      <property name="Count" type="int" value="5"/>
      <property name="Client0_Command" type="array">
        <value type="string" value="xfwm4"/>
      </property>
      <property name="Client0_PerScreen" type="bool" value="false"/>
      <property name="Client1_Command" type="array">
        <value type="string" value="xfce4-panel"/>
      </property>
      <property name="Client1_PerScreen" type="bool" value="false"/>
      <property name="Client2_Command" type="array">
        <value type="string" value="Thunar"/>
        <value type="string" value="--daemon"/>
      </property>
      <property name="Client2_PerScreen" type="bool" value="false"/>
      <property name="Client3_Command" type="array">
        <value type="string" value="xfdesktop"/>
      </property>
      <property name="Client3_PerScreen" type="bool" value="false"/>
      <property name="Client4_Command" type="array">
        <value type="string" value="xfce4-notifyd"/>
      </property>
      <property name="Client4_PerScreen" type="bool" value="false"/>
    </property>
  </property>
</channel>
EOF
fi

# Set up desktop panel configuration if not exists
if [ ! -f "${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" ]; then
    cat > "${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="dark-mode" type="bool" value="true"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="icon-size" type="uint" value="16"/>
      <property name="size" type="uint" value="26"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu"/>
    <property name="plugin-2" type="string" value="tasklist"/>
    <property name="plugin-3" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-4" type="string" value="systray"/>
    <property name="plugin-5" type="string" value="clock"/>
    <property name="plugin-6" type="string" value="actions"/>
  </property>
</channel>
EOF
fi

# Set up xsettings (GTK + icon theme: Adwaita-dark)
if [ ! -f "${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" ]; then
    cat > "${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Adwaita-dark"/>
    <property name="IconThemeName" type="string" value="Adwaita"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="CursorThemeName" type="string" value="Adwaita"/>
  </property>
</channel>
EOF
fi

# Set up desktop background (solid space gray #3d3d3d)
# Include both monitorscreen and monitorVNC-0 paths since KasmVNC
# creates a display named "VNC-0" (xfdesktop uses "monitor" + xrandr name)
if [ ! -f "${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" ]; then
    cat > "${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorscreen" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="0"/>
          <property name="rgba1" type="array">
            <value type="double" value="0.23921568627"/>
            <value type="double" value="0.23921568627"/>
            <value type="double" value="0.23921568627"/>
            <value type="double" value="1.0"/>
          </property>
        </property>
      </property>
      <property name="monitorVNC-0" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="0"/>
          <property name="rgba1" type="array">
            <value type="double" value="0.23921568627"/>
            <value type="double" value="0.23921568627"/>
            <value type="double" value="0.23921568627"/>
            <value type="double" value="1.0"/>
          </property>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF
fi

# Set up dark terminal theme
if [ ! -f "${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml" ]; then
    cat > "${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-terminal" version="1.0">
  <property name="color-background" type="string" value="#1e1e1e"/>
  <property name="color-foreground" type="string" value="#d4d4d4"/>
  <property name="color-use-theme" type="bool" value="false"/>
</channel>
EOF
fi

# Create Firefox launcher wrapper (handles sandbox and root-user mismatch in Docker)
cat > /opt/desktop/scripts/firefox-launcher.sh << SCRIPT
#!/bin/bash
export MOZ_DISABLE_CONTENT_SANDBOX=1
export MOZ_ENABLE_WAYLAND=0
export HOME="${HOME}"
if [ "\$(id -u)" = "0" ] && id "${USERNAME}" >/dev/null 2>&1; then
    exec sudo -u "${USERNAME}" firefox-esr "\$@"
else
    exec firefox-esr "\$@"
fi
SCRIPT
chmod +x /opt/desktop/scripts/firefox-launcher.sh

# Create universal browser launcher (handles sandbox flags for Docker)
# Detects Chrome or Firefox at runtime — Chrome is a plugin installed after init
cat > /opt/desktop/scripts/browser-launcher.sh << 'LAUNCHER'
#!/bin/bash
if command -v google-chrome-stable >/dev/null 2>&1; then
    exec google-chrome-stable "$@"
elif command -v firefox-esr >/dev/null 2>&1; then
    exec /opt/desktop/scripts/firefox-launcher.sh "$@"
else
    echo "No supported browser found" >&2
    exit 1
fi
LAUNCHER
chmod +x /opt/desktop/scripts/browser-launcher.sh

# Register browser-launcher as system default browser

# .desktop entry for xdg-open / mimeapps
mkdir -p "${HOME}/.local/share/applications"
cat > "${HOME}/.local/share/applications/browser-launcher.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Default Browser
Comment=Open URL in the default browser
Exec=/opt/desktop/scripts/browser-launcher.sh %u
Icon=web-browser
Terminal=false
Categories=Network;WebBrowser;
MimeType=x-scheme-handler/http;x-scheme-handler/https;text/html;
EOF

# Default MIME handler for HTTP/HTTPS URLs
mkdir -p "${HOME}/.config"
cat > "${HOME}/.config/mimeapps.list" << 'EOF'
[Default Applications]
x-scheme-handler/http=browser-launcher.desktop
x-scheme-handler/https=browser-launcher.desktop
text/html=browser-launcher.desktop
EOF

# XFCE preferred applications helper
mkdir -p "${HOME}/.local/share/xfce4/helpers"
cat > "${HOME}/.local/share/xfce4/helpers/custom-WebBrowser.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=X-XFCE-Helper
Name=Default Browser
Icon=web-browser
X-XFCE-Binaries=browser-launcher.sh
X-XFCE-Category=WebBrowser
X-XFCE-Commands=/opt/desktop/scripts/browser-launcher.sh;
X-XFCE-CommandsWithParameter=/opt/desktop/scripts/browser-launcher.sh "%s";
EOF

mkdir -p "${HOME}/.config/xfce4"
cat > "${HOME}/.config/xfce4/helpers.rc" << 'EOF'
WebBrowser=custom-WebBrowser
EOF

# Register as x-www-browser alternative (priority 300 beats Firefox 100, Chrome 200)
update-alternatives --install /usr/bin/x-www-browser x-www-browser /opt/desktop/scripts/browser-launcher.sh 300

# Ensure BROWSER env is available in interactive shells and XFCE session
for rc_file in "${HOME}/.bashrc" "${HOME}/.profile"; do
    touch "$rc_file"
    if ! grep -q 'BROWSER=' "$rc_file" 2>/dev/null; then
        echo 'export BROWSER="/opt/desktop/scripts/browser-launcher.sh"' >> "$rc_file"
    fi
done

# Create desktop shortcuts
cat > "${HOME}/Desktop/Firefox.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox
Comment=Browse the Web
Exec=/opt/desktop/scripts/firefox-launcher.sh
Icon=firefox-esr
Terminal=false
Categories=Network;WebBrowser;
EOF

cat > "${HOME}/Desktop/Terminal.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal
Comment=Use the command line
Exec=xfce4-terminal
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
EOF

cat > "${HOME}/Desktop/File Manager.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=File Manager
Comment=Browse the filesystem
Exec=${FILE_MANAGER}
Icon=system-file-manager
Terminal=false
Categories=System;FileManager;
EOF

# Create autostart entry to set up desktop on session start
# This runs after D-Bus session is available, enabling:
# - xhost for user-process X display access (needed by Firefox launcher)
# - metadata::trusted on .desktop files (needed by xfdesktop to launch them)
mkdir -p "${HOME}/.config/autostart"
cat > "${HOME}/.config/autostart/desktop-setup.desktop" << AUTOSTART
[Desktop Entry]
Type=Application
Name=Desktop Setup
Exec=/opt/desktop/scripts/desktop-setup.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
AUTOSTART

cat > /opt/desktop/scripts/desktop-setup.sh << SETUP
#!/bin/bash
# Wait for gvfsd-metadata to start (required for gio set metadata::trusted)
for i in \$(seq 1 15); do
    pgrep -u "\$(whoami)" gvfsd-metadata >/dev/null 2>&1 && break
    sleep 1
done

# Allow local user connections to X display (needed for sudo -u user apps)
xhost +local: 2>/dev/null || true

# Mark desktop shortcuts as trusted so xfdesktop can execute them
# XFCE 4.18+ uses metadata::xfce-exe-checksum (SHA256) to verify trust
if command -v gio >/dev/null 2>&1; then
    for f in "${HOME}/Desktop/"*.desktop; do
        if [ -f "\$f" ]; then
            CHECKSUM=\$(sha256sum "\$f" | cut -d' ' -f1)
            gio set "\$f" metadata::xfce-exe-checksum "\$CHECKSUM" 2>/dev/null || true
            gio set "\$f" metadata::trusted true 2>/dev/null || true
        fi
    done
fi

# Set desktop background color via xfconf-query
# xfdesktop uses "monitor" + xrandr output name (e.g., monitorVNC-0)
if command -v xfconf-query >/dev/null 2>&1; then
    set_backdrop() {
        local ws_path="\$1"
        xfconf-query -c xfce4-desktop -n -t int -p "\${ws_path}/color-style" -s 0 2>/dev/null || true
        xfconf-query -c xfce4-desktop -n -t int -p "\${ws_path}/image-style" -s 0 2>/dev/null || true
        xfconf-query -c xfce4-desktop -n \
            -p "\${ws_path}/rgba1" \
            -t double -t double -t double -t double \
            -s 0.23921568627 -s 0.23921568627 -s 0.23921568627 -s 1.0 2>/dev/null || true
    }

    # Detect monitor name from xrandr (e.g., VNC-0)
    XRANDR_MONITOR=\$(xrandr 2>/dev/null | grep ' connected' | awk '{print \$1}' | head -1)
    if [ -n "\$XRANDR_MONITOR" ]; then
        set_backdrop "/backdrop/screen0/monitor\${XRANDR_MONITOR}/workspace0"
    fi
    # Also set fallback path
    set_backdrop "/backdrop/screen0/monitorscreen/workspace0"
fi
SETUP
chmod +x /opt/desktop/scripts/desktop-setup.sh

# Fix permissions
chown -R "${USERNAME}:${USERNAME}" "${HOME}"

echo "User environment initialized successfully"
