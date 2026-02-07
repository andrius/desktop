# User Management

This guide covers user creation, configuration, and permissions in the Debian Docker Desktop.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `USERNAME` | `user` | Desktop username |
| `USER_UID` | `1000` | User ID |
| `USER_GID` | `1000` | Group ID |

## How It Works

### Runtime User Creation (`setup-user.sh`)

On container start, `setup-user.sh` runs as root and:

1. Checks if the target user exists
2. If not, creates the user with the specified UID/GID
3. If the user exists but UID/GID differ, renames or adjusts the existing user
4. Grants passwordless sudo via `/etc/sudoers.d/<username>`
5. Ensures home directory ownership is correct

This allows runtime user creation without rebuilding the image.

### User Environment (`init-user.sh`)

After user setup, `init-user.sh` creates:

- Standard XDG directories (`~/.config`, `~/.local`, `~/.cache`)
- Desktop directories (`~/Desktop`, `~/Downloads`, `~/Documents`, etc.)
- XFCE configuration (session, panel, theme, desktop background)
- Desktop shortcuts (Firefox, Terminal, File Manager)
- Autostart entries for display/shortcut setup

## Passwordless Sudo

The container user has full passwordless sudo:

```bash
# No password required
sudo apt-get install ...
sudo systemctl ...
```

This is configured via `/etc/sudoers.d/<username>`:
```
user ALL=(ALL) NOPASSWD:ALL
```

## Volume Permissions

When mounting host directories, match the container UID/GID to your host user:

```bash
# Check your host UID/GID
id -u   # e.g., 1000
id -g   # e.g., 1000

# Set in .env
USER_UID=1000
USER_GID=1000
```

### Named Volume (default)

The default `desktop-home` volume is owned by the container user automatically:

```yaml
volumes:
  - desktop-home:/home/${USERNAME:-user}
```

### Bind Mount

For bind mounts, ensure the host directory is owned by the matching UID:

```yaml
volumes:
  - /path/on/host:/home/user/projects
```

```bash
# On the host, match ownership
sudo chown -R 1000:1000 /path/on/host
```

## Examples

### Custom Username

```bash
# .env
USERNAME=developer
USER_UID=1000
USER_GID=1000
```

### Non-Standard UID/GID

```bash
# .env
USERNAME=myuser
USER_UID=1500
USER_GID=1500
```

### Multiple Containers with Different Users

```bash
# Container 1
docker run -e USERNAME=alice -e USER_UID=1001 ...

# Container 2
docker run -e USERNAME=bob -e USER_UID=1002 ...
```
