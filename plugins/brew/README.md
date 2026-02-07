# Homebrew

Installs [Homebrew](https://brew.sh/), the Linux package manager.

## Details

- Installed at `/home/linuxbrew/.linuxbrew` (standard Linux path)
- Runs as the target user (not root) — Homebrew refuses root installation
- Adds `brew shellenv` to `~/.bashrc` and `~/.profile`
- Installs build dependencies: `build-essential`, `procps`, `curl`, `file`, `git`
- Runs `brew doctor` after installation

## Usage

```bash
PLUGINS=brew
```

## Notes

- Homebrew is installed as the container user, not root
- Auto-update and analytics are disabled by default via env vars
- Other plugins (e.g. `claude-code`) can use Homebrew to install their dependencies
