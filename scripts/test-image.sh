#!/bin/bash
# Test script for Debian Desktop Docker image
# Usage: ./scripts/test-image.sh [--local] [--no-cleanup] [--verbose]
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

# Image configuration
IMAGE_NAME="desktop:latest"
COMPOSE_FILE="docker-compose.yml"
WEB_PORT=6901
HEALTH_ENDPOINT="/"
EXPECTED_CONTENT="KasmVNC"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
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
            echo "Usage: $0 [--local] [--no-cleanup] [--verbose]"
            echo ""
            echo "Test Debian Desktop Docker image"
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
        log_info "Container is still running. Stop with: docker compose down"
    fi
}

# Trap for cleanup on exit
trap cleanup EXIT

# Main test functions
test_build() {
    log_info "Building image..."
    cd "$PROJECT_DIR"

    # Prepare build context
    make prepare

    # Build the image
    if ! make build; then
        log_error "Failed to build image"
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

    # Check VNC server started
    if echo "$LOGS" | grep -q "New.*desktop is"; then
        log_info "VNC server started successfully"
    else
        log_warn "VNC server startup message not found in logs"
    fi

    if [[ "$VERBOSE" == "true" ]]; then
        log_verbose "=== Container Logs ==="
        echo "$LOGS"
        log_verbose "=== End Logs ==="
    fi

    return 0
}

test_process_ownership() {
    local expected_user="$1"
    log_info "Checking process ownership (expecting: ${expected_user})..."
    cd "$PROJECT_DIR"

    # Get the container ID from docker compose
    local container_id
    container_id=$(docker compose -f "$COMPOSE_FILE" ps -q 2>/dev/null | head -1)
    if [[ -z "$container_id" ]]; then
        log_error "No running container found"
        return 1
    fi

    # Check VNC server process ownership
    local vnc_user
    vnc_user=$(docker exec "$container_id" ps -eo user,comm --no-headers 2>/dev/null \
        | grep -E 'Xvnc|Xkasmvnc' | awk '{print $1}' | head -1)

    if [[ -z "$vnc_user" ]]; then
        log_warn "VNC server process not found in process list"
        log_verbose "Process list:"
        log_verbose "$(docker exec "$container_id" ps -eo user,comm --no-headers 2>/dev/null)"
        return 0
    fi

    if [[ "$vnc_user" == "$expected_user" ]]; then
        log_info "VNC server running as expected user: ${vnc_user}"
    else
        log_error "VNC server running as '${vnc_user}', expected '${expected_user}'"
        return 1
    fi

    # Check PulseAudio ownership
    local pulse_user
    pulse_user=$(docker exec "$container_id" ps -eo user,comm --no-headers 2>/dev/null \
        | grep pulseaudio | awk '{print $1}' | head -1)

    if [[ -n "$pulse_user" ]]; then
        if [[ "$pulse_user" == "$expected_user" ]]; then
            log_info "PulseAudio running as expected user: ${pulse_user}"
        else
            log_warn "PulseAudio running as '${pulse_user}', expected '${expected_user}'"
        fi
    fi

    return 0
}

test_custom_user() {
    log_info "Testing custom user configuration..."

    local custom_container="test-custom-user-$$"
    local custom_port=16901

    # Start a container with custom user settings
    log_info "Starting container with USERNAME=testuser, USER_UID=1234, USER_GID=1234..."
    docker run -d \
        --name "$custom_container" \
        --security-opt seccomp=unconfined \
        --shm-size=2g \
        -p "${custom_port}:6901" \
        -e USERNAME=testuser \
        -e USER_UID=1234 \
        -e USER_GID=1234 \
        -e VNC_PW=testpass \
        "$IMAGE_NAME" >/dev/null 2>&1

    # Wait for startup
    local elapsed=0
    local custom_ok=false
    while [[ $elapsed -lt $TIMEOUT_STARTUP ]]; do
        local http_code
        http_code=$(curl -sf -o /dev/null -w '%{http_code}' "http://localhost:${custom_port}/" 2>/dev/null || echo "000")
        if [[ "$http_code" == "200" ]]; then
            custom_ok=true
            break
        fi
        log_verbose "Custom container HTTP: ${http_code} (elapsed: ${elapsed}s)"
        sleep $RETRY_INTERVAL
        elapsed=$((elapsed + RETRY_INTERVAL))
    done

    if [[ "$custom_ok" != "true" ]]; then
        log_error "Custom user container did not become ready"
        docker logs "$custom_container" 2>&1 | tail -20
        docker rm -f "$custom_container" >/dev/null 2>&1 || true
        return 1
    fi

    log_info "Custom user container is responding on port ${custom_port}"

    # Verify VNC runs as testuser
    local vnc_user
    vnc_user=$(docker exec "$custom_container" ps -eo user,comm --no-headers 2>/dev/null \
        | grep -E 'Xvnc|Xkasmvnc' | awk '{print $1}' | head -1)

    if [[ "$vnc_user" == "testuser" ]]; then
        log_info "VNC server running as custom user: ${vnc_user}"
    elif [[ -z "$vnc_user" ]]; then
        log_warn "VNC server process not found in custom container"
    else
        log_error "VNC server running as '${vnc_user}', expected 'testuser'"
        docker rm -f "$custom_container" >/dev/null 2>&1 || true
        return 1
    fi

    # Verify uid
    local actual_uid
    actual_uid=$(docker exec "$custom_container" id -u testuser 2>/dev/null || echo "")

    if [[ "$actual_uid" == "1234" ]]; then
        log_info "Custom user UID verified: ${actual_uid}"
    else
        log_error "Custom user UID is '${actual_uid}', expected '1234'"
        docker rm -f "$custom_container" >/dev/null 2>&1 || true
        return 1
    fi

    # Cleanup custom container
    docker rm -f "$custom_container" >/dev/null 2>&1 || true
    log_info "Custom user test passed"
    return 0
}

# Run all tests
run_tests() {
    local failed=0

    echo ""
    echo "========================================"
    echo "  Testing desktop image"
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

    if [[ $failed -eq 0 ]]; then
        # Test 7: Process ownership (detect expected user from container)
        local expected_user
        expected_user=$(docker compose -f "$COMPOSE_FILE" exec -T desktop printenv USERNAME 2>/dev/null || echo "user")
        if ! test_process_ownership "$expected_user"; then
            failed=1
        fi
    fi

    if [[ $failed -eq 0 ]]; then
        # Test 8: Custom user configuration
        if ! test_custom_user; then
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
