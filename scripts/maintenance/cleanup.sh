#!/bin/bash
# Cleanup Script for Debian Docker Desktop
# Removes temporary files, caches, and frees up disk space
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Header
echo "========================================"
echo "  Debian Docker Desktop Cleanup Script "
echo "========================================"
echo ""

# Check disk usage before cleanup
log_info "Disk usage before cleanup:"
df -h / | tail -1

SPACE_BEFORE=$(df / | tail -1 | awk '{print $4}')

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

# Clean APT cache
log_info "Cleaning APT cache..."
$SUDO apt-get clean
$SUDO apt-get autoclean
$SUDO apt-get autoremove -y

# Clean APT lists (can be regenerated with apt update)
log_info "Cleaning APT lists..."
$SUDO rm -rf /var/lib/apt/lists/*

# Clean temporary files
log_info "Cleaning temporary files..."
$SUDO rm -rf /tmp/* 2>/dev/null || true
$SUDO rm -rf /var/tmp/* 2>/dev/null || true

# Clean user cache
log_info "Cleaning user cache..."
rm -rf ~/.cache/* 2>/dev/null || true
rm -rf ~/.local/share/Trash/* 2>/dev/null || true

# Clean thumbnail cache
log_info "Cleaning thumbnail cache..."
rm -rf ~/.cache/thumbnails/* 2>/dev/null || true
rm -rf ~/.thumbnails/* 2>/dev/null || true

# Clean Homebrew cache if installed
if command -v brew &> /dev/null; then
    log_info "Cleaning Homebrew cache..."
    brew cleanup -s --prune=all 2>/dev/null || true
    rm -rf "$(brew --cache)" 2>/dev/null || true
fi

# Clean npm cache if installed
if command -v npm &> /dev/null; then
    log_info "Cleaning npm cache..."
    npm cache clean --force 2>/dev/null || true
fi

# Clean pip cache if installed
if command -v pip3 &> /dev/null; then
    log_info "Cleaning pip cache..."
    pip3 cache purge 2>/dev/null || true
fi

# Clean Firefox cache
if [ -d ~/.mozilla ]; then
    log_info "Cleaning Firefox cache..."
    rm -rf ~/.mozilla/firefox/*/cache* 2>/dev/null || true
    rm -rf ~/.cache/mozilla/firefox/* 2>/dev/null || true
fi

# Clean Chrome cache if installed
if [ -d ~/.config/google-chrome ]; then
    log_info "Cleaning Chrome cache..."
    rm -rf ~/.config/google-chrome/Default/Cache/* 2>/dev/null || true
    rm -rf ~/.cache/google-chrome/* 2>/dev/null || true
fi

# Clean VS Code cache if installed
if [ -d ~/.config/Code ]; then
    log_info "Cleaning VS Code cache..."
    rm -rf ~/.config/Code/CachedData/* 2>/dev/null || true
    rm -rf ~/.config/Code/CachedExtensions/* 2>/dev/null || true
    rm -rf ~/.config/Code/CachedExtensionVSIXs/* 2>/dev/null || true
fi

# Clean journal logs (keep only recent logs)
log_info "Cleaning old logs..."
$SUDO journalctl --vacuum-time=7d 2>/dev/null || true

# Clean old kernel headers and modules (if any)
log_info "Cleaning old kernels..."
$SUDO apt-get autoremove --purge -y 2>/dev/null || true

echo ""
log_info "Disk usage after cleanup:"
df -h / | tail -1

SPACE_AFTER=$(df / | tail -1 | awk '{print $4}')

echo ""
echo "========================================"
log_success "Cleanup completed!"
echo "Space before: ${SPACE_BEFORE}K"
echo "Space after:  ${SPACE_AFTER}K"
echo "========================================"
