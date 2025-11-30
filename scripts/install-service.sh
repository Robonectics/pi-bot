#!/bin/bash
#
# Pi-Bot Service Installer
# Installs pibot as a systemd service that starts on boot
#
# Usage: sudo ./scripts/install-service.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Get the project root directory (parent of scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SERVICE_FILE="/etc/systemd/system/pibot.service"

log_info "Installing Pi-Bot service..."
log_info "  Project directory: $PROJECT_DIR"

# Check that required files exist
if [ ! -f "$PROJECT_DIR/src/pibotweb.py" ]; then
    log_error "src/pibotweb.py not found in $PROJECT_DIR"
    exit 1
fi

if [ ! -d "$PROJECT_DIR/venv" ]; then
    log_warn "Virtual environment not found. Creating it now..."
    python3 -m venv "$PROJECT_DIR/venv"
    "$PROJECT_DIR/venv/bin/pip" install -r "$PROJECT_DIR/requirements.txt"
    log_info "Virtual environment created"
fi

# Check for .env file
if [ ! -f "$PROJECT_DIR/.env" ]; then
    if [ -f "$PROJECT_DIR/.env.example" ]; then
        cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
        log_info "Created .env from .env.example"
    else
        log_warn "No .env file found - using defaults"
    fi
fi

# Stop existing service if running
if systemctl is-active --quiet pibot.service; then
    log_info "Stopping existing pibot service..."
    systemctl stop pibot.service
fi

# Create service file with correct paths
log_info "Creating systemd service file..."
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Pi-Bot Web Controller
# Wait for network - works with both AP mode (hostapd) and client mode
After=network-online.target hostapd.service
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$PROJECT_DIR/venv/bin:/usr/bin:/bin"
ExecStart=$PROJECT_DIR/venv/bin/python3 $PROJECT_DIR/src/pibotweb.py
Restart=always
RestartSec=5
# Give network time to fully initialize
ExecStartPre=/bin/sleep 3

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
log_info "Enabling service..."
systemctl daemon-reload
systemctl enable pibot.service

echo ""
echo "=============================================="
echo -e "${GREEN}Pi-Bot Service Installed!${NC}"
echo "=============================================="
echo ""
echo "Commands:"
echo "  Start now:     sudo systemctl start pibot"
echo "  Stop:          sudo systemctl stop pibot"
echo "  Restart:       sudo systemctl restart pibot"
echo "  View status:   sudo systemctl status pibot"
echo "  View logs:     sudo journalctl -u pibot -f"
echo "  Disable:       sudo systemctl disable pibot"
echo "  Uninstall:     sudo ./scripts/uninstall-service.sh"
echo ""
echo "The service will automatically start on boot."
echo ""

# Ask if user wants to start now
read -p "Start Pi-Bot service now? [Y/n] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    systemctl start pibot.service
    sleep 2
    if systemctl is-active --quiet pibot.service; then
        log_info "Pi-Bot service started successfully!"

        # Show access URL
        IP_ADDR=$(hostname -I | awk '{print $1}')
        if [ -n "$IP_ADDR" ]; then
            echo ""
            echo "Access Pi-Bot at: http://$IP_ADDR:5000"
        fi
    else
        log_error "Service failed to start. Check logs:"
        echo "  sudo journalctl -u pibot -n 20"
    fi
fi
