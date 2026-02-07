#!/bin/bash
# Tests for NoMachine plugin
set -e

ERRORS=0

echo "Testing NoMachine plugin..."

# Test: nxserver binary exists
if [ -x /etc/NX/nxserver ] || command -v nxserver &>/dev/null; then
    echo "  PASS: nxserver binary exists"
else
    echo "  FAIL: nxserver binary not found"
    ERRORS=$((ERRORS + 1))
fi

# Test: nxserver status
if /etc/NX/nxserver --status &>/dev/null; then
    echo "  PASS: nxserver status OK"
else
    echo "  WARN: nxserver status check failed (may need manual start)"
fi

# Test: port 4000 listening
if netstat -tlnp 2>/dev/null | grep -q ':4000'; then
    echo "  PASS: port 4000 listening"
elif ss -tlnp 2>/dev/null | grep -q ':4000'; then
    echo "  PASS: port 4000 listening"
else
    echo "  FAIL: port 4000 not listening"
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -gt 0 ]; then
    echo "FAILED: ${ERRORS} test(s) failed"
    exit 1
fi

echo "All NoMachine tests passed"
