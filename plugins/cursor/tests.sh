#!/bin/bash
# Tests for Cursor plugin
set -e

ERRORS=0

echo "Testing Cursor plugin..."

# Test: cursor binary exists at dpkg install path
if [ -x /usr/share/cursor/cursor ]; then
    echo "  PASS: cursor binary exists at /usr/share/cursor/cursor"
else
    echo "  FAIL: cursor binary not found at /usr/share/cursor/cursor"
    ERRORS=$((ERRORS + 1))
fi

# Test: symlink exists at /usr/bin/cursor (created by dpkg postinst)
if [ -L /usr/bin/cursor ] || [ -x /usr/bin/cursor ]; then
    echo "  PASS: cursor available at /usr/bin/cursor"
else
    echo "  FAIL: cursor not found at /usr/bin/cursor"
    ERRORS=$((ERRORS + 1))
fi

# Test: desktop shortcut exists
if [ -f "${HOME}/Desktop/Cursor.desktop" ]; then
    echo "  PASS: desktop shortcut exists"
else
    echo "  FAIL: desktop shortcut not found"
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -gt 0 ]; then
    echo "FAILED: ${ERRORS} test(s) failed"
    exit 1
fi

echo "All Cursor tests passed"
