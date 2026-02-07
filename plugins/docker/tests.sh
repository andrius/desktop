#!/bin/bash
# Tests for Docker plugin
set -e

ERRORS=0

echo "Testing Docker plugin..."

# Test: docker binary exists
if command -v docker &>/dev/null; then
    echo "  PASS: docker binary exists"
else
    echo "  FAIL: docker binary not found"
    ERRORS=$((ERRORS + 1))
fi

# Test: docker compose plugin
if docker compose version &>/dev/null; then
    echo "  PASS: docker compose plugin available"
else
    echo "  WARN: docker compose plugin not available"
fi

# Test: docker info (needs socket or privileged mode)
if docker info &>/dev/null; then
    echo "  PASS: docker daemon reachable"
else
    echo "  WARN: docker daemon not reachable (needs socket mount or privileged mode)"
fi

# Test: user in docker group
if id -nG "${USERNAME:-user}" 2>/dev/null | grep -qw docker; then
    echo "  PASS: user in docker group"
else
    echo "  WARN: user not in docker group"
fi

if [ $ERRORS -gt 0 ]; then
    echo "FAILED: ${ERRORS} test(s) failed"
    exit 1
fi

echo "All Docker tests passed"
