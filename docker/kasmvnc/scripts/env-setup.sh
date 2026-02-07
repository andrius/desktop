#!/bin/bash
# Environment setup script
# Loads configuration from environment variables

# Default values
export USERNAME="${USERNAME:-user}"
export USER="${USERNAME}"
export HOME="/home/${USERNAME}"
export DISPLAY="${DISPLAY:-:1}"
export RESOLUTION="${RESOLUTION:-1920x1080x24}"
export TZ="${TZ:-UTC}"
export LANG="${LANG:-en_US.UTF-8}"
export LANGUAGE="${LANGUAGE:-en_US:en}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# XDG directories (always derive from USERNAME, not Dockerfile defaults)
export XDG_RUNTIME_DIR="/tmp/runtime-${USERNAME}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"

# Homebrew
export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
export HOMEBREW_NO_AUTO_UPDATE="${HOMEBREW_NO_AUTO_UPDATE:-1}"
export HOMEBREW_NO_ANALYTICS="${HOMEBREW_NO_ANALYTICS:-1}"
if [ -d "$HOMEBREW_PREFIX" ]; then
    export PATH="${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin:${PATH}"
fi

# Plugin configuration (comma-separated list, e.g. PLUGINS=brew,vscode,cursor)
export PLUGINS="${PLUGINS:-}"

# VNC configuration
export VNC_PORT="${VNC_PORT:-5901}"
export VNC_WEB_PORT="${VNC_WEB_PORT:-6901}"
export VNC_PW="${VNC_PW:-}"

echo "Environment configured for user: ${USERNAME}"
