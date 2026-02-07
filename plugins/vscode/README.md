# Visual Studio Code

Installs [Visual Studio Code](https://code.visualstudio.com/) from Microsoft's official APT repository.

## Details

- Adds Microsoft GPG key and APT repository
- Multi-arch repository supports **amd64**, **arm64**, and **armhf**
- Creates a desktop shortcut with `--no-sandbox` flag

## Usage

```bash
PLUGINS=vscode
```

## Notes

- The `--no-sandbox` flag is required when running inside Docker containers
- Extensions can be installed via the GUI or `code --install-extension`
