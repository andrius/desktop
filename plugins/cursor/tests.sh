#!/bin/bash
# Tests for Cursor plugin
set -e

ERRORS=0

echo "Testing Cursor plugin..."

# Test: cursor binary exists and is executable
if [ -x /opt/cursor/cursor ]; then
    echo "  PASS: cursor binary exists at /opt/cursor/cursor"
else
    echo "  FAIL: cursor binary not found at /opt/cursor/cursor"
    ERRORS=$((ERRORS + 1))
fi

# Test: symlink exists
if [ -L /usr/local/bin/cursor ]; then
    echo "  PASS: symlink at /usr/local/bin/cursor"
else
    echo "  FAIL: symlink not found at /usr/local/bin/cursor"
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
