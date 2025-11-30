#!/bin/bash
#
# Pi-Bot One-Line Installer
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/Robonectics/pi-bot/main/install.sh | sudo bash
#
# Or with custom SSID/password:
#   curl -sSL https://raw.githubusercontent.com/Robonectics/pi-bot/main/install.sh | sudo bash -s -- MyBot mypassword
#

set -e

SSID="${1:-PiBot}"
PASSWORD="${2:-pibot1234}"
INSTALL_DIR="/opt/pi-bot"
REPO_URL="https://github.com/Robonectics/pi-bot.git"

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
echo "║         Pi-Bot Installer                   ║"
echo "║   Tank Robot Web Controller                ║"
echo "╚════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root"
    echo "Usage: curl -sSL https://raw.githubusercontent.com/Robonectics/pi-bot/main/install.sh | sudo bash"
    exit 1
fi

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi\|BCM" /proc/cpuinfo 2>/dev/null; then
    log_error "This script must be run on a Raspberry Pi"
    exit 1
fi

# Check password length
if [ ${#PASSWORD} -lt 8 ]; then
    log_error "WiFi password must be at least 8 characters"
    exit 1
fi

log_info "Installing Pi-Bot to $INSTALL_DIR"
log_info "WiFi SSID: $SSID"

# Install system dependencies
log_info "Installing system dependencies..."
apt-get update
apt-get install -y git python3 python3-venv python3-pip hostapd dnsmasq

# Clone or update repository
if [ -d "$INSTALL_DIR" ]; then
    log_info "Updating existing installation..."
    cd "$INSTALL_DIR"
    git pull
else
    log_info "Cloning repository..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Create virtual environment
log_info "Setting up Python environment..."
python3 -m venv venv
venv/bin/pip install --upgrade pip
venv/bin/pip install -r requirements.txt

# Create .env if it doesn't exist
if [ ! -f .env ] && [ -f .env.example ]; then
    cp .env.example .env
    log_info "Created .env configuration"
fi

# Set up WiFi Access Point
log_info "Configuring WiFi Access Point..."
bash scripts/setup-ap-mode.sh "$SSID" "$PASSWORD"

# Install systemd service
log_info "Installing systemd service..."
bash scripts/install-service.sh <<< "n"  # Don't start yet, we'll reboot

# Start the service now
log_info "Starting Pi-Bot service..."
systemctl start pibot.service

# Get the configured IP
AP_IP="192.168.4.1"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       Installation Complete!               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo "Pi-Bot has been installed and configured."
echo ""
echo "Connect your phone to WiFi: ${CYAN}$SSID${NC}"
echo "Password: ${CYAN}$PASSWORD${NC}"
echo ""
echo "Open browser: ${CYAN}http://$AP_IP:5000${NC}"
echo ""
echo "Installed to: $INSTALL_DIR"
echo ""

# Check if AP is working
if systemctl is-active --quiet hostapd; then
    echo -e "${GREEN}WiFi Access Point is running${NC}"
else
    echo -e "${YELLOW}NOTE: Reboot recommended for WiFi AP to work properly${NC}"
    echo "  sudo reboot"
fi
echo ""
