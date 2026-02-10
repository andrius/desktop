#!/bin/bash
# Tests for Antigravity plugin
set -e

ERRORS=0

echo "Testing Antigravity plugin..."

# Test: antigravity binary exists
if command -v antigravity &>/dev/null; then
    echo "  PASS: antigravity binary exists"
else
    echo "  FAIL: antigravity binary not found"
    ERRORS=$((ERRORS + 1))
fi

# Test: antigravity --version works
if antigravity --version &>/dev/null; then
    echo "  PASS: antigravity --version works"
else
    echo "  WARN: antigravity --version failed (may need display)"
fi

# Test: desktop shortcut exists
if [ -f "${HOME}/Desktop/Antigravity.desktop" ]; then
    echo "  PASS: desktop shortcut exists"
else
    echo "  FAIL: desktop shortcut not found"
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -gt 0 ]; then
    echo "FAILED: ${ERRORS} test(s) failed"
    exit 1
fi

echo "All Antigravity tests passed"
