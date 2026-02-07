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
    echo "  build     - Build the image (default)"
    echo "  prepare   - Prepare build context only"
    echo "  help      - Show this help"
    echo ""
    echo "Environment variables:"
    echo "  USERNAME    - Desktop username (default: user)"
    echo "  IMAGE_TAG   - Image tag (default: latest)"
}

prepare_contexts() {
    log_info "Preparing build contexts..."

    # Copy base scripts to build context
    cp docker/base/scripts/env-setup.sh docker/kasmvnc/scripts/
    cp docker/base/scripts/init-user.sh docker/kasmvnc/scripts/
    cp docker/base/scripts/plugin-manager.sh docker/kasmvnc/scripts/
    cp docker/base/scripts/setup-user.sh docker/kasmvnc/scripts/
    rm -rf docker/kasmvnc/plugins/
    cp -r plugins/ docker/kasmvnc/plugins/

    log_success "Build contexts prepared"
}

build_image() {
    log_info "Building image..."

    docker build \
        --build-arg USERNAME="${USERNAME}" \
        -t "desktop:${IMAGE_TAG}" \
        -f docker/kasmvnc/Dockerfile \
        docker/kasmvnc/

    log_success "Image built: desktop:${IMAGE_TAG}"
}

# Change to script directory
cd "$(dirname "$0")"

# Parse command
case "${1:-build}" in
    build|all)
        prepare_contexts
        build_image
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
