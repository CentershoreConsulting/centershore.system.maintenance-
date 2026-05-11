#!/bin/bash
################################################################################
# Centershore System Maintenance - Installation Script
# 
# This script installs the system maintenance toolkit to /opt/system-maintenance/
################################################################################

set -euo pipefail

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This installation script must be run as root (use sudo)"
    exit 1
fi

# Installation directory
INSTALL_DIR="/opt/system-maintenance"
LOG_DIR="/var/log/system-maintenance"

echo "Installing Centershore System Maintenance..."

# Create directories
mkdir -p "${INSTALL_DIR}/lib"
mkdir -p "${LOG_DIR}"

# Copy main script
cp system-maintenance.sh "${INSTALL_DIR}/"
chmod 755 "${INSTALL_DIR}/system-maintenance.sh"

# Copy utility libraries
cp lib/*.sh "${INSTALL_DIR}/lib/"
chmod 644 "${INSTALL_DIR}/lib/"*.sh

# Copy cron configuration
mkdir -p /etc/cron.d
cp cron/system-maintenance.cron /etc/cron.d/system-maintenance
chmod 644 /etc/cron.d/system-maintenance

# Create log directory
mkdir -p "${LOG_DIR}"
chmod 755 "${LOG_DIR}"

# Create symlink for easy access
ln -sf "${INSTALL_DIR}/system-maintenance.sh" /usr/local/bin/system-maintenance

echo "Installation completed!"
echo ""
echo "Installation paths:"
echo "  Main script: ${INSTALL_DIR}/system-maintenance.sh"
echo "  Libraries: ${INSTALL_DIR}/lib/"
echo "  Logs: ${LOG_DIR}/"
echo "  Cron config: /etc/cron.d/system-maintenance"
echo ""
echo "To run maintenance immediately:"
echo "  sudo system-maintenance"
echo ""
echo "To view help:"
echo "  sudo system-maintenance --help"
echo ""
echo "To enable automatic cron scheduling:"
echo "  sudo systemctl restart cron  # or 'crond' for RedHat-based systems"
echo ""
