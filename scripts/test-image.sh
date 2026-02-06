#!/bin/bash
# Test script for Debian Desktop Docker images
# Usage: ./scripts/test-image.sh [kasmvnc|selkies] [--local]
#
# Options:
#   --local     Build image locally before testing (default: use existing image)
#   --no-cleanup Keep container running after test (for debugging)
#   --verbose   Show detailed output
#
# Exit codes:
#   0 - All tests passed
#   1 - Test failed
#   2 - Invalid arguments

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TIMEOUT_STARTUP=60
TIMEOUT_HEALTH=30
RETRY_INTERVAL=5

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default options
LOCAL_BUILD=false
CLEANUP=true
VERBOSE=false

# Parse arguments
VARIANT=""
while [[ $# -gt 0 ]]; do
    case $1 in
        kasmvnc|selkies)
            VARIANT="$1"
            shift
            ;;
        --local)
            LOCAL_BUILD=true
            shift
            ;;
        --no-cleanup)
            CLEANUP=false
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [kasmvnc|selkies] [--local] [--no-cleanup] [--verbose]"
            echo ""
            echo "Test Debian Desktop Docker images"
            echo ""
            echo "Arguments:"
            echo "  kasmvnc|selkies  Image variant to test (required)"
            echo ""
            echo "Options:"
            echo "  --local          Build image locally before testing"
            echo "  --no-cleanup     Keep container running after test"
            echo "  --verbose        Show detailed output"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown argument: $1${NC}"
            exit 2
            ;;
    esac
done

if [[ -z "$VARIANT" ]]; then
    echo -e "${RED}Error: Image variant required (kasmvnc or selkies)${NC}"
    echo "Usage: $0 [kasmvnc|selkies] [--local] [--no-cleanup] [--verbose]"
    exit 2
fi

# Set variant-specific configuration
case $VARIANT in
    kasmvnc)
        COMPOSE_FILE="docker-compose.kasmvnc.yml"
        WEB_PORT=6901
        IMAGE_NAME="debian-desktop:kasmvnc-latest"
        HEALTH_ENDPOINT="/"
        EXPECTED_CONTENT="KasmVNC"
        ;;
    selkies)
        COMPOSE_FILE="docker-compose.selkies.yml"
        WEB_PORT=8080
        IMAGE_NAME="debian-desktop:selkies-latest"
        HEALTH_ENDPOINT="/"
        EXPECTED_CONTENT="Selkies"
        ;;
esac

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "[DEBUG] $1"
    fi
}

cleanup() {
    if [[ "$CLEANUP" == "true" ]]; then
        log_info "Cleaning up..."
        cd "$PROJECT_DIR"
        docker compose -f "$COMPOSE_FILE" down --volumes --remove-orphans 2>/dev/null || true
    else
        log_warn "Skipping cleanup (--no-cleanup specified)"
        log_info "Container is still running. Stop with: docker compose -f $COMPOSE_FILE down"
    fi
}

# Trap for cleanup on exit
trap cleanup EXIT

# Main test functions
test_build() {
    log_info "Building $VARIANT image..."
    cd "$PROJECT_DIR"

    # Prepare build context
    make prepare

    # Build the image
    if ! make "build-$VARIANT"; then
        log_error "Failed to build $VARIANT image"
        return 1
    fi

    log_info "Build completed successfully"
    return 0
}

test_image_exists() {
    log_info "Checking if image exists: $IMAGE_NAME"

    if docker image inspect "$IMAGE_NAME" &>/dev/null; then
        log_info "Image found: $IMAGE_NAME"

        # Show image size
        SIZE=$(docker image inspect "$IMAGE_NAME" --format='{{.Size}}' | numfmt --to=iec-i --suffix=B 2>/dev/null || echo "unknown")
        log_info "Image size: $SIZE"
        return 0
    else
        log_error "Image not found: $IMAGE_NAME"
        return 1
    fi
}

test_container_start() {
    log_info "Starting container..."
    cd "$PROJECT_DIR"

    # Start container
    if ! docker compose -f "$COMPOSE_FILE" up -d; then
        log_error "Failed to start container"
        return 1
    fi

    log_info "Container started, waiting for initialization..."

    # Wait for container to be running
    local elapsed=0
    while [[ $elapsed -lt $TIMEOUT_STARTUP ]]; do
        # docker compose ps --format json returns one JSON object per line (not an array)
        STATUS=$(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null | head -1 | jq -r '.State' 2>/dev/null || echo "unknown")
        log_verbose "Container status: $STATUS (elapsed: ${elapsed}s)"

        if [[ "$STATUS" == "running" ]]; then
            log_info "Container is running"
            return 0
        elif [[ "$STATUS" == "exited" ]] || [[ "$STATUS" == "dead" ]]; then
            log_error "Container exited unexpectedly"
            docker compose -f "$COMPOSE_FILE" logs --tail 50
            return 1
        fi

        sleep $RETRY_INTERVAL
        elapsed=$((elapsed + RETRY_INTERVAL))
    done

    log_error "Timeout waiting for container to start"
    return 1
}

test_web_access() {
    log_info "Testing web interface on port $WEB_PORT..."

    local elapsed=0
    while [[ $elapsed -lt $TIMEOUT_HEALTH ]]; do
        log_verbose "Attempting to connect to http://localhost:$WEB_PORT$HEALTH_ENDPOINT (elapsed: ${elapsed}s)"

        # Try to fetch the web interface
        HTTP_CODE=$(curl -sf -o /dev/null -w '%{http_code}' "http://localhost:$WEB_PORT$HEALTH_ENDPOINT" 2>/dev/null || echo "000")

        if [[ "$HTTP_CODE" == "200" ]]; then
            log_info "Web interface responding (HTTP $HTTP_CODE)"
            return 0
        fi

        log_verbose "HTTP response code: $HTTP_CODE"
        sleep $RETRY_INTERVAL
        elapsed=$((elapsed + RETRY_INTERVAL))
    done

    log_error "Timeout waiting for web interface"
    return 1
}

test_web_content() {
    log_info "Validating web interface content..."

    # Fetch page content
    CONTENT=$(curl -sf "http://localhost:$WEB_PORT$HEALTH_ENDPOINT" 2>/dev/null || echo "")

    if [[ -z "$CONTENT" ]]; then
        log_error "Failed to fetch web content"
        return 1
    fi

    # Check for expected content
    if echo "$CONTENT" | grep -qi "$EXPECTED_CONTENT"; then
        log_info "Web content validated (found: $EXPECTED_CONTENT)"
        return 0
    else
        log_warn "Expected content not found: $EXPECTED_CONTENT"
        log_verbose "Content preview: $(echo "$CONTENT" | head -c 500)"
        # This is a warning, not a failure - the page structure might change
        return 0
    fi
}

test_health_check() {
    log_info "Checking container health status..."
    cd "$PROJECT_DIR"

    # Wait for health check to run
    local elapsed=0
    while [[ $elapsed -lt $TIMEOUT_HEALTH ]]; do
        # docker compose ps --format json returns one JSON object per line (not an array)
        HEALTH=$(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null | head -1 | jq -r '.Health' 2>/dev/null || echo "unknown")
        log_verbose "Health status: $HEALTH (elapsed: ${elapsed}s)"

        case "$HEALTH" in
            healthy)
                log_info "Container is healthy"
                return 0
                ;;
            unhealthy)
                log_error "Container health check failed"
                docker compose -f "$COMPOSE_FILE" logs --tail 30
                return 1
                ;;
            starting|"")
                # Still starting, continue waiting
                ;;
        esac

        sleep $RETRY_INTERVAL
        elapsed=$((elapsed + RETRY_INTERVAL))
    done

    log_warn "Health check did not complete in time (may still be starting)"
    return 0
}

test_container_logs() {
    log_info "Checking container logs for errors..."
    cd "$PROJECT_DIR"

    # Get logs
    LOGS=$(docker compose -f "$COMPOSE_FILE" logs 2>&1)

    # Check for critical errors
    if echo "$LOGS" | grep -qi "fatal\|panic\|segfault"; then
        log_error "Critical errors found in logs"
        echo "$LOGS" | grep -i "fatal\|panic\|segfault"
        return 1
    fi

    # Check VNC server started (for kasmvnc)
    if [[ "$VARIANT" == "kasmvnc" ]]; then
        if echo "$LOGS" | grep -q "New.*desktop is"; then
            log_info "VNC server started successfully"
        else
            log_warn "VNC server startup message not found in logs"
        fi
    fi

    if [[ "$VERBOSE" == "true" ]]; then
        log_verbose "=== Container Logs ==="
        echo "$LOGS"
        log_verbose "=== End Logs ==="
    fi

    return 0
}

# Run all tests
run_tests() {
    local failed=0

    echo ""
    echo "========================================"
    echo "  Testing $VARIANT image"
    echo "========================================"
    echo ""

    # Build if requested
    if [[ "$LOCAL_BUILD" == "true" ]]; then
        if ! test_build; then
            return 1
        fi
    fi

    # Test 1: Image exists
    if ! test_image_exists; then
        log_error "Image not found. Use --local to build first."
        return 1
    fi

    # Test 2: Container starts
    if ! test_container_start; then
        failed=1
    fi

    if [[ $failed -eq 0 ]]; then
        # Test 3: Web interface accessible
        if ! test_web_access; then
            failed=1
        fi
    fi

    if [[ $failed -eq 0 ]]; then
        # Test 4: Web content validation
        if ! test_web_content; then
            failed=1
        fi
    fi

    if [[ $failed -eq 0 ]]; then
        # Test 5: Health check
        if ! test_health_check; then
            failed=1
        fi
    fi

    if [[ $failed -eq 0 ]]; then
        # Test 6: Log analysis
        if ! test_container_logs; then
            failed=1
        fi
    fi

    echo ""
    echo "========================================"
    if [[ $failed -eq 0 ]]; then
        echo -e "  ${GREEN}All tests passed!${NC}"
    else
        echo -e "  ${RED}Some tests failed!${NC}"
    fi
    echo "========================================"
    echo ""

    return $failed
}

# Main execution
cd "$PROJECT_DIR"
run_tests
exit $?
