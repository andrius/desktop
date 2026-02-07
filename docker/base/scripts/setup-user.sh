#!/bin/bash
# Runtime user creation/adjustment script
# Runs as root at container entrypoint start
# Handles configurable USERNAME, USER_UID, USER_GID at runtime
set -e

TARGET_USER="${USERNAME:-user}"
TARGET_UID="${USER_UID:-1000}"
TARGET_GID="${USER_GID:-1000}"

echo "Setting up user: ${TARGET_USER} (uid=${TARGET_UID}, gid=${TARGET_GID})"

# --- Group setup ---
EXISTING_GROUP=$(getent group "${TARGET_GID}" | cut -d: -f1 || true)
if [ -n "$EXISTING_GROUP" ] && [ "$EXISTING_GROUP" != "$TARGET_USER" ]; then
    # GID is taken by a different group — rename it
    groupmod -n "$TARGET_USER" "$EXISTING_GROUP"
elif [ -z "$EXISTING_GROUP" ]; then
    # GID does not exist — create the group
    if getent group "$TARGET_USER" >/dev/null 2>&1; then
        # Group name exists with different GID — change its GID
        groupmod -g "$TARGET_GID" "$TARGET_USER"
    else
        groupadd --gid "$TARGET_GID" "$TARGET_USER"
    fi
fi

# --- User setup ---
EXISTING_USER=$(getent passwd "${TARGET_UID}" | cut -d: -f1 || true)
if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "$TARGET_USER" ]; then
    # UID is taken by a different user (e.g., build-time user) — rename
    usermod -l "$TARGET_USER" -d "/home/${TARGET_USER}" -m "$EXISTING_USER" 2>/dev/null || true
    # Also update the primary group
    usermod -g "$TARGET_GID" "$TARGET_USER" 2>/dev/null || true
elif [ -z "$EXISTING_USER" ]; then
    # UID does not exist — create the user
    useradd --uid "$TARGET_UID" --gid "$TARGET_GID" -m -s /bin/bash "$TARGET_USER"
fi

# Ensure correct primary group
usermod -g "$TARGET_GID" "$TARGET_USER" 2>/dev/null || true

# --- Supplementary groups (ssl-cert needed for KasmVNC) ---
if getent group ssl-cert >/dev/null 2>&1; then
    usermod -a -G ssl-cert "$TARGET_USER" 2>/dev/null || true
fi

# --- Passwordless sudo ---
echo "${TARGET_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${TARGET_USER}"
chmod 0440 "/etc/sudoers.d/${TARGET_USER}"

# --- Set user password if provided (required for NoMachine/XRDP PAM login) ---
if [ -n "${USER_PASSWORD:-}" ]; then
    echo "${TARGET_USER}:${USER_PASSWORD}" | chpasswd
    echo "User password set for ${TARGET_USER}"
fi

# --- Home directory ---
USER_HOME="/home/${TARGET_USER}"
mkdir -p "$USER_HOME"
chown "${TARGET_UID}:${TARGET_GID}" "$USER_HOME"

# Export for downstream scripts
export USERNAME="$TARGET_USER"
export USER="$TARGET_USER"
export HOME="$USER_HOME"

echo "User setup complete: ${TARGET_USER} (uid=${TARGET_UID}, gid=${TARGET_GID})"
