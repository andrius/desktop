# Cursor

Installs [Cursor](https://cursor.sh/), an AI-powered code editor.

## Details

- Downloaded as a `.deb` package from Cursor's API
- Installed via `dpkg -i` to `/usr/share/cursor/` with `/usr/bin/cursor` symlink
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
