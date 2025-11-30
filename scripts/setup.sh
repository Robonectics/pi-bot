#!/bin/bash
# Pi-Bot Quick Setup Script
# Run from project root: ./scripts/setup.sh

set -e  # Exit on error

# Get the project root directory (parent of scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

echo "======================================"
echo "    Pi-Bot Tank Robot Setup"
echo "======================================"
echo ""
echo "Project directory: $PROJECT_DIR"
echo ""

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null && ! grep -q "BCM" /proc/cpuinfo 2>/dev/null; then
    echo "Warning: This doesn't appear to be a Raspberry Pi"
    echo "   GPIO functions will not work properly"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check Python version
echo "Checking Python version..."
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
REQUIRED_VERSION=3.7

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "Error: Python 3.7 or higher required. Found: $PYTHON_VERSION"
    exit 1
fi
echo "  Python $PYTHON_VERSION found"
echo ""

# Create virtual environment
if [ -d "venv" ]; then
    echo "Virtual environment already exists"
    read -p "Recreate it? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing old virtual environment..."
        rm -rf venv
    fi
fi

if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    echo "  Virtual environment created"
else
    echo "  Using existing virtual environment"
fi
echo ""

# Activate virtual environment and install dependencies
echo "Installing dependencies..."
source venv/bin/activate
pip install --upgrade pip > /dev/null 2>&1
pip install -r requirements.txt
echo "  Dependencies installed"
echo ""

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        echo "Creating .env configuration file..."
        cp .env.example .env
        echo "  .env file created"
        echo "  Edit .env to customize settings"
    fi
else
    echo "  .env file already exists"
fi
echo ""

# Get IP address
IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}')

echo "======================================"
echo "    Setup Complete!"
echo "======================================"
echo ""
echo "To start the web controller:"
echo "  sudo venv/bin/python3 src/pibotweb.py"
echo ""
echo "Or test the basic robot functions:"
echo "  sudo venv/bin/python3 src/pibot.py"
echo ""
echo "Access web interface from:"
echo "  - This Pi:        http://localhost:5000"
if [ -n "$IP_ADDR" ]; then
echo "  - Other devices:  http://$IP_ADDR:5000"
fi
echo ""
echo "For field operation (WiFi AP mode):"
echo "  sudo ./scripts/setup-ap-mode.sh"
echo ""
echo "To auto-start on boot:"
echo "  sudo ./scripts/install-service.sh"
echo ""
echo "For detailed instructions, see:"
echo "  - README.md - Overview and quick start"
echo "  - SETUP.md  - Detailed setup guide"
echo "  - wiring.md - Hardware wiring guide"
echo ""
