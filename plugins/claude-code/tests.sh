#!/bin/bash
# Tests for Claude Code plugin
set -e

ERRORS=0

echo "Testing Claude Code plugin..."

# Test: claude binary exists
if command -v claude &>/dev/null; then
    echo "  PASS: claude binary exists"
else
    echo "  FAIL: claude binary not found"
    ERRORS=$((ERRORS + 1))
fi

# Test: claude --version works
if claude --version &>/dev/null; then
    echo "  PASS: claude --version works"
else
    echo "  WARN: claude --version failed"
fi

# Test: node available
if command -v node &>/dev/null; then
    echo "  PASS: Node.js available"
else
    echo "  FAIL: Node.js not found (required dependency)"
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -gt 0 ]; then
    echo "FAILED: ${ERRORS} test(s) failed"
    exit 1
fi

echo "All Claude Code tests passed"
