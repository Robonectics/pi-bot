#!/bin/bash
#
# Pi-Bot WiFi Access Point Disable Script
# Restores normal WiFi client mode so Pi can connect to existing networks
#
# Usage: sudo ./disable-ap-mode.sh
#

set -e

INTERFACE="wlan0"
BACKUP_DIR="/etc/pibot-backup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Check if AP mode is configured
if [ ! -f /etc/pibot-ap-mode ]; then
    log_warn "AP mode doesn't appear to be configured"
    log_info "Proceeding with cleanup anyway..."
fi

log_info "Disabling Pi-Bot Access Point mode..."

# Stop AP services
log_info "Stopping AP services..."
systemctl stop hostapd 2>/dev/null || true
systemctl stop dnsmasq 2>/dev/null || true

# Disable AP services from starting at boot
systemctl disable hostapd 2>/dev/null || true
systemctl disable dnsmasq 2>/dev/null || true

# Remove AP configurations
log_info "Removing AP configurations..."
rm -f /etc/dnsmasq.d/pibot-ap.conf
rm -f /etc/hostapd/hostapd.conf
rm -f /etc/pibot-ap-mode

# Restore dhcpcd.conf - remove Pi-Bot AP Configuration block
if [ -f /etc/dhcpcd.conf ]; then
    log_info "Restoring dhcpcd.conf..."
    # Remove the Pi-Bot AP configuration block
    sed -i '/# Pi-Bot AP Configuration/,/nohook wpa_supplicant/d' /etc/dhcpcd.conf
    # Remove any trailing empty lines
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' /etc/dhcpcd.conf
fi

# Alternatively, restore from backup if it exists
if [ -f "$BACKUP_DIR/dhcpcd.conf.backup" ]; then
    log_info "Backup found - restoring original dhcpcd.conf"
    cp "$BACKUP_DIR/dhcpcd.conf.backup" /etc/dhcpcd.conf
fi

# Reset hostapd default config
if [ -f /etc/default/hostapd ]; then
    sed -i 's|^DAEMON_CONF=.*|#DAEMON_CONF=""|' /etc/default/hostapd
fi

# Restart networking
log_info "Restarting networking services..."
systemctl restart dhcpcd

# Re-enable wpa_supplicant for normal WiFi
systemctl enable wpa_supplicant 2>/dev/null || true
systemctl start wpa_supplicant 2>/dev/null || true

echo ""
echo "=============================================="
echo -e "${GREEN}AP Mode Disabled Successfully!${NC}"
echo "=============================================="
echo ""
echo "The Pi is now in normal WiFi client mode."
echo ""
echo "To connect to a WiFi network:"
echo "  sudo raspi-config  (Network Options > Wireless LAN)"
echo "  or edit /etc/wpa_supplicant/wpa_supplicant.conf"
echo ""
echo "To re-enable AP mode:"
echo "  sudo ./setup-ap-mode.sh [SSID] [PASSWORD]"
echo ""
echo "NOTE: Reboot recommended for changes to fully apply"
echo "  sudo reboot"
echo ""
