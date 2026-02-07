#!/bin/bash
# XRDP service startup — runs every boot
/etc/init.d/xrdp start 2>/dev/null || true
