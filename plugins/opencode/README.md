# OpenCode

Installs [OpenCode](https://github.com/opencode-ai/opencode), an open-source terminal AI coding agent with a TUI interface.

## Details

- Downloads the latest `.deb` package from GitHub releases
- Supports both amd64 and arm64 architectures
- Single binary — no runtime dependencies
- Supports 75+ LLM providers (Claude, GPT, Gemini, Copilot, local models)

## Usage

```bash
PLUGINS=opencode
```

## Notes

- Requires an API key for the chosen LLM provider (e.g. `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`)
- Terminal-only tool — no desktop shortcut created
