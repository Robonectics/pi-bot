#!/bin/bash
#
# Pi-Bot Service Uninstaller
# Removes the pibot systemd service
#
# Usage: sudo ./uninstall-service.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} This script must be run as root (use sudo)"
    exit 1
fi

SERVICE_FILE="/etc/systemd/system/pibot.service"

if [ ! -f "$SERVICE_FILE" ]; then
    log_warn "Pi-Bot service is not installed"
    exit 0
fi

log_info "Uninstalling Pi-Bot service..."

# Stop service if running
if systemctl is-active --quiet pibot.service; then
    log_info "Stopping service..."
    systemctl stop pibot.service
fi

# Disable and remove
log_info "Disabling service..."
systemctl disable pibot.service 2>/dev/null || true

log_info "Removing service file..."
rm -f "$SERVICE_FILE"

systemctl daemon-reload

echo ""
echo -e "${GREEN}Pi-Bot service uninstalled.${NC}"
echo ""
echo "The Pi-Bot files are still in place."
echo "To run manually: sudo venv/bin/python3 pibotweb.py"
echo ""
