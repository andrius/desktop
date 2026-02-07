# Google Chrome

Installs [Google Chrome](https://www.google.com/chrome/) web browser.

## Details

- **amd64 only** — Google does not provide arm64 Linux `.deb` packages
- Adds the official Google Chrome APT repository
- Installs `google-chrome-stable`
- Creates a desktop shortcut with `--no-sandbox` (required inside containers)

## Usage

```bash
PLUGINS=chrome
```

No port forwarding required — Chrome is a desktop application accessed through the remote desktop session.

## Notes

- The `--no-sandbox` flag is required when running inside a Docker container
- Chrome runs within the existing desktop session (KasmVNC, Selkies, XRDP, or NoMachine)
