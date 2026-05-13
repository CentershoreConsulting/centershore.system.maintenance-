#!/bin/bash
################################################################################
# Centershore System Maintenance - Installation Script
# 
# This script installs the system maintenance toolkit to /opt/system-maintenance/
# Usage: sudo bash install.sh
################################################################################

set -euo pipefail

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This installation script must be run as root (use sudo)"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Installation directories
INSTALL_DIR="/opt/system-maintenance"
LOG_DIR="/var/log/system-maintenance"

echo "Installing Centershore System Maintenance..."
echo "Source directory: ${SCRIPT_DIR}"
echo "Install directory: ${INSTALL_DIR}"

# Create directories
mkdir -p "${INSTALL_DIR}/lib"
mkdir -p "${LOG_DIR}"

# Copy main script
if [[ -f "${SCRIPT_DIR}/system-maintenance.sh" ]]; then
    cp "${SCRIPT_DIR}/system-maintenance.sh" "${INSTALL_DIR}/"
    chmod 755 "${INSTALL_DIR}/system-maintenance.sh"
    echo "✓ Copied main script"
else
    echo "✗ Error: system-maintenance.sh not found in ${SCRIPT_DIR}"
    exit 1
fi

# Copy utility libraries
if [[ -d "${SCRIPT_DIR}/lib" ]]; then
    cp "${SCRIPT_DIR}/lib/"*.sh "${INSTALL_DIR}/lib/"
    chmod 644 "${INSTALL_DIR}/lib/"*.sh
    echo "✓ Copied library scripts:"
    ls -1 "${INSTALL_DIR}/lib/" | sed 's/^/  - /'
else
    echo "✗ Error: lib directory not found in ${SCRIPT_DIR}"
    exit 1
fi

# Copy cron configuration
if [[ -d "${SCRIPT_DIR}/cron" ]]; then
    mkdir -p /etc/cron.d
    cp "${SCRIPT_DIR}/cron/system-maintenance.cron" /etc/cron.d/system-maintenance
    chmod 644 /etc/cron.d/system-maintenance
    echo "✓ Installed cron configuration"
else
    echo "✗ Warning: cron directory not found, skipping cron setup"
fi

# Create log directory
mkdir -p "${LOG_DIR}"
chmod 755 "${LOG_DIR}"
echo "✓ Created log directory"

# Create symlink for easy access
ln -sf "${INSTALL_DIR}/system-maintenance.sh" /usr/local/bin/system-maintenance
echo "✓ Created command symlink at /usr/local/bin/system-maintenance"

echo ""
echo "=========================================="
echo "Installation completed successfully!"
echo "=========================================="
echo ""
echo "Installation paths:"
echo "  Main script: ${INSTALL_DIR}/system-maintenance.sh"
echo "  Libraries: ${INSTALL_DIR}/lib/"
echo "  Logs: ${LOG_DIR}/"
echo "  Cron config: /etc/cron.d/system-maintenance"
echo ""
echo "Quick start:"
echo "  sudo system-maintenance --help"
echo "  sudo system-maintenance"
echo ""
echo "View logs:"
echo "  tail -f /var/log/system-maintenance.log"
echo ""
echo "To restart cron and enable automatic scheduling:"
echo "  sudo systemctl restart cron  # Debian/Ubuntu"
echo "  sudo systemctl restart crond # RedHat/CentOS/Fedora"
echo ""
