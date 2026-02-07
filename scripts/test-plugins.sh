#!/bin/bash
# Plugin test runner for Debian Desktop Docker
# Tests each plugin in an isolated container
#
# Usage: ./scripts/test-plugins.sh [plugin...] [--verbose] [--no-cleanup]
#
# Examples:
#   ./scripts/test-plugins.sh                    # Test all plugins
#   ./scripts/test-plugins.sh brew vscode        # Test specific plugins
#   ./scripts/test-plugins.sh brew --verbose     # Verbose output
#
# Exit codes:
#   0 - All tests passed
#   1 - One or more tests failed
#   2 - Invalid arguments

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TIMEOUT_STARTUP=120
RETRY_INTERVAL=5

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Options
VERBOSE=false
CLEANUP=true
PLUGINS=()

# All available plugins (excluding docker which needs privileged)
ALL_PLUGINS=(brew chrome xrdp nomachine cursor vscode claude-code)

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --no-cleanup)
            CLEANUP=false
            shift
            ;;
        --all)
            PLUGINS=("${ALL_PLUGINS[@]}")
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [plugin...] [--verbose] [--no-cleanup] [--all]"
            echo ""
            echo "Test plugins in isolated containers."
            echo ""
            echo "Plugins: ${ALL_PLUGINS[*]} docker"
            echo ""
            echo "Options:"
            echo "  --verbose     Show detailed output"
            echo "  --no-cleanup  Keep containers after test"
            echo "  --all         Test all plugins (excluding docker)"
            echo ""
            echo "Note: 'docker' plugin requires --privileged or socket mount."
            exit 0
            ;;
        *)
            PLUGINS+=("$1")
            shift
            ;;
    esac
done

# Default to all plugins if none specified
if [ ${#PLUGINS[@]} -eq 0 ]; then
    PLUGINS=("${ALL_PLUGINS[@]}")
fi

IMAGE_NAME="desktop:latest"

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_verbose() { [[ "$VERBOSE" == "true" ]] && echo -e "[DEBUG] $1"; }

# Check image exists
if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
    log_error "Image not found: $IMAGE_NAME"
    log_info "Build first with: make build"
    exit 2
fi

CONTAINERS=()
cleanup() {
    if [[ "$CLEANUP" == "true" ]]; then
        for cid in "${CONTAINERS[@]}"; do
            docker rm -f "$cid" &>/dev/null || true
        done
    fi
}
trap cleanup EXIT

# Test a single plugin
test_plugin() {
    local plugin="$1"
    local container_name="test-plugin-${plugin}-$$"
    local extra_args=""

    # Docker plugin needs special handling
    if [[ "$plugin" == "docker" ]]; then
        if [ -S /var/run/docker.sock ]; then
            extra_args="-v /var/run/docker.sock:/var/run/docker.sock"
        else
            extra_args="--privileged"
        fi
    fi

    log_info "Testing plugin: ${plugin}"

    # Start container with the plugin
    local cid
    cid=$(docker run -d \
        --name "$container_name" \
        --security-opt seccomp=unconfined \
        --shm-size=2g \
        -e "PLUGINS=${plugin}" \
        -e "VNC_PW=testpass" \
        $extra_args \
        "$IMAGE_NAME" 2>&1)

    if [ $? -ne 0 ]; then
        log_error "Failed to start container for plugin: ${plugin}"
        return 1
    fi

    CONTAINERS+=("$cid")
    log_verbose "Container started: ${cid:0:12}"

    # Wait for container to be ready (HTTP 200 on 6901 or timeout)
    local elapsed=0
    local port
    port=$(docker port "$cid" 6901 2>/dev/null | head -1 | cut -d: -f2 || echo "")

    if [ -z "$port" ]; then
        # No port mapping, wait for container to be running
        while [[ $elapsed -lt $TIMEOUT_STARTUP ]]; do
            local state
            state=$(docker inspect -f '{{.State.Status}}' "$cid" 2>/dev/null || echo "unknown")
            if [[ "$state" == "running" ]]; then
                break
            elif [[ "$state" == "exited" ]] || [[ "$state" == "dead" ]]; then
                log_error "Container exited for plugin: ${plugin}"
                [[ "$VERBOSE" == "true" ]] && docker logs "$cid" 2>&1 | tail -20
                return 1
            fi
            sleep $RETRY_INTERVAL
            elapsed=$((elapsed + RETRY_INTERVAL))
        done
        # Give plugins time to install
        sleep 30
    else
        while [[ $elapsed -lt $TIMEOUT_STARTUP ]]; do
            local http_code
            http_code=$(curl -sf -o /dev/null -w '%{http_code}' "http://localhost:${port}/" 2>/dev/null || echo "000")
            if [[ "$http_code" == "200" ]]; then
                log_verbose "Web interface ready for ${plugin}"
                break
            fi
            log_verbose "HTTP: ${http_code} (elapsed: ${elapsed}s)"
            sleep $RETRY_INTERVAL
            elapsed=$((elapsed + RETRY_INTERVAL))
        done
    fi

    # Wait for plugin installation to complete (marker file)
    local install_elapsed=0
    while [[ $install_elapsed -lt 120 ]]; do
        if docker exec "$cid" test -f "/opt/desktop/plugins/.installed/${plugin}" 2>/dev/null; then
            log_verbose "Plugin ${plugin} installation marker found"
            break
        fi
        sleep 5
        install_elapsed=$((install_elapsed + 5))
    done

    if [[ $install_elapsed -ge 120 ]]; then
        log_warn "Plugin ${plugin} install marker not found after 120s, running tests anyway"
    fi

    # Run plugin tests
    log_verbose "Running tests for ${plugin}..."
    if docker exec "$cid" bash /opt/desktop/plugins/${plugin}/tests.sh 2>&1; then
        log_info "PASS: ${plugin}"
        return 0
    else
        log_error "FAIL: ${plugin}"
        if [[ "$VERBOSE" == "true" ]]; then
            log_verbose "Container logs:"
            docker logs "$cid" 2>&1 | tail -30
        fi
        return 1
    fi
}

# Run all tests
echo ""
echo "========================================"
echo "  Plugin Test Runner"
echo "  Plugins: ${PLUGINS[*]}"
echo "========================================"
echo ""

PASSED=0
FAILED=0
FAILED_PLUGINS=()

for plugin in "${PLUGINS[@]}"; do
    if test_plugin "$plugin"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
        FAILED_PLUGINS+=("$plugin")
    fi
    echo ""
done

echo "========================================"
echo "  Results: ${PASSED} passed, ${FAILED} failed"
if [ $FAILED -gt 0 ]; then
    echo -e "  ${RED}Failed: ${FAILED_PLUGINS[*]}${NC}"
fi
echo "========================================"

exit $FAILED
