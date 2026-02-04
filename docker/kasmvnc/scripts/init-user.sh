#!/bin/bash
# Initialize user environment
set -e

USERNAME="${USERNAME:-user}"
HOME="/home/${USERNAME}"

echo "Initializing user environment for: ${USERNAME}"

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

# Create desktop shortcuts
cat > "${HOME}/Desktop/Firefox.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox
Comment=Browse the Web
Exec=firefox-esr
Icon=firefox-esr
Terminal=false
Categories=Network;WebBrowser;
EOF
chmod +x "${HOME}/Desktop/Firefox.desktop"

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
chmod +x "${HOME}/Desktop/Terminal.desktop"

cat > "${HOME}/Desktop/File Manager.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=File Manager
Comment=Browse the filesystem
Exec=thunar
Icon=system-file-manager
Terminal=false
Categories=System;FileManager;
EOF
chmod +x "${HOME}/Desktop/File Manager.desktop"

# Fix permissions
chown -R "${USERNAME}:${USERNAME}" "${HOME}"

echo "User environment initialized successfully"
