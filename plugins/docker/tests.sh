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
    echo "  FAIL: docker compose plugin not available"
    ERRORS=$((ERRORS + 1))
fi

# Test: user in docker group
if id -nG "${USERNAME:-user}" 2>/dev/null | grep -qw docker; then
    echo "  PASS: user in docker group"
else
    echo "  FAIL: user not in docker group"
    ERRORS=$((ERRORS + 1))
fi

# Test: docker daemon reachable
if docker info &>/dev/null; then
    echo "  PASS: docker daemon reachable"
else
    echo "  FAIL: docker daemon not reachable (needs socket mount or privileged mode)"
    ERRORS=$((ERRORS + 1))
fi

# Test: functional — pull and run hello-world
if docker run --rm hello-world &>/dev/null; then
    echo "  PASS: docker run hello-world succeeded"
else
    echo "  FAIL: docker run hello-world failed"
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -gt 0 ]; then
    echo "FAILED: ${ERRORS} test(s) failed"
    exit 1
fi

echo "All Docker tests passed"
