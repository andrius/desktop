# Claude Code

Installs [Claude Code](https://docs.anthropic.com/en/docs/claude-code), the CLI tool for working with Claude.

## Details

- Requires **Node.js** (installed automatically if not present)
- If Homebrew is available, uses `brew install node`; otherwise uses NodeSource
- Installed globally via `npm install -g @anthropic-ai/claude-code`

## Usage

```bash
PLUGINS=claude-code
```

For the best experience, install Homebrew first:

```bash
PLUGINS=brew,claude-code
```

## Notes

- Plugin ordering matters: if using `brew` for Node.js, list `brew` before `claude-code`
- Requires an API key to use — set `ANTHROPIC_API_KEY` environment variable
