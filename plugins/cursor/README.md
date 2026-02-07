# Cursor

Installs [Cursor](https://cursor.sh/), an AI-powered code editor.

## Details

- Downloaded as an AppImage
- Installed to `/opt/cursor/cursor`
- Symlinked to `/usr/local/bin/cursor`
- Supports **amd64** and **arm64** architectures
- Creates a desktop shortcut with `--no-sandbox` flag
- Runs with `--no-sandbox` (required in container environments)

## Usage

```bash
PLUGINS=cursor
```

## Notes

- Cursor is based on VS Code and uses the same extension ecosystem
- The `--no-sandbox` flag is required when running inside Docker containers
- arm64 AppImage availability depends on Cursor's release schedule
