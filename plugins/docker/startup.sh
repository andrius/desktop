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
