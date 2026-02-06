#!/bin/bash
# Start Selkies GStreamer WebRTC server
set -e

source /opt/desktop/scripts/env-setup.sh

# Selkies configuration
SELKIES_PORT=${SELKIES_WEB_PORT:-8080}
SELKIES_ENCODER=${SELKIES_ENCODER:-x264enc}
SELKIES_ENABLE_RESIZE=${SELKIES_ENABLE_RESIZE:-true}
SELKIES_ENABLE_BASIC_AUTH=${SELKIES_ENABLE_BASIC_AUTH:-false}

# Resolution settings
RESOLUTION=${RESOLUTION:-1920x1080x24}
RESOLUTION_X=$(echo $RESOLUTION | cut -d'x' -f1)
RESOLUTION_Y=$(echo $RESOLUTION | cut -d'x' -f2)
FRAMERATE=${FRAMERATE:-30}

echo "Starting Selkies GStreamer WebRTC server..."
echo "  Display: ${DISPLAY}"
echo "  Resolution: ${RESOLUTION_X}x${RESOLUTION_Y}"
echo "  Encoder: ${SELKIES_ENCODER}"
echo "  Port: ${SELKIES_PORT}"

# Authentication setup
AUTH_ARGS=""
if [ "$SELKIES_ENABLE_BASIC_AUTH" = "true" ] && [ -n "$SELKIES_BASIC_AUTH_USER" ] && [ -n "$SELKIES_BASIC_AUTH_PASSWORD" ]; then
    AUTH_ARGS="--enable_basic_auth --basic_auth_user=${SELKIES_BASIC_AUTH_USER} --basic_auth_password=${SELKIES_BASIC_AUTH_PASSWORD}"
fi

# TURN server configuration
TURN_ARGS=""
if [ -n "$SELKIES_TURN_HOST" ]; then
    TURN_ARGS="--turn_host=${SELKIES_TURN_HOST}"
    if [ -n "$SELKIES_TURN_PORT" ]; then
        TURN_ARGS="${TURN_ARGS} --turn_port=${SELKIES_TURN_PORT}"
    fi
    if [ -n "$SELKIES_TURN_USERNAME" ] && [ -n "$SELKIES_TURN_PASSWORD" ]; then
        TURN_ARGS="${TURN_ARGS} --turn_username=${SELKIES_TURN_USERNAME} --turn_password=${SELKIES_TURN_PASSWORD}"
    fi
    TURN_ARGS="${TURN_ARGS} --turn_protocol=${SELKIES_TURN_PROTOCOL:-udp}"
fi

# Build the command
SELKIES_CMD="selkies-gstreamer"
SELKIES_CMD="${SELKIES_CMD} --addr=0.0.0.0"
SELKIES_CMD="${SELKIES_CMD} --port=${SELKIES_PORT}"
SELKIES_CMD="${SELKIES_CMD} --encoder=${SELKIES_ENCODER}"
SELKIES_CMD="${SELKIES_CMD} --framerate=${FRAMERATE}"

if [ "$SELKIES_ENABLE_RESIZE" = "true" ]; then
    SELKIES_CMD="${SELKIES_CMD} --enable_resize"
fi

SELKIES_CMD="${SELKIES_CMD} ${AUTH_ARGS} ${TURN_ARGS}"

echo "Running: ${SELKIES_CMD}"

# Execute Selkies
exec ${SELKIES_CMD}
