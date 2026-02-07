#!/bin/bash
# Tests for VS Code plugin
set -e

ERRORS=0

echo "Testing VS Code plugin..."

# Test: code binary exists
if command -v code &>/dev/null; then
    echo "  PASS: code binary exists"
else
    echo "  FAIL: code binary not found"
    ERRORS=$((ERRORS + 1))
fi

# Test: code --version works
if code --version &>/dev/null; then
    echo "  PASS: code --version works"
else
    echo "  WARN: code --version failed (may need display)"
fi

# Test: desktop shortcut exists
if [ -f "${HOME}/Desktop/VSCode.desktop" ]; then
    echo "  PASS: desktop shortcut exists"
else
    echo "  FAIL: desktop shortcut not found"
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -gt 0 ]; then
    echo "FAILED: ${ERRORS} test(s) failed"
    exit 1
fi

echo "All VS Code tests passed"
