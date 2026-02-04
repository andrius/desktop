#!/bin/bash
# Build script for Debian Docker Desktop
set -e

# Configuration
USERNAME="${USERNAME:-user}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    echo "Debian Docker Desktop Build Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  all       - Build all images (default)"
    echo "  kasmvnc   - Build KasmVNC variant only"
    echo "  selkies   - Build Selkies variant only"
    echo "  prepare   - Prepare build contexts only"
    echo "  help      - Show this help"
    echo ""
    echo "Environment variables:"
    echo "  USERNAME    - Desktop username (default: user)"
    echo "  IMAGE_TAG   - Image tag (default: latest)"
}

prepare_contexts() {
    log_info "Preparing build contexts..."

    # Copy base scripts to variant directories
    cp docker/base/scripts/env-setup.sh docker/kasmvnc/scripts/
    cp docker/base/scripts/init-user.sh docker/kasmvnc/scripts/
    cp docker/base/scripts/plugin-manager.sh docker/kasmvnc/scripts/

    cp docker/base/scripts/env-setup.sh docker/selkies/scripts/
    cp docker/base/scripts/init-user.sh docker/selkies/scripts/
    cp docker/base/scripts/plugin-manager.sh docker/selkies/scripts/

    log_success "Build contexts prepared"
}

build_kasmvnc() {
    log_info "Building KasmVNC image..."

    docker build \
        --build-arg USERNAME="${USERNAME}" \
        -t "debian-desktop:kasmvnc-${IMAGE_TAG}" \
        -f docker/kasmvnc/Dockerfile \
        docker/kasmvnc/

    log_success "KasmVNC image built: debian-desktop:kasmvnc-${IMAGE_TAG}"
}

build_selkies() {
    log_info "Building Selkies image..."

    docker build \
        --build-arg USERNAME="${USERNAME}" \
        -t "debian-desktop:selkies-${IMAGE_TAG}" \
        -f docker/selkies/Dockerfile \
        docker/selkies/

    log_success "Selkies image built: debian-desktop:selkies-${IMAGE_TAG}"
}

# Change to script directory
cd "$(dirname "$0")"

# Parse command
case "${1:-all}" in
    all)
        prepare_contexts
        build_kasmvnc
        build_selkies
        ;;
    kasmvnc)
        prepare_contexts
        build_kasmvnc
        ;;
    selkies)
        prepare_contexts
        build_selkies
        ;;
    prepare)
        prepare_contexts
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac

echo ""
log_success "Build completed!"
