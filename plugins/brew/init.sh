#!/bin/bash
# Homebrew plugin - installs Homebrew package manager
set -e

source /opt/desktop/scripts/env-setup.sh

LOG_FILE="/var/log/plugin-manager.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [brew] $1" | tee -a "$LOG_FILE"; }

BREW_PREFIX="/home/linuxbrew/.linuxbrew"

# Check if already installed
if [ -x "${BREW_PREFIX}/bin/brew" ]; then
    log "Homebrew is already installed"
    exit 0
fi

log "Installing Homebrew..."

# Install build dependencies
apt-get update
apt-get install -y --no-install-recommends build-essential procps curl file git
rm -rf /var/lib/apt/lists/*

# Homebrew refuses to run as root — install as target user
sudo -u "${USERNAME}" bash -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

# Add brew shellenv to user profiles
SHELLENV='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
for profile in "${HOME}/.bashrc" "${HOME}/.profile"; do
    if ! grep -qF "brew shellenv" "$profile" 2>/dev/null; then
        echo "$SHELLENV" >> "$profile"
    fi
done
chown "${USERNAME}:${USERNAME}" "${HOME}/.bashrc" "${HOME}/.profile"

# Run brew doctor as user
sudo -u "${USERNAME}" "${BREW_PREFIX}/bin/brew" doctor 2>&1 | tail -5 || true

log "Homebrew installed successfully"
