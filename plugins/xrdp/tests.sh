#!/bin/bash
# Tests for XRDP plugin
set -e

ERRORS=0

echo "Testing XRDP plugin..."

# Test: xrdp binary exists
if command -v xrdp &>/dev/null; then
    echo "  PASS: xrdp binary exists"
else
    echo "  FAIL: xrdp binary not found"
    ERRORS=$((ERRORS + 1))
fi

# Test: xrdp service running
if pgrep -x xrdp &>/dev/null; then
    echo "  PASS: xrdp service running"
else
    echo "  WARN: xrdp service not running (may need manual start)"
fi

# Test: port 3389 listening
if netstat -tlnp 2>/dev/null | grep -q ':3389'; then
    echo "  PASS: port 3389 listening"
elif ss -tlnp 2>/dev/null | grep -q ':3389'; then
    echo "  PASS: port 3389 listening"
else
    echo "  WARN: port 3389 not listening (service may not be started)"
fi

# Test: .xsession exists
if [ -f "${HOME}/.xsession" ]; then
    echo "  PASS: .xsession file exists"
else
    echo "  FAIL: .xsession file not found"
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -gt 0 ]; then
    echo "FAILED: ${ERRORS} test(s) failed"
    exit 1
fi

echo "All XRDP tests passed"
