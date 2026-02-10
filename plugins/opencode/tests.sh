#!/bin/bash
# Tests for OpenCode plugin
set -e

ERRORS=0

echo "Testing OpenCode plugin..."

# Test: opencode binary exists
if command -v opencode &>/dev/null; then
    echo "  PASS: opencode binary exists"
else
    echo "  FAIL: opencode binary not found"
    ERRORS=$((ERRORS + 1))
fi

# Test: opencode --version works
if opencode --version &>/dev/null 2>&1; then
    echo "  PASS: opencode --version works"
else
    echo "  WARN: opencode --version failed"
fi

if [ $ERRORS -gt 0 ]; then
    echo "FAILED: ${ERRORS} test(s) failed"
    exit 1
fi

echo "All OpenCode tests passed"
