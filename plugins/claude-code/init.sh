#!/bin/bash
# Claude Code plugin - installs the Claude Code CLI
source /opt/desktop/scripts/plugin-lib.sh

# Check if already installed
if command -v claude &>/dev/null; then
    log "Claude Code is already installed"
    exit 0
fi

log "Installing Claude Code..."

# Ensure Node.js is available
if ! command -v node &>/dev/null; then
    log "Node.js not found, installing..."

    BREW_PREFIX="/home/linuxbrew/.linuxbrew"
    if [ -x "${BREW_PREFIX}/bin/brew" ]; then
        log "Installing Node.js via Homebrew..."
        sudo -u "${USERNAME}" "${BREW_PREFIX}/bin/brew" install node
    else
        log "Installing Node.js via NodeSource..."
        curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
        apt-get install -y nodejs
        rm -rf /var/lib/apt/lists/*
    fi
fi

# Install Claude Code globally
npm install -g @anthropic-ai/claude-code

log "Claude Code installed successfully"
