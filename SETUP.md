# Pi-Bot Setup Guide

This guide will help you set up the Python virtual environment and run the web controller.

## Prerequisites

- Raspberry Pi (any model with GPIO)
- Python 3.7 or higher
- Internet connection (for initial setup)

## Quick Start (Automated)

Run the one-line installer on your Raspberry Pi:

```bash
curl -sSL https://raw.githubusercontent.com/Robonectics/pi-bot/main/install.sh | sudo bash
```

This installs everything, sets up WiFi AP mode, and configures auto-start.

## Quick Start (Manual)

```bash
python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt
```

Then start the web server:

```bash
sudo venv/bin/python3 src/pibotweb.py
```

## Detailed Setup Instructions

### 1. Create Python Virtual Environment

Navigate to the project directory and create a virtual environment:

```bash
cd /home/michael/code/pi-bot
python3 -m venv venv
```

This creates a `venv` directory containing an isolated Python environment.

### 2. Activate Virtual Environment

```bash
source venv/bin/activate
```

You should see `(venv)` appear at the beginning of your command prompt.

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

This installs:
- Flask (web framework)
- RPi.GPIO (GPIO control)
- python-dotenv (environment variable management)

### 4. Configure Environment Variables

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` to customize settings:

```bash
nano .env
```

Key settings you might want to change:
- `PORT`: Change web server port (default: 5000)
- `DEFAULT_SPEED`: Starting speed percentage (default: 60)
- `LEFT_TRACK_MULTIPLIER` / `RIGHT_TRACK_MULTIPLIER`: Calibrate motor speeds if one track is faster

### 5. Run the Web Controller

**Important:** GPIO access requires root privileges, so use `sudo`:

```bash
sudo venv/bin/python3 src/pibotweb.py
```

Or activate the venv first, then run with sudo:

```bash
source venv/bin/activate
sudo $(which python3) src/pibotweb.py
```

### 6. Access the Web Interface

**On the Raspberry Pi:**
```
http://localhost:5000
```

**From another device on the same network:**

First, find your Pi's IP address:
```bash
hostname -I
```

Then access from your phone/computer:
```
http://[PI_IP_ADDRESS]:5000
```

Example: `http://192.168.1.100:5000`

## Running as a Service (Auto-start on Boot)

To make Pi-Bot start automatically when the Pi boots up:

### Install the Service

```bash
sudo ./scripts/install-service.sh
```

This script:
- Creates a systemd service with correct paths
- Sets up the virtual environment if needed
- Waits for network before starting (works with AP mode)
- Enables auto-start on boot

### Service Commands

```bash
# Check if running
sudo systemctl status pibot

# Start/stop/restart
sudo systemctl start pibot
sudo systemctl stop pibot
sudo systemctl restart pibot

# View live logs
sudo journalctl -u pibot -f

# View recent logs
sudo journalctl -u pibot -n 50
```

### Uninstall the Service

```bash
sudo ./scripts/uninstall-service.sh
```

This stops and removes the service but keeps your Pi-Bot files intact.

### Complete Field Setup

For a fully autonomous field robot:

1. **Set up WiFi AP mode:**
   ```bash
   sudo ./scripts/setup-ap-mode.sh
   ```

2. **Install the service:**
   ```bash
   sudo ./scripts/install-service.sh
   ```

3. **Reboot:**
   ```bash
   sudo reboot
   ```

After reboot, the Pi will:
1. Create the "PiBot" WiFi network
2. Start the web controller automatically
3. Be ready for connections at `http://192.168.4.1:5000`

## WiFi Access Point Mode (Field Operation)

When operating the robot in the field where there's no existing WiFi network, you can configure the Pi to act as its own WiFi Access Point. This allows your phone to connect directly to the Pi.

### Setting Up Access Point Mode

Run the setup script:

```bash
sudo ./scripts/setup-ap-mode.sh
```

This creates a WiFi network with:
- **SSID:** PiBot (auto-increments to PiBot01, PiBot02, etc. if another PiBot is nearby)
- **Password:** pibot1234
- **Pi IP:** 192.168.4.1

To customize the network name and password:

```bash
sudo ./scripts/setup-ap-mode.sh MyRobot secretpass123
```

After setup completes, reboot the Pi:

```bash
sudo reboot
```

### Connecting to the Robot

1. On your phone, connect to the "PiBot" WiFi network
2. Open a browser and go to: `http://192.168.4.1:5000`
3. Control your robot!

### Checking Network Status

To see the current network mode and connection info:

```bash
./scripts/network-status.sh
```

### Switching Back to Normal WiFi

To disable AP mode and return to normal WiFi client mode:

```bash
sudo ./scripts/disable-ap-mode.sh
sudo reboot
```

Then configure your WiFi network:

```bash
sudo raspi-config
# Navigate to: System Options > Wireless LAN
```

### Notes on AP Mode

- The Pi cannot connect to the internet while in AP mode
- DHCP assigns IPs in range 192.168.4.10-50
- You can also use `http://pibot.local:5000` (mDNS) on some devices
- AP mode persists across reboots until disabled

## Testing Without Hardware

If you want to test the web interface without a Raspberry Pi:

1. Comment out or mock the `RPi.GPIO` import in `src/pibot.py`
2. Run without sudo: `python3 src/pibotweb.py`
3. The web interface will work, but motor commands won't execute

## Deactivating Virtual Environment

When you're done working in the virtual environment:

```bash
deactivate
```

## Updating Dependencies

To update all packages to their latest versions:

```bash
source venv/bin/activate
pip install --upgrade -r requirements.txt
```

## Troubleshooting

### "Permission denied" when accessing GPIO

- You must run with `sudo` for GPIO access
- Make sure you're using the venv Python: `sudo venv/bin/python3`

### "Cannot find RPi.GPIO module"

- Make sure you activated the venv before installing: `source venv/bin/activate`
- Reinstall: `pip install RPi.GPIO`

### Port 5000 already in use

- Change the port in `.env` file
- Or kill the existing process: `sudo lsof -ti:5000 | xargs sudo kill -9`

### Web interface won't load from another device

- Check firewall: `sudo ufw allow 5000`
- Verify Pi is connected to same network
- Make sure `HOST=0.0.0.0` in `.env` (not 127.0.0.1)

### Motors not responding

- Check wiring (see `wiring.md`)
- Verify common ground between Pi and L298N
- Check GPIO pins match configuration in `.env`
- Test with basic script: `sudo venv/bin/python3 src/pibot.py`

## Uninstalling

To remove the virtual environment:

```bash
deactivate  # if currently activated
rm -rf venv
```

To remove the systemd service:

```bash
sudo systemctl stop pibot.service
sudo systemctl disable pibot.service
sudo rm /etc/systemd/system/pibot.service
sudo systemctl daemon-reload
```

## Development

### Installing additional packages

```bash
source venv/bin/activate
pip install package-name
pip freeze > requirements.txt  # Update requirements
```

### Running in debug mode

Edit `.env`:
```
DEBUG=True
```

This enables:
- Auto-reload on code changes
- Detailed error messages
- Flask debug toolbar

**Warning:** Never run debug mode on a public network!

## Next Steps

- See `wiring.md` for hardware connection details
- Read `README.md` for usage instructions
- Check `.env` file for configuration options
- Test movements with the web interface
- Calibrate motor speeds using multipliers in `.env`

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify wiring matches `wiring.md`
3. Test basic GPIO functionality with `src/pibot.py` demo
4. Check system logs: `sudo journalctl -xe`
