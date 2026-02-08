#!/bin/bash
# Detect the docker bridge interface IP address.
# Usage: ./get-docker-ip.sh [interface]
# Default interface: docker0

IFACE="${1:-docker0}"

IP=$(ip -4 addr show "$IFACE" 2>/dev/null | grep -oP 'inet \K[\d.]+')

if [ -z "$IP" ]; then
    echo "Error: interface '$IFACE' not found or has no IPv4 address" >&2
    echo "Available interfaces:" >&2
    ip -4 -o addr show | awk '{print "  " $2 " -> " $4}' >&2
    exit 1
fi

echo "$IP"
