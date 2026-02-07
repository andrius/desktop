#!/bin/bash
# Health Check Script for Debian Docker Desktop
# Checks system health and reports any issues
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ISSUES=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    ((ISSUES++)) || true
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((ISSUES++)) || true
}

check_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((ISSUES++)) || true
}

check_warn() {
    echo -e "  ${YELLOW}!${NC} $1"
}

# Header
echo "========================================"
echo "  Debian Docker Desktop Health Check   "
echo "========================================"
echo ""

# System Information
log_info "System Information:"
echo "  Hostname: $(hostname)"
echo "  Kernel: $(uname -r)"
echo "  Uptime: $(uptime -p)"
echo ""

# Check disk space
log_info "Disk Space:"
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -ge 90 ]; then
    check_fail "Root filesystem is ${DISK_USAGE}% full (critical)"
elif [ "$DISK_USAGE" -ge 80 ]; then
    check_warn "Root filesystem is ${DISK_USAGE}% full (warning)"
else
    check_pass "Root filesystem is ${DISK_USAGE}% full"
fi
echo ""

# Check memory
log_info "Memory:"
MEM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/^Mem:/ {print $3}')
MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))
if [ "$MEM_PERCENT" -ge 90 ]; then
    check_fail "Memory usage is ${MEM_PERCENT}% (${MEM_USED}MB / ${MEM_TOTAL}MB)"
elif [ "$MEM_PERCENT" -ge 80 ]; then
    check_warn "Memory usage is ${MEM_PERCENT}% (${MEM_USED}MB / ${MEM_TOTAL}MB)"
else
    check_pass "Memory usage is ${MEM_PERCENT}% (${MEM_USED}MB / ${MEM_TOTAL}MB)"
fi
echo ""

# Check X server
log_info "Display Server:"
if pgrep -x "Xvfb" > /dev/null || pgrep -x "Xorg" > /dev/null; then
    check_pass "X server is running"
else
    check_fail "X server is not running"
fi

if [ -n "$DISPLAY" ]; then
    if xdpyinfo -display "$DISPLAY" &>/dev/null; then
        check_pass "Display $DISPLAY is accessible"
    else
        check_fail "Display $DISPLAY is not accessible"
    fi
else
    check_warn "DISPLAY environment variable is not set"
fi
echo ""

# Check VNC server
log_info "VNC Server:"
if pgrep -f "kasmvnc" > /dev/null || pgrep -f "vncserver" > /dev/null; then
    check_pass "KasmVNC server is running"
else
    check_warn "No VNC server detected"
fi
echo ""

# Check desktop environment
log_info "Desktop Environment:"
if pgrep -x "xfce4-session" > /dev/null || pgrep -x "xfwm4" > /dev/null; then
    check_pass "XFCE4 is running"
else
    check_warn "XFCE4 is not running"
fi
echo ""

# Check D-Bus
log_info "System Services:"
if pgrep -x "dbus-daemon" > /dev/null; then
    check_pass "D-Bus daemon is running"
else
    check_fail "D-Bus daemon is not running"
fi

if pgrep -x "pulseaudio" > /dev/null; then
    check_pass "PulseAudio is running"
else
    check_warn "PulseAudio is not running"
fi
echo ""

# Check network
log_info "Network:"
if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    check_pass "Internet connectivity (IP)"
else
    check_fail "No internet connectivity (IP)"
fi

if ping -c 1 -W 2 google.com &>/dev/null; then
    check_pass "Internet connectivity (DNS)"
else
    check_fail "DNS resolution failed"
fi
echo ""

# Check Homebrew
log_info "Package Managers:"
if command -v brew &>/dev/null; then
    check_pass "Homebrew is installed"
    BREW_OUTDATED=$(brew outdated 2>/dev/null | wc -l)
    if [ "$BREW_OUTDATED" -gt 0 ]; then
        check_warn "$BREW_OUTDATED Homebrew packages have updates available"
    fi
else
    check_warn "Homebrew is not installed"
fi

APT_UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo 0)
if [ "$APT_UPGRADABLE" -gt 0 ]; then
    check_warn "$APT_UPGRADABLE APT packages have updates available"
else
    check_pass "APT packages are up to date"
fi
echo ""

# Check installed applications
log_info "Installed Applications:"
command -v firefox-esr &>/dev/null && check_pass "Firefox ESR" || check_warn "Firefox ESR not found"
command -v google-chrome-stable &>/dev/null && check_pass "Google Chrome" || echo -e "  ${BLUE}-${NC} Google Chrome (not installed)"
command -v code &>/dev/null && check_pass "VS Code" || echo -e "  ${BLUE}-${NC} VS Code (not installed)"
command -v cursor &>/dev/null && check_pass "Cursor" || echo -e "  ${BLUE}-${NC} Cursor (not installed)"
command -v claude &>/dev/null && check_pass "Claude Code" || echo -e "  ${BLUE}-${NC} Claude Code (not installed)"
echo ""

# Summary
echo "========================================"
if [ "$ISSUES" -eq 0 ]; then
    log_ok "All health checks passed!"
elif [ "$ISSUES" -eq 1 ]; then
    log_warning "1 issue detected"
else
    log_warning "$ISSUES issues detected"
fi
echo "========================================"

exit $ISSUES
