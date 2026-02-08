# Examples

Docker Compose examples for common deployment scenarios.

| Example | Description | Plugins |
|---------|-------------|---------|
| [basic](basic/) | Minimal single-desktop setup | none |
| [developer](developer/) | Developer workstation with IDE and Docker | brew, vscode, docker |
| [remote-access](remote-access/) | Multiple remote access methods | xrdp, nomachine |
| [multi-desktop](multi-desktop/) | Multiple isolated desktop instances | varies per instance |
| [reverse-proxy](reverse-proxy/) | KasmVNC behind HTTPS proxy (Caddy) | any |

## Quick Start

```bash
cd examples/basic
docker compose up -d
open http://localhost:6901
```

For examples with `.env.example`, copy it to `.env` and edit before starting:

```bash
cp .env.example .env
# edit .env
docker compose up -d
```

## Building Locally

The examples use `ghcr.io/andrius/desktop:latest` by default. To use a locally built image, either change `image:` to `desktop:latest` or build and tag:

```bash
# from the project root
make prepare && make build
docker tag desktop:latest ghcr.io/andrius/desktop:latest
```
