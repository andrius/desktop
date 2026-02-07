# NoMachine

Installs [NoMachine](https://www.nomachine.com/) remote desktop server.

## Details

- Supports **amd64** and **arm64** architectures
- Downloads the `.deb` from `download.nomachine.com`
- Version pinned to `9.3.7`
- Listens on port **4000** (NX protocol, TCP + UDP)
- Provides audio, file transfer, and multi-monitor support
- Port must be forwarded in compose file for external access

## Usage

```bash
PLUGINS=nomachine
```

Expose port 4000 in your compose file:

```yaml
ports:
  - "${NOMACHINE_PORT:-4000}:4000"
```

## Connecting

Download the NoMachine client from [nomachine.com](https://www.nomachine.com/download) and connect to `localhost:4000`.
