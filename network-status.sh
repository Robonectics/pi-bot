#!/bin/bash
#
# Pi-Bot Network Status Script
# Shows current network mode and connection details
#
# Usage: ./network-status.sh
#

INTERFACE="wlan0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}=============================================="
echo "        Pi-Bot Network Status"
echo -e "==============================================${NC}"
echo ""

# Check if AP mode is configured
if [ -f /etc/pibot-ap-mode ]; then
    AP_SSID=$(grep "^SSID=" /etc/pibot-ap-mode | cut -d= -f2)
    AP_IP=$(grep "^IP=" /etc/pibot-ap-mode | cut -d= -f2)

    echo -e "${YELLOW}Mode: ACCESS POINT (AP)${NC}"
    echo ""

    # Check if hostapd is running
    if systemctl is-active --quiet hostapd; then
        echo -e "  AP Status:  ${GREEN}RUNNING${NC}"
    else
        echo -e "  AP Status:  ${RED}STOPPED${NC}"
    fi

    echo "  SSID:       $AP_SSID"
    echo "  AP IP:      $AP_IP"
    echo ""
    echo "  Connect your phone to '$AP_SSID' WiFi"
    echo "  Then visit: http://$AP_IP:5000"
else
    echo -e "${BLUE}Mode: WIFI CLIENT${NC}"
    echo ""

    # Get current WiFi connection info
    if command -v iwgetid &> /dev/null; then
        CURRENT_SSID=$(iwgetid -r 2>/dev/null)
        if [ -n "$CURRENT_SSID" ]; then
            echo -e "  WiFi Status: ${GREEN}CONNECTED${NC}"
            echo "  Network:     $CURRENT_SSID"
        else
            echo -e "  WiFi Status: ${RED}NOT CONNECTED${NC}"
        fi
    fi
fi

# Get IP addresses
echo ""
echo "IP Addresses:"
IP_ADDR=$(hostname -I 2>/dev/null | tr ' ' '\n' | grep -v '^$' | head -5)
if [ -n "$IP_ADDR" ]; then
    echo "$IP_ADDR" | while read ip; do
        echo "  $ip"
    done
else
    echo "  No IP address assigned"
fi

# Show interface status
echo ""
echo "Interface ($INTERFACE):"
if ip link show $INTERFACE &>/dev/null; then
    STATE=$(cat /sys/class/net/$INTERFACE/operstate 2>/dev/null || echo "unknown")
    echo "  State: $STATE"

    # Show signal strength if connected
    if [ -f /proc/net/wireless ]; then
        SIGNAL=$(awk "/$INTERFACE/ {print \$4}" /proc/net/wireless 2>/dev/null | tr -d '.')
        if [ -n "$SIGNAL" ]; then
            echo "  Signal: ${SIGNAL}dBm"
        fi
    fi
else
    echo -e "  ${RED}Interface not found${NC}"
fi

# Service status
echo ""
echo "Services:"
if systemctl is-active --quiet hostapd; then
    echo -e "  hostapd:  ${GREEN}active${NC}"
else
    echo -e "  hostapd:  ${YELLOW}inactive${NC}"
fi

if systemctl is-active --quiet dnsmasq; then
    echo -e "  dnsmasq:  ${GREEN}active${NC}"
else
    echo -e "  dnsmasq:  ${YELLOW}inactive${NC}"
fi

# Check if pibotweb is running
if pgrep -f "pibotweb.py" > /dev/null; then
    echo -e "  pibotweb: ${GREEN}active${NC}"
else
    echo -e "  pibotweb: ${YELLOW}inactive${NC}"
fi

echo ""
echo "Commands:"
if [ -f /etc/pibot-ap-mode ]; then
    echo "  Disable AP mode:  sudo ./disable-ap-mode.sh"
else
    echo "  Enable AP mode:   sudo ./setup-ap-mode.sh [SSID] [PASSWORD]"
fi
echo "  Start Pi-Bot:     sudo python3 pibotweb.py"
echo ""
