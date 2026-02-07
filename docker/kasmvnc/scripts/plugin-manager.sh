#!/bin/bash
# Plugin Manager for Debian Desktop Docker
# Directory-based plugin system: each plugin is a folder with init.sh, tests.sh, README.md
set -e

PLUGIN_BASE_DIR="/opt/desktop/plugins"
MARKER_DIR="${PLUGIN_BASE_DIR}/.installed"
LOG_FILE="/var/log/plugin-manager.log"
REPO_URL="https://github.com/andrius/desktop.git"

# Source environment
source /opt/desktop/scripts/env-setup.sh

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" | tee -a "$LOG_FILE" 2>/dev/null || echo "$msg"
}

# Backward compatibility: convert ENABLE_* vars to PLUGINS list with deprecation warning
compat_enable_vars() {
    local compat_plugins=""
    local found_legacy=false

    declare -A legacy_map=(
        [ENABLE_CHROME]="chrome"
        [ENABLE_NOMACHINE]="nomachine"
        [ENABLE_CURSOR]="cursor"
        [ENABLE_VSCODE]="vscode"
        [ENABLE_CLAUDE_CODE]="claude-code"
        [ENABLE_XRDP]="xrdp"
        [ENABLE_DOCKER]="docker"
        [ENABLE_BREW]="brew"
    )

    for var in "${!legacy_map[@]}"; do
        if [ "${!var}" = "true" ]; then
            found_legacy=true
            if [ -n "$compat_plugins" ]; then
                compat_plugins="${compat_plugins},${legacy_map[$var]}"
            else
                compat_plugins="${legacy_map[$var]}"
            fi
        fi
    done

    if [ "$found_legacy" = true ]; then
        log "DEPRECATION WARNING: ENABLE_* variables are deprecated. Use PLUGINS=${compat_plugins} instead."
        if [ -n "$PLUGINS" ]; then
            PLUGINS="${PLUGINS},${compat_plugins}"
        else
            PLUGINS="$compat_plugins"
        fi
        export PLUGINS
    fi
}

# Install a single plugin by name
install_plugin() {
    local name="$1"
    local init_script="${PLUGIN_BASE_DIR}/${name}/init.sh"
    local marker="${MARKER_DIR}/${name}"

    if [ ! -f "$init_script" ]; then
        log "ERROR: Plugin '${name}' not found at ${init_script}"
        return 1
    fi

    if [ -f "$marker" ]; then
        log "Plugin '${name}' already installed (marker exists), skipping"
        return 0
    fi

    log "Installing plugin: ${name}"
    if bash -e "$init_script" 2>&1 | tee -a "$LOG_FILE"; then
        mkdir -p "$MARKER_DIR"
        touch "$marker"
        log "Plugin '${name}' installed successfully"
        return 0
    else
        log "ERROR: Plugin '${name}' installation failed"
        return 1
    fi
}

# Install all plugins from PLUGINS env var
install_plugins() {
    compat_enable_vars

    if [ -z "${PLUGINS:-}" ]; then
        log "No plugins configured (PLUGINS is empty)"
        return 0
    fi

    log "Starting plugin installation for: ${PLUGINS}"
    mkdir -p "$MARKER_DIR"

    local IFS=','
    for plugin in $PLUGINS; do
        plugin=$(echo "$plugin" | xargs)  # trim whitespace
        [ -z "$plugin" ] && continue
        install_plugin "$plugin" || log "WARNING: Plugin '${plugin}' failed, continuing..."
    done

    log "Plugin installation completed"
}

# List available plugins
list_plugins() {
    echo "Available plugins:"
    echo ""

    if [ ! -d "$PLUGIN_BASE_DIR" ]; then
        echo "  (no plugin directory found)"
        return 0
    fi

    for dir in "$PLUGIN_BASE_DIR"/*/; do
        [ -d "$dir" ] || continue
        local name
        name=$(basename "$dir")
        [ "$name" = ".installed" ] && continue

        local status="available"
        if [ -f "${MARKER_DIR}/${name}" ]; then
            status="installed"
        fi

        local desc=""
        if [ -f "${dir}/README.md" ]; then
            desc=$(head -1 "${dir}/README.md" | sed 's/^#\+\s*//')
        fi

        printf "  %-15s [%s] %s\n" "$name" "$status" "$desc"
    done

    echo ""
    echo "Configure plugins: PLUGINS=brew,vscode,cursor (comma-separated)"
}

# Run tests for a plugin
test_plugin() {
    local name="$1"
    local test_script="${PLUGIN_BASE_DIR}/${name}/tests.sh"

    if [ ! -f "$test_script" ]; then
        echo "No tests found for plugin '${name}'"
        return 1
    fi

    echo "Running tests for plugin: ${name}"
    bash -e "$test_script"
}

# Update plugins from remote repository via sparse-checkout
update_plugins() {
    log "Updating plugins from ${REPO_URL}..."

    local tmpdir="/tmp/plugin-update-$$"
    if git clone --depth 1 --filter=blob:none --sparse "$REPO_URL" "$tmpdir" 2>&1 | tee -a "$LOG_FILE"; then
        cd "$tmpdir"
        git sparse-checkout set plugins/ 2>&1 | tee -a "$LOG_FILE"
        if [ -d "plugins" ] && [ "$(ls -A plugins/)" ]; then
            cp -r plugins/* "$PLUGIN_BASE_DIR/"
            log "Plugins updated successfully"
        else
            log "WARNING: No plugins found in remote repository"
        fi
        rm -rf "$tmpdir"
    else
        log "WARNING: Failed to update plugins from remote (continuing with bundled plugins)"
        rm -rf "$tmpdir"
        return 1
    fi
}

# Command dispatcher
case "${1:-install}" in
    install)
        install_plugins
        ;;
    list)
        list_plugins
        ;;
    test)
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 test <plugin-name>"
            exit 1
        fi
        test_plugin "$2"
        ;;
    update)
        update_plugins
        ;;
    *)
        # Try as a direct plugin name for backward compat
        if [ -f "${PLUGIN_BASE_DIR}/$1/init.sh" ]; then
            install_plugin "$1"
        else
            echo "Usage: $0 {install|list|test <name>|update|<plugin-name>}"
            exit 1
        fi
        ;;
esac
