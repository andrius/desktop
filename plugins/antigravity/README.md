# Antigravity

Installs [Google Antigravity](https://antigravity.dev/) IDE — Google's Electron-based VS Code fork with AI-first agent management features.

## Details

- **amd64 only** — Google does not provide arm64 Linux packages
- Adds the official Google Antigravity APT repository
- Installs `antigravity`
- Creates a desktop shortcut with `--no-sandbox` (required inside containers)

## Usage

```bash
PLUGINS=antigravity
```

No port forwarding required — Antigravity is a desktop application accessed through the remote desktop session.

## Notes

- The `--no-sandbox` flag is required when running inside a Docker container
- Antigravity runs within the existing desktop session (KasmVNC, XRDP, or NoMachine)
- Some paths (chrome-sandbox, .desktop file locations) may need adjustment after first install — see plan notes
