#!/bin/bash
# Tests for Chrome plugin
set -e

ERRORS=0

echo "Testing Chrome plugin..."

# Test: google-chrome-stable binary exists
if command -v google-chrome-stable &>/dev/null; then
    echo "  PASS: google-chrome-stable binary exists"
else
    echo "  FAIL: google-chrome-stable binary not found"
    ERRORS=$((ERRORS + 1))
fi

# Test: google-chrome-stable --version works
if google-chrome-stable --version &>/dev/null; then
    echo "  PASS: google-chrome-stable --version works"
else
    echo "  WARN: google-chrome-stable --version failed (may need display)"
fi

# Test: desktop shortcut exists
if [ -f "${HOME}/Desktop/Chrome.desktop" ]; then
    echo "  PASS: desktop shortcut exists"
else
    echo "  FAIL: desktop shortcut not found"
    ERRORS=$((ERRORS + 1))
fi

# Test: Chrome binary is wrapped with --no-sandbox
if [ -f /usr/bin/google-chrome-stable.real ]; then
    if grep -q '\-\-no-sandbox' /usr/bin/google-chrome-stable; then
        echo "  PASS: google-chrome-stable is wrapped with --no-sandbox"
    else
        echo "  FAIL: google-chrome-stable wrapper missing --no-sandbox"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "  FAIL: google-chrome-stable.real not found (wrapper not applied)"
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -gt 0 ]; then
    echo "FAILED: ${ERRORS} test(s) failed"
    exit 1
fi

echo "All Chrome tests passed"
