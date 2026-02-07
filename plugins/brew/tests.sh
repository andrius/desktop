#!/bin/bash
# Tests for Homebrew plugin
set -e

BREW_PREFIX="/home/linuxbrew/.linuxbrew"
ERRORS=0

echo "Testing Homebrew plugin..."

# Test: brew binary exists
if [ -x "${BREW_PREFIX}/bin/brew" ]; then
    echo "  PASS: brew binary exists"
else
    echo "  FAIL: brew binary not found at ${BREW_PREFIX}/bin/brew"
    ERRORS=$((ERRORS + 1))
fi

# Test: brew --version works
if "${BREW_PREFIX}/bin/brew" --version &>/dev/null; then
    echo "  PASS: brew --version works"
else
    echo "  FAIL: brew --version failed"
    ERRORS=$((ERRORS + 1))
fi

# Test: PATH configured in .bashrc
if grep -qF "brew shellenv" "${HOME}/.bashrc" 2>/dev/null; then
    echo "  PASS: brew shellenv in .bashrc"
else
    echo "  FAIL: brew shellenv not in .bashrc"
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -gt 0 ]; then
    echo "FAILED: ${ERRORS} test(s) failed"
    exit 1
fi

echo "All Homebrew tests passed"
