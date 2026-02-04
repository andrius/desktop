#!/bin/bash
# System Update Script for Debian Docker Desktop
# Updates the system packages, Homebrew, and installed plugins
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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Header
echo "========================================"
echo "  Debian Docker Desktop System Update  "
echo "========================================"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_warning "Running as root. Some operations will be performed without sudo."
    SUDO=""
else
    SUDO="sudo"
fi

# Update APT packages
log_info "Updating APT package lists..."
$SUDO apt-get update

log_info "Upgrading installed packages..."
$SUDO apt-get upgrade -y

log_info "Performing distribution upgrade..."
$SUDO apt-get dist-upgrade -y

log_info "Removing unused packages..."
$SUDO apt-get autoremove -y

log_info "Cleaning package cache..."
$SUDO apt-get clean

log_success "APT packages updated successfully"

# Update Homebrew if installed
if command -v brew &> /dev/null; then
    echo ""
    log_info "Updating Homebrew..."

    # Temporarily enable auto-update
    OLD_HOMEBREW_NO_AUTO_UPDATE="${HOMEBREW_NO_AUTO_UPDATE}"
    unset HOMEBREW_NO_AUTO_UPDATE

    brew update

    log_info "Upgrading Homebrew packages..."
    brew upgrade

    log_info "Cleaning up Homebrew..."
    brew cleanup -s

    # Restore setting
    export HOMEBREW_NO_AUTO_UPDATE="${OLD_HOMEBREW_NO_AUTO_UPDATE}"

    log_success "Homebrew updated successfully"
else
    log_warning "Homebrew not found, skipping..."
fi

# Update npm packages if installed
if command -v npm &> /dev/null; then
    echo ""
    log_info "Updating global npm packages..."
    npm update -g 2>/dev/null || log_warning "npm global update had some issues"
    log_success "npm packages updated"
fi

# Update snap packages if installed
if command -v snap &> /dev/null; then
    echo ""
    log_info "Updating snap packages..."
    $SUDO snap refresh 2>/dev/null || log_warning "snap refresh had some issues"
    log_success "snap packages updated"
fi

# Update flatpak packages if installed
if command -v flatpak &> /dev/null; then
    echo ""
    log_info "Updating flatpak packages..."
    flatpak update -y 2>/dev/null || log_warning "flatpak update had some issues"
    log_success "flatpak packages updated"
fi

echo ""
echo "========================================"
log_success "System update completed!"
echo "========================================"
echo ""
echo "You may need to restart the container for some updates to take effect."
