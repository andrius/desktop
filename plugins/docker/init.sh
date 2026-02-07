#!/bin/bash
# Docker plugin - installs Docker Engine (system service, DinD support)
source /opt/desktop/scripts/plugin-lib.sh

# Check if already installed
if command -v docker &>/dev/null; then
    log "Docker is already installed"
    exit 0
fi

log "Installing Docker Engine..."

# Detect architecture
ARCH=$(dpkg --print-architecture)

# Add Docker GPG key and repository
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
rm -rf /var/lib/apt/lists/*

# Add user to docker group
usermod -aG docker "${USERNAME}" 2>/dev/null || true

log "Docker Engine installed successfully"
