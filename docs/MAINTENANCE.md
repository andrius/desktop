# Maintenance Guide

This guide covers system maintenance tasks for the Debian Docker Desktop.

## Maintenance Scripts

All maintenance scripts are located in `/opt/desktop/scripts/maintenance/` inside the container and `scripts/maintenance/` in the repository.

### System Update

Updates all system packages, Homebrew, and other package managers.

```bash
# Run inside container
/opt/desktop/scripts/maintenance/update-system.sh

# Or from host
docker compose exec desktop /opt/desktop/scripts/maintenance/update-system.sh
```

**What it updates:**
- APT packages (system packages)
- Homebrew packages
- npm global packages (if installed)
- snap packages (if installed)
- flatpak packages (if installed)

### System Cleanup

Removes temporary files, caches, and frees up disk space.

```bash
# Run inside container
/opt/desktop/scripts/maintenance/cleanup.sh

# Or from host
docker compose exec desktop /opt/desktop/scripts/maintenance/cleanup.sh
```

**What it cleans:**
- APT cache and old package lists
- Temporary files (`/tmp`, `/var/tmp`)
- User cache (`~/.cache`)
- Thumbnail cache
- Homebrew cache
- npm cache
- pip cache
- Browser caches (Firefox, Chrome)
- VS Code cached data
- Old system logs

### Health Check

Performs a comprehensive health check of the system.

```bash
# Run inside container
/opt/desktop/scripts/maintenance/health-check.sh

# Or from host
docker compose exec desktop /opt/desktop/scripts/maintenance/health-check.sh
```

**What it checks:**
- Disk space usage
- Memory usage
- X server status
- VNC server status
- Desktop environment (XFCE4)
- D-Bus daemon
- PulseAudio
- Network connectivity
- Package manager status
- Installed applications

## Regular Maintenance Schedule

### Daily (Automated)
- Container health checks (via Docker healthcheck)

### Weekly (Recommended)
- Run system updates: `update-system.sh`
- Check system health: `health-check.sh`

### Monthly (Recommended)
- Run full cleanup: `cleanup.sh`
- Review container logs
- Check for security updates

## Container Management

### Viewing Logs

```bash
# View container logs
docker compose logs

# Follow logs in real-time
docker compose logs -f

# View last 100 lines
docker compose logs --tail 100
```

### Restarting Services

```bash
# Restart the entire container
docker compose restart

# Restart specific services inside container
docker compose exec desktop pkill -HUP Xvfb
docker compose exec desktop pkill -HUP vncserver
```

### Backup User Data

The user's home directory is stored in a Docker volume. To backup:

```bash
# Create a backup
docker run --rm -v desktop-home:/data -v $(pwd):/backup \
  alpine tar czf /backup/home-backup-$(date +%Y%m%d).tar.gz -C /data .

# Restore from backup
docker run --rm -v desktop-home:/data -v $(pwd):/backup \
  alpine tar xzf /backup/home-backup-YYYYMMDD.tar.gz -C /data
```

### Recreating Container

To update to a new image while preserving data:

```bash
# Pull latest image
docker compose pull

# Recreate container (volumes are preserved)
docker compose up -d --force-recreate
```

## Troubleshooting

### High Disk Usage

1. Run cleanup script:
   ```bash
   /opt/desktop/scripts/maintenance/cleanup.sh
   ```

2. Check large files:
   ```bash
   du -sh /* 2>/dev/null | sort -h | tail -20
   ```

3. Check Docker volume:
   ```bash
   docker system df -v
   ```

### High Memory Usage

1. Check memory-heavy processes:
   ```bash
   ps aux --sort=-%mem | head -10
   ```

2. Kill unnecessary processes:
   ```bash
   pkill -9 process-name
   ```

3. Increase container memory limit in docker-compose.yml

### Network Issues

1. Check DNS resolution:
   ```bash
   nslookup google.com
   ```

2. Check connectivity:
   ```bash
   ping -c 3 8.8.8.8
   ```

3. Check Docker network:
   ```bash
   docker network inspect desktop-network
   ```

### VNC Connection Issues

1. Check VNC server status:
   ```bash
   pgrep -a vncserver
   ```

2. Check port binding:
   ```bash
   netstat -tlnp | grep -E "5901|6901"
   ```

3. Restart VNC:
   ```bash
   pkill vncserver
   /opt/desktop/scripts/start-kasmvnc.sh
   ```

### X Server Issues

1. Check Xvfb status:
   ```bash
   pgrep -a Xvfb
   ```

2. Check display:
   ```bash
   echo $DISPLAY
   xdpyinfo
   ```

3. Restart X server:
   ```bash
   pkill Xvfb
   Xvfb :1 -screen 0 1920x1080x24 &
   ```

## Automated Maintenance with Cron

You can set up automated maintenance inside the container:

```bash
# Edit crontab
crontab -e

# Add maintenance jobs
# Weekly system update (Sunday 2am)
0 2 * * 0 /opt/desktop/scripts/maintenance/update-system.sh >> /var/log/maintenance.log 2>&1

# Monthly cleanup (1st of month, 3am)
0 3 1 * * /opt/desktop/scripts/maintenance/cleanup.sh >> /var/log/maintenance.log 2>&1

# Daily health check (6am)
0 6 * * * /opt/desktop/scripts/maintenance/health-check.sh >> /var/log/maintenance.log 2>&1
```

## Security Updates

### Checking for Security Updates

```bash
# Check for security updates
apt list --upgradable 2>/dev/null | grep -i security

# Install security updates only
apt-get update && apt-get upgrade -y --only-upgrade
```

### Vulnerability Scanning

The GitHub Actions workflows include automated vulnerability scanning with Trivy. You can also run locally:

```bash
# Scan with Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image desktop:latest
```
