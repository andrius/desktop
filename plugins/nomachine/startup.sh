#!/bin/bash
# NoMachine service startup — runs every boot
# X display is guaranteed available (plugin-manager starts after display wait)
[ -x /etc/NX/nxserver ] && /etc/NX/nxserver --startup 2>/dev/null || true
