#!/bin/bash
# Shared plugin library — sourced by every plugin init.sh and startup.sh
set -e
source /opt/desktop/scripts/env-setup.sh
LOG_FILE="/var/log/plugin-manager.log"
PLUGIN_NAME="${PLUGIN_NAME:-$(basename "$(dirname "$0")")}"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${PLUGIN_NAME}] $1" | tee -a "$LOG_FILE"; }
