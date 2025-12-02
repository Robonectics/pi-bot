#!/bin/bash
#
# Pi-Bot WiFi Access Point Setup Script
# Creates a WiFi hotspot so phones can connect directly to control the robot
#
# Usage: sudo ./setup-ap-mode.sh [SSID] [PASSWORD]
#   SSID defaults to "PiBot" (auto-increments to PiBot01, PiBot02, etc. if taken)
#   PASSWORD defaults to "pibot1234" (must be 8+ characters)
#

set -e

# Configuration defaults
BASE_SSID="PiBot"
USER_SSID="$1"
PASSWORD="${2:-pibot1234}"
CHANNEL=7
IP_ADDRESS="192.168.4.1"
DHCP_RANGE_START="192.168.4.10"
DHCP_RANGE_END="192.168.4.50"
INTERFACE="wlan0"

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

# Function to scan for existing PiBot networks and find available SSID
find_available_ssid() {
    local base="$1"

    log_info "Scanning for existing $base networks..."

    # Scan for nearby WiFi networks (may need a few seconds)
    # Use timeout to prevent hanging, suppress errors
    SCAN_RESULTS=$(iwlist "$INTERFACE" scan 2>/dev/null | grep -oP 'ESSID:"\K[^"]+' || true)

    # If scan failed or empty, just use base SSID
    if [ -z "$SCAN_RESULTS" ]; then
        log_warn "Could not scan WiFi networks (interface may be down)"
        echo "$base"
        return
    fi

    # Check if base SSID (e.g., "PiBot") is in use
    if ! echo "$SCAN_RESULTS" | grep -qx "$base"; then
        echo "$base"
        return
    fi

    log_info "Found existing '$base' network, finding available number..."

    # Find the next available number (PiBot01, PiBot02, etc.)
    for i in $(seq -w 1 99); do
        CANDIDATE="${base}${i}"
        if ! echo "$SCAN_RESULTS" | grep -qx "$CANDIDATE"; then
            echo "$CANDIDATE"
            return
        fi
    done

    # Fallback: use random suffix
    echo "${base}$(shuf -i 100-999 -n 1)"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Check password length
if [ ${#PASSWORD} -lt 8 ]; then
    log_error "Password must be at least 8 characters"
    exit 1
fi

# Determine SSID: use user-provided or auto-detect available
if [ -n "$USER_SSID" ]; then
    SSID="$USER_SSID"
    log_info "Using specified SSID: $SSID"
else
    SSID=$(find_available_ssid "$BASE_SSID")
    if [ "$SSID" != "$BASE_SSID" ]; then
        log_info "Auto-selected SSID: $SSID (to avoid conflict)"
    fi
fi

log_info "Setting up Pi-Bot Access Point"
log_info "  SSID: $SSID"
log_info "  IP Address: $IP_ADDRESS"
log_info "  Interface: $INTERFACE"

# Install required packages
log_info "Installing required packages..."
apt-get update
apt-get install -y hostapd dnsmasq

# Stop services while configuring
log_info "Stopping services for configuration..."
systemctl stop hostapd 2>/dev/null || true
systemctl stop dnsmasq 2>/dev/null || true

# Backup existing configurations
BACKUP_DIR="/etc/pibot-backup"
mkdir -p "$BACKUP_DIR"

if [ -f /etc/dhcpcd.conf ] && [ ! -f "$BACKUP_DIR/dhcpcd.conf.backup" ]; then
    cp /etc/dhcpcd.conf "$BACKUP_DIR/dhcpcd.conf.backup"
    log_info "Backed up dhcpcd.conf"
fi

if [ -f /etc/dnsmasq.conf ] && [ ! -f "$BACKUP_DIR/dnsmasq.conf.backup" ]; then
    cp /etc/dnsmasq.conf "$BACKUP_DIR/dnsmasq.conf.backup"
    log_info "Backed up dnsmasq.conf"
fi

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

# Configure static IP for wlan0
log_info "Configuring static IP..."
if [ "$USE_NETWORKMANAGER" = true ]; then
    # NetworkManager (Bookworm) - tell NM to ignore wlan0 permanently
    mkdir -p /etc/NetworkManager/conf.d
    cat > /etc/NetworkManager/conf.d/pibot-ap.conf << EOF
# Pi-Bot AP Configuration - prevent NetworkManager from managing wlan0
[keyfile]
unmanaged-devices=interface-name:$INTERFACE
EOF

    # Create systemd-networkd config for static IP (persists across reboots)
    mkdir -p /etc/systemd/network
    cat > /etc/systemd/network/10-pibot-ap.network << EOF
[Match]
Name=$INTERFACE

[Network]
Address=$IP_ADDRESS/24
EOF

    # Enable systemd-networkd to handle the interface
    systemctl enable systemd-networkd 2>/dev/null || true

    # Apply immediately
    nmcli device set $INTERFACE managed no 2>/dev/null || true
    ip addr flush dev $INTERFACE 2>/dev/null || true
    ip addr add $IP_ADDRESS/24 dev $INTERFACE 2>/dev/null || true
    ip link set $INTERFACE up
else
    # dhcpcd (Bullseye) - configure via dhcpcd.conf
    if ! grep -q "# Pi-Bot AP Configuration" /etc/dhcpcd.conf 2>/dev/null; then
        cat >> /etc/dhcpcd.conf << EOF

# Pi-Bot AP Configuration
interface $INTERFACE
    static ip_address=$IP_ADDRESS/24
    nohook wpa_supplicant
EOF
    fi
fi

# Configure dnsmasq (DHCP server)
log_info "Configuring DHCP server..."
cat > /etc/dnsmasq.d/pibot-ap.conf << EOF
# Pi-Bot Access Point DHCP Configuration
interface=$INTERFACE
dhcp-range=$DHCP_RANGE_START,$DHCP_RANGE_END,255.255.255.0,24h
domain=pibot.local
address=/pibot.local/$IP_ADDRESS
EOF

# Configure hostapd (Access Point)
log_info "Configuring Access Point..."
cat > /etc/hostapd/hostapd.conf << EOF
# Pi-Bot Access Point Configuration
interface=$INTERFACE
driver=nl80211
ssid=$SSID
hw_mode=g
channel=$CHANNEL
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$PASSWORD
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

# Set hostapd to use our config
if [ -f /etc/default/hostapd ]; then
    sed -i 's|^#DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
    sed -i 's|^DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
else
    echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' > /etc/default/hostapd
fi

# Unmask and enable services
log_info "Enabling services..."
systemctl unmask hostapd
systemctl enable hostapd
systemctl enable dnsmasq

# Create a marker file to indicate AP mode is configured
echo "SSID=$SSID" > /etc/pibot-ap-mode
echo "IP=$IP_ADDRESS" >> /etc/pibot-ap-mode
echo "CONFIGURED=$(date)" >> /etc/pibot-ap-mode

# Restart services
log_info "Starting Access Point..."
if [ "$USE_NETWORKMANAGER" = true ]; then
    # On Bookworm, just make sure the interface is configured
    nmcli device set $INTERFACE managed no 2>/dev/null || true
    ip addr flush dev $INTERFACE 2>/dev/null || true
    ip addr add $IP_ADDRESS/24 dev $INTERFACE 2>/dev/null || true
    ip link set $INTERFACE up
else
    systemctl restart dhcpcd
fi
sleep 2
systemctl restart dnsmasq
systemctl restart hostapd

# Check if hostapd started successfully
sleep 3
if systemctl is-active --quiet hostapd; then
    log_info "Access Point started successfully!"
else
    log_error "Failed to start hostapd. Check logs with: journalctl -u hostapd"
    exit 1
fi

echo ""
echo "=============================================="
echo -e "${GREEN}Pi-Bot Access Point Setup Complete!${NC}"
echo "=============================================="
echo ""
echo "WiFi Network Details:"
echo "  SSID:     $SSID"
echo "  Password: $PASSWORD"
echo "  Pi IP:    $IP_ADDRESS"
echo ""
echo "To control Pi-Bot:"
echo "  1. Connect your phone to '$SSID' WiFi"
echo "  2. Open browser to: http://$IP_ADDRESS:5000"
echo "     or http://pibot.local:5000"
echo ""
echo "To switch back to normal WiFi client mode:"
echo "  sudo ./disable-ap-mode.sh"
echo ""
echo "NOTE: Reboot recommended for changes to fully apply"
echo "  sudo reboot"
echo ""
