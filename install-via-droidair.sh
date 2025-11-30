#!/bin/bash
#
# Pi-Bot Installer via DroidAir
# Connects to DroidAir WiFi hotspot, then runs the full installer
#
# Usage:
#   sudo ./install-via-droidair.sh <droidair-password>
#
# Example:
#   sudo ./install-via-droidair.sh myhotspotpass
#

set -e

DROIDAIR_SSID="DroidAir"
DROIDAIR_PASSWORD="$1"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${CYAN}"
echo "╔════════════════════════════════════════════╗"
echo "║    Pi-Bot Installer via DroidAir           ║"
echo "╚════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Check for password argument
if [ -z "$DROIDAIR_PASSWORD" ]; then
    log_error "DroidAir password required"
    echo ""
    echo "Usage: sudo $0 <droidair-password>"
    echo ""
    exit 1
fi

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi\|BCM" /proc/cpuinfo 2>/dev/null; then
    log_error "This script must be run on a Raspberry Pi"
    exit 1
fi

log_info "Connecting to $DROIDAIR_SSID..."

# Add DroidAir network to wpa_supplicant
WPA_CONF="/etc/wpa_supplicant/wpa_supplicant.conf"

# Backup existing config
if [ -f "$WPA_CONF" ]; then
    cp "$WPA_CONF" "${WPA_CONF}.backup"
fi

# Check if network already configured
if grep -q "ssid=\"$DROIDAIR_SSID\"" "$WPA_CONF" 2>/dev/null; then
    log_info "DroidAir already configured, updating password..."
    # Remove existing DroidAir block and add new one
    sed -i "/network={/,/}/{ /ssid=\"$DROIDAIR_SSID\"/,/}/d }" "$WPA_CONF"
fi

# Add network configuration
cat >> "$WPA_CONF" << EOF

network={
    ssid="$DROIDAIR_SSID"
    psk="$DROIDAIR_PASSWORD"
    key_mgmt=WPA-PSK
}
EOF

log_info "Network configured, restarting WiFi..."

# Restart WiFi
wpa_cli -i wlan0 reconfigure > /dev/null 2>&1 || true

# Wait for connection
log_info "Waiting for connection..."
TIMEOUT=30
CONNECTED=false

for i in $(seq 1 $TIMEOUT); do
    if iwgetid -r 2>/dev/null | grep -q "$DROIDAIR_SSID"; then
        CONNECTED=true
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

if [ "$CONNECTED" = false ]; then
    log_error "Failed to connect to $DROIDAIR_SSID"
    log_error "Check password and make sure DroidAir hotspot is active"
    # Restore backup
    if [ -f "${WPA_CONF}.backup" ]; then
        mv "${WPA_CONF}.backup" "$WPA_CONF"
    fi
    exit 1
fi

log_info "Connected to $DROIDAIR_SSID!"

# Wait for IP address
log_info "Waiting for IP address..."
sleep 3

IP_ADDR=$(hostname -I | awk '{print $1}')
if [ -n "$IP_ADDR" ]; then
    log_info "Got IP: $IP_ADDR"
else
    log_warn "No IP yet, waiting longer..."
    sleep 5
fi

# Test internet connectivity
log_info "Testing internet connection..."
if ! ping -c 1 github.com > /dev/null 2>&1; then
    log_error "Cannot reach github.com - check DroidAir internet sharing"
    exit 1
fi
log_info "Internet connection OK"

# Run the main installer
log_info "Running Pi-Bot installer..."
echo ""

curl -sSL https://raw.githubusercontent.com/Robonectics/pi-bot/main/install.sh | bash

# Note: The install.sh will set up AP mode, which will disconnect from DroidAir
