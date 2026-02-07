# XRDP

Installs [XRDP](http://www.xrdp.org/) remote desktop server alongside KasmVNC.

## Details

- Installs `xrdp` and `xorgxrdp` packages
- Creates `~/.xsession` configured for XFCE4
- Listens on port **3389** (standard RDP)
- Coexists with KasmVNC — both can run simultaneously

## Usage

```bash
PLUGINS=xrdp
```

Expose port 3389 in your compose file:

```yaml
ports:
  - "${XRDP_PORT:-3389}:3389"
```

## Connecting

Use any RDP client (Microsoft Remote Desktop, Remmina, FreeRDP):

```bash
xfreerdp /v:localhost:3389 /u:user /p:password
```
