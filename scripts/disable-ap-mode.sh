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

# Detect network manager (Bookworm uses NetworkManager, Bullseye uses dhcpcd)
if systemctl is-active --quiet NetworkManager; then
    USE_NETWORKMANAGER=true
    log_info "Detected NetworkManager (Bookworm-style)"
elif systemctl list-unit-files | grep -q "dhcpcd.service"; then
    USE_NETWORKMANAGER=false
    log_info "Detected dhcpcd (Bullseye-style)"
else
    USE_NETWORKMANAGER=true
    log_info "Assuming NetworkManager setup"
fi

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
rm -f /etc/NetworkManager/conf.d/pibot-ap.conf
rm -f /etc/systemd/network/10-pibot-ap.network

# Restore dhcpcd.conf - remove Pi-Bot AP Configuration block (only for Bullseye)
if [ "$USE_NETWORKMANAGER" = false ] && [ -f /etc/dhcpcd.conf ]; then
    log_info "Restoring dhcpcd.conf..."
    # Remove the Pi-Bot AP configuration block
    sed -i '/# Pi-Bot AP Configuration/,/nohook wpa_supplicant/d' /etc/dhcpcd.conf
    # Remove any trailing empty lines
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' /etc/dhcpcd.conf

    # Alternatively, restore from backup if it exists
    if [ -f "$BACKUP_DIR/dhcpcd.conf.backup" ]; then
        log_info "Backup found - restoring original dhcpcd.conf"
        cp "$BACKUP_DIR/dhcpcd.conf.backup" /etc/dhcpcd.conf
    fi
fi

# Reset hostapd default config
if [ -f /etc/default/hostapd ]; then
    sed -i 's|^DAEMON_CONF=.*|#DAEMON_CONF=""|' /etc/default/hostapd
fi

# Restart networking
log_info "Restarting networking services..."
if [ "$USE_NETWORKMANAGER" = true ]; then
    # On Bookworm, re-enable NetworkManager control of wlan0
    nmcli device set $INTERFACE managed yes 2>/dev/null || true
    systemctl restart NetworkManager
else
    systemctl restart dhcpcd
fi

# Re-enable wpa_supplicant for normal WiFi (only needed on Bullseye)
if [ "$USE_NETWORKMANAGER" = false ]; then
    systemctl enable wpa_supplicant 2>/dev/null || true
    systemctl start wpa_supplicant 2>/dev/null || true
fi

echo ""
echo "=============================================="
echo -e "${GREEN}AP Mode Disabled Successfully!${NC}"
echo "=============================================="
echo ""
echo "The Pi is now in normal WiFi client mode."
echo ""
echo "To connect to a WiFi network:"
if [ "$USE_NETWORKMANAGER" = true ]; then
    echo "  nmcli device wifi list                    # List available networks"
    echo "  nmcli device wifi connect SSID password PASSWORD"
    echo "  or: sudo raspi-config  (System Options > Wireless LAN)"
else
    echo "  sudo raspi-config  (Network Options > Wireless LAN)"
    echo "  or edit /etc/wpa_supplicant/wpa_supplicant.conf"
fi
echo ""
echo "To re-enable AP mode:"
echo "  sudo /opt/pi-bot/scripts/setup-ap-mode.sh [SSID] [PASSWORD]"
echo ""
echo "NOTE: Reboot recommended for changes to fully apply"
echo "  sudo reboot"
echo ""
