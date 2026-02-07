#!/bin/bash
# Docker daemon startup — runs every boot
if command -v dockerd &>/dev/null && [ ! -S /var/run/docker.sock ]; then
    dockerd &>/dev/null &
fi
