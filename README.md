# Centershore System Maintenance

A comprehensive system-level maintenance and updates toolkit for multiple Linux distributions.

## Features

- **Multi-Distribution Support**: Debian/Ubuntu, RedHat/CentOS/Fedora, Arch Linux, Alpine, and openSUSE
- **System Updates**: Full system package updates with automatic dependency resolution
- **Security Updates**: Priority security patching
- **System Cleanup**: Remove unnecessary packages, cache cleanup, temporary files
- **Maintenance Tasks**: Log rotation, disk space analysis, service optimization
- **Safe Operations**: Pre-flight checks, rollback capabilities, detailed logging
- **Cron Scheduling**: Ready-to-use cron configurations

## Usage

### Quick Start

```bash
# Full system maintenance (updates + cleanup + optimization)
sudo ./system-maintenance.sh

# Security updates only
sudo ./system-maintenance.sh --security-only

# Cleanup only
sudo ./system-maintenance.sh --cleanup-only

# Dry-run (shows what would be done)
sudo ./system-maintenance.sh --dry-run

# Enable verbose logging
sudo ./system-maintenance.sh --verbose
```

### Available Options

- `--security-only`: Only apply security updates
- `--cleanup-only`: Only perform cleanup tasks
- `--dry-run`: Preview changes without applying them
- `--verbose`: Enable detailed logging
- `--skip-backup`: Skip system backup (not recommended)
- `--force`: Force execution even if checks fail
- `--help`: Display help information

## Script Structure

### Main Scripts

1. **system-maintenance.sh** - Main orchestration script
2. **distro-detector.sh** - Automatic Linux distribution detection
3. **lib/debian-utils.sh** - Debian/Ubuntu specific functions
4. **lib/redhat-utils.sh** - RedHat/CentOS/Fedora specific functions
5. **lib/arch-utils.sh** - Arch Linux specific functions
6. **lib/alpine-utils.sh** - Alpine Linux specific functions
7. **lib/opensuse-utils.sh** - openSUSE specific functions
8. **lib/common-utils.sh** - Cross-distro utilities

### Cron Integration

Schedule automatic maintenance:

```bash
# Copy cron configuration
sudo cp cron/system-maintenance.cron /etc/cron.d/system-maintenance

# Run daily at 2 AM
0 2 * * * root /opt/system-maintenance/system-maintenance.sh >> /var/log/system-maintenance.log 2>&1
```

## Logs

Maintenance activities are logged to:
- `/var/log/system-maintenance.log` - Main log file
- `/var/log/system-maintenance/` - Detailed logs per operation

## Safety Features

- Pre-flight system checks
- Disk space validation
- Service health verification
- Automatic rollback on critical failures
- Detailed logging of all operations

## Supported Distributions

- Ubuntu 18.04 LTS+
- Debian 10+
- CentOS 7+
- RHEL 7+
- Fedora 30+
- Arch Linux
- Alpine Linux 3.12+
- openSUSE Leap 15+

## License

Centershore Consulting Inc.
