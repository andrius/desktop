#!/bin/bash
# Docker plugin — service startup (runs every boot)
source /opt/desktop/scripts/plugin-lib.sh

if [ -S /var/run/docker.sock ]; then
    # Socket mount: align container docker group GID to socket's GID
    SOCK_GID=$(stat -c '%g' /var/run/docker.sock)
    CURRENT_GID=$(getent group docker | cut -d: -f3)
    if [ -n "$CURRENT_GID" ] && [ "$SOCK_GID" != "$CURRENT_GID" ]; then
        log "Adjusting docker group GID from ${CURRENT_GID} to ${SOCK_GID}"
        groupmod -g "$SOCK_GID" docker
    fi
elif command -v dockerd &>/dev/null; then
    # DinD: start daemon
    log "Starting Docker daemon (DinD)..."
    dockerd &>/dev/null &
fi

# Ensure user is in docker group (handles first boot + GID changes)
usermod -aG docker "${USERNAME}" 2>/dev/null || true

# Add bashrc hook to refresh docker group in new terminal sessions
# Plugins install after the user session starts, so the shell doesn't
# inherit the docker group — newgrp refreshes it on first terminal open
BASHRC="/home/${USERNAME}/.bashrc"
MARKER="# docker-group-refresh"
if [ -f "$BASHRC" ] && ! grep -q "$MARKER" "$BASHRC"; then
    cat >> "$BASHRC" << 'DOCKER_EOF'

# docker-group-refresh
if command -v docker &>/dev/null \
    && id -Gn "$(id -un)" 2>/dev/null | grep -qw docker \
    && ! id -Gn 2>/dev/null | grep -qw docker; then
  exec newgrp docker
fi
DOCKER_EOF
fi
