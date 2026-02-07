# Docker

Installs [Docker Engine](https://docs.docker.com/engine/) for Docker-in-Docker (DinD) support.

## Details

- Adds Docker's official GPG key and APT repository (architecture-aware)
- Installs `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`
- Adds the container user to the `docker` group
- Starts `dockerd` if no Docker socket is mounted

## Usage

```bash
PLUGINS=docker
```

### Socket Mount (recommended)

Mount the host Docker socket instead of running DinD:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

The plugin automatically detects the mounted socket's group ID and adjusts the container's `docker` group GID to match, so the container user can access the socket without manual configuration.

### Docker-in-Docker

For full DinD, run the container with `--privileged`:

```yaml
services:
  desktop:
    privileged: true
    environment:
      - PLUGINS=docker
```

## Notes

- Socket mount is preferred over DinD for performance and security
- DinD requires `--privileged` mode
- The `docker compose` plugin is included (use `docker compose` not `docker-compose`)
